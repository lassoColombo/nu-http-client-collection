# Auto-generated client for Adobe Analytics APIs v2.0
# Source: https://raw.githubusercontent.com/AdobeDocs/analytics-2.0-apis/main/static/swagger.json
# Auth: --token flag or $env.ADOBE_ANALYTICS_APIS_TOKEN

const BASE_URL = "https://analytics.adobe.io/api"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ADOBE_ANALYTICS_APIS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["https://analytics.adobe.io/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def color-completer [] { ["STANDARD1" "STANDARD2" "STANDARD3" "STANDARD4" "STANDARD5" "STANDARD6" "STANDARD7" "STANDARD8" "STANDARD9"] }
def expansion-completer [] { ["categories" "compatibility" "definition" "modified" "ownerFullName" "reportSuiteName" "tags"] }
def includeType-completer [] { ["all" "shared" "templates"] }
def polarity-completer [] { ["negative" "positive"] }
def type-completer [] { ["CURRENCY" "DECIMAL" "PERCENT" "TIME"] }
def componentType-completer [] { ["alert" "bookmark" "calculatedMetric" "classificationSet" "dashboard" "dateRange" "dimension" "metric" "project" "scheduledJob" "segment" "virtualReportSuite"] }
def segmentable-completer [] { ["true"] }
def reportable-completer [] { ["true"] }
def expansion-completer-1 [] { ["allowedForReporting" "attributionModel" "categories" "tags"] }
def expansion-completer-2 [] { ["allowedForReporting" "categories" "tags"] }
def type-completer-1 [] { ["mobileScorecard" "project"] }
def pagination-completer [] { ["false" "true"] }
def filterByPublishedSegments-completer [] { ["all" "false" "true"] }
def expansion-completer-3 [] { ["categories" "compatibility" "definition" "definitionLastModified" "modified" "ownerFullName" "publishingStatus" "reportSuiteName" "tags"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "annotations get-by-globalCompanyId" } } | get name | first)
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

# Retrieve all annotations.
#
# GET /{globalCompanyId}/annotations
# operationId: getAnnotations_1
export def "annotations get-by-globalCompanyId" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expansion: list # Comma-delimited list of additional annotation metadata fields to include on response.
  --includeType: list # Include additional annotations not owned by user. The "all" option takes precedence over "shared"
  --locale: string # Locale (default: en_US)
  --filterByIds: string
  --filterByModifiedAfter: string # Filter list to only include annotations modified since this date (ISO8601 format)
  --filterByDateRange: string # Filter list to only include annotations in the specified date range with format yyyy-MM-dd'T'HH:mm:ss/yyyy-MM-dd'T'hh:MM:ss
  --limit: int # Number of results per page (default: 10)
  --page: int # Page number (base 0 - first page is "0") (default: 0)
  --sortDirection: int # Sort direction (ASC or DESC (default: ASC)
  --sortProperty: string # Property to sort by (name, modified_date, id is currently allowed) (default: id)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<id: string, name: string, description: string, dateRange: string, color: string, applyToAllReports: bool, scope: record<metrics: list<record>, filters: list<record>>, createdDate: string, modifiedDate: string, modifiedById: string, tags: list<record>, shares: list<record>, approved: bool, favorite: bool, usageSummary: record, systemUserOwned: bool, owner: record<id: int, name: string, login: string>, companyId: int, reportSuiteName: string, rsid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expansion" $expansion "csv") (serialize-qp "includeType" $includeType "csv") (serialize-qp "locale" $locale "scalar") (serialize-qp "filterByIds" $filterByIds "scalar") (serialize-qp "filterByModifiedAfter" $filterByModifiedAfter "scalar") (serialize-qp "filterByDateRange" $filterByDateRange "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "sortProperty" $sortProperty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/annotations" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new annotation
#
# POST /{globalCompanyId}/annotations
# operationId: createAnnotation_1
# --scope shape: {metrics?: list, filters?: list}
# --owner shape: {id: int, name?: string, login?: string}
export def "annotations createAnnotation-by-globalCompanyId" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expansion: list # Comma-delimited list of additional annotation metadata fields to include on response.
  --locale: string # Locale (default: en_US)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --id: string
  --name: string
  --description: string
  --dateRange: string
  --color: string@color-completer
  --applyToAllReports: string@bool-completer
  --scope: record # shape: {metrics?: list, filters?: list}
  --createdDate: string # format: date-time
  --modifiedDate: string # format: date-time
  --modifiedById: string
  --tags: list
  --shares: list
  --approved: string@bool-completer
  --favorite: string@bool-completer
  --usageSummary: record
  --systemUserOwned: string@bool-completer
  --owner: record # shape: {id: int, name?: string, login?: string}
  --companyId: int # format: int32
  --reportSuiteName: string
  --rsid: string
]: any -> record<id: string, name: string, description: string, dateRange: string, color: string, applyToAllReports: bool, scope: record<metrics: list<record>, filters: list<record>>, createdDate: string, modifiedDate: string, modifiedById: string, tags: list<record>, shares: list<record>, approved: bool, favorite: bool, usageSummary: record, systemUserOwned: bool, owner: record<id: int, name: string, login: string>, companyId: int, reportSuiteName: string, rsid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expansion" $expansion "csv") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/annotations" $qp)
  let body = {id: $id, name: $name, description: $description, dateRange: $dateRange, color: $color, applyToAllReports: $applyToAllReports, scope: $scope, createdDate: $createdDate, modifiedDate: $modifiedDate, modifiedById: $modifiedById, tags: $tags, shares: $shares, approved: $approved, favorite: $favorite, usageSummary: $usageSummary, systemUserOwned: $systemUserOwned, owner: $owner, companyId: $companyId, reportSuiteName: $reportSuiteName, rsid: $rsid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get existing annotation
#
# GET /{globalCompanyId}/annotations/{id}
# operationId: getAnnotation_1
export def "annotations get-by-globalCompanyId-id" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expansion: list # Comma-delimited list of additional annotation metadata fields to include on response.
  --locale: string # Locale (default: en_US)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<id: string, name: string, description: string, dateRange: string, color: string, applyToAllReports: bool, scope: record<metrics: list<record>, filters: list<record>>, createdDate: string, modifiedDate: string, modifiedById: string, tags: list<record>, shares: list<record>, approved: bool, favorite: bool, usageSummary: record, systemUserOwned: bool, owner: record<id: int, name: string, login: string>, companyId: int, reportSuiteName: string, rsid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expansion" $expansion "csv") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/annotations/($id)" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update existing annotation
#
# PUT /{globalCompanyId}/annotations/{id}
# operationId: updateAnnotation_1
# --scope shape: {metrics?: list, filters?: list}
# --owner shape: {id: int, name?: string, login?: string}
export def "annotations updateAnnotation-by-globalCompanyId-id" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expansion: list # Comma-delimited list of additional annotation metadata fields to include on response.
  --locale: string # Locale (default: en_US)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --body-id: string
  --name: string
  --description: string
  --dateRange: string
  --color: string@color-completer
  --applyToAllReports: string@bool-completer
  --scope: record # shape: {metrics?: list, filters?: list}
  --createdDate: string # format: date-time
  --modifiedDate: string # format: date-time
  --modifiedById: string
  --tags: list
  --shares: list
  --approved: string@bool-completer
  --favorite: string@bool-completer
  --usageSummary: record
  --systemUserOwned: string@bool-completer
  --owner: record # shape: {id: int, name?: string, login?: string}
  --companyId: int # format: int32
  --reportSuiteName: string
  --rsid: string
]: any -> record<id: string, name: string, description: string, dateRange: string, color: string, applyToAllReports: bool, scope: record<metrics: list<record>, filters: list<record>>, createdDate: string, modifiedDate: string, modifiedById: string, tags: list<record>, shares: list<record>, approved: bool, favorite: bool, usageSummary: record, systemUserOwned: bool, owner: record<id: int, name: string, login: string>, companyId: int, reportSuiteName: string, rsid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expansion" $expansion "csv") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/annotations/($id)" $qp)
  let body = {id: $body_id, name: $name, description: $description, dateRange: $dateRange, color: $color, applyToAllReports: $applyToAllReports, scope: $scope, createdDate: $createdDate, modifiedDate: $modifiedDate, modifiedById: $modifiedById, tags: $tags, shares: $shares, approved: $approved, favorite: $favorite, usageSummary: $usageSummary, systemUserOwned: $systemUserOwned, owner: $owner, companyId: $companyId, reportSuiteName: $reportSuiteName, rsid: $rsid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete existing annotation
#
# DELETE /{globalCompanyId}/annotations/{id}
# operationId: deleteAnnotation_1
export def "annotations delete-by-globalCompanyId-id" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale (default: en_US)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<result: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/annotations/($id)" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve multiple calculated metrics
#
# GET /{globalCompanyId}/calculatedmetrics
# operationId: findCalculatedMetrics
export def "calculatedmetrics findCalculatedMetrics" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rsids: string # Filter list to only include calculated metrics tied to specified RSID list (comma-delimited)
  --ownerId: int # Filter list to only include calculated metrics owned by the specified loginId (format: int32)
  --filterByIds: string # Filter list to only include calculated metrics in the specified list (comma-delimited list of IDs) (this is the same as calculatedMetricFilter, and is overwritten by calculatedMetricFilter
  --toBeUsedInRsid: string # The report suite where the calculated metric intended to be used.  This report suite will be used to determine things like compatibility and permissions.  If it is not specified then the permissions will be calculated based on the union of all metrics authorized in all groups the user belongs to.  If the compatibility expansion is specified and toBeUsedInRsid is not then the compatibility returned is based off the compatibility from the last time the calculated metric was saved.
  --locale: string # Locale (default: en_US)
  --name: string # Filter list to only include calculated metrics that contains the Name
  --tagNames: string # Filter list to only include calculated metrics that contains one of the tags
  --favorite: string@bool-completer # Filter list to only include calculated metrics that are favorites
  --approved: string@bool-completer # Filter list to only include calculated metrics that are approved
  --limit: int # Number of results per page (default: 10)
  --page: int # Page number (base 0 - first page is "0") (default: 0)
  --sortDirection: string # Sort direction (ASC or DESC) (default: ASC)
  --sortProperty: string # Property to sort by (name, modified_date, id is currently allowed) (default: id)
  --expansion: list@expansion-completer # Comma-delimited list of additional calculated metric metadata fields to include on response.
  --includeType: list@includeType-completer # Include additional calculated metrics not owned by user. The "all" option takes precedence over "shared"
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> table<id: string, name: string, description: string, rsid: string, reportSuiteName: string, owner: record<id: int, name: string, login: string>, polarity: string, precision: int, type: string, definition: record, categories: list<string>, tags: list<record>, siteTitle: string, modified: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rsids" $rsids "scalar") (serialize-qp "ownerId" $ownerId "scalar") (serialize-qp "filterByIds" $filterByIds "scalar") (serialize-qp "toBeUsedInRsid" $toBeUsedInRsid "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "tagNames" $tagNames "scalar") (serialize-qp "favorite" $favorite "scalar") (serialize-qp "approved" $approved "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "sortProperty" $sortProperty "scalar") (serialize-qp "expansion" $expansion "csv") (serialize-qp "includeType" $includeType "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/calculatedmetrics" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new calculated metric
#
# POST /{globalCompanyId}/calculatedmetrics
# operationId: calculatedmetrics_createCalculatedMetric
# --owner shape: {id: int, name?: string, login?: string}
# --tags item shape: {id?: int, name?: string, description?: string, components?: list}
export def "calculatedmetrics createCalculatedMetric" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale (default: en_US)
  --expansion: list@expansion-completer # Comma-delimited list of additional calculated metric metadata fields to include on response.
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --name: string
  --description: string
  --rsid: string # The report suite id for which the component was created/updated
  --owner: record # shape: {id: int, name?: string, login?: string}
  --polarity: string@polarity-completer # Set metric polarity, which indicates whether it's good or bad if a given metric goes up. Default=positive
  --precision: int # Number of decimal places to include in calculated metric result (format: int32)
  --type: string@type-completer
  definition: record
  --categories: list
  --tags: list # item shape: {id?: int, name?: string, description?: string, components?: list}
  --siteTitle: string
  --modified: string # format: date-time
]: any -> record<id: string, name: string, description: string, rsid: string, reportSuiteName: string, owner: record<id: int, name: string, login: string>, polarity: string, precision: int, type: string, definition: record, categories: list<string>, tags: table<id: int, name: string, description: string, components: list>, siteTitle: string, modified: string, created: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "expansion" $expansion "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/calculatedmetrics" $qp)
  let body = {name: $name, description: $description, rsid: $rsid, owner: $owner, polarity: $polarity, precision: $precision, type: $type, definition: $definition, categories: $categories, tags: $tags, siteTitle: $siteTitle, modified: $modified} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve calculated metric functions
#
# GET /{globalCompanyId}/calculatedmetrics/functions
# operationId: calculatedmetrics_getCalculatedMetricFunctions
export def "calculatedmetrics-functions list" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale (default: en_US)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> table<id: string, category: string, persistable: bool, name: string, namespace: string, description: string, exampleKey: string, example: string, definition: record<func: string, parameters: list, formula: record, version: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/calculatedmetrics/functions" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a calculated metric function by ID
#
# GET /{globalCompanyId}/calculatedmetrics/functions/{id}
# operationId: calculatedmetrics_getCalculatedMetricFunction
export def "calculatedmetrics-functions get" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale (default: en_US)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<id: string, category: string, persistable: bool, name: string, namespace: string, description: string, exampleKey: string, example: string, definition: record<func: string, parameters: list<record>, formula: record, version: list<int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/calculatedmetrics/functions/($id)" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate a calculated metric definition
#
# POST /{globalCompanyId}/calculatedmetrics/validate
# operationId: calculatedmetrics_validateCalculatedMetric
# --owner shape: {id: int, name?: string, login?: string}
# --tags item shape: {id?: int, name?: string, description?: string, components?: list}
export def "calculatedmetrics-validate validateCalculatedMetric" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale (default: en_US)
  --migrating: string@bool-completer # Include migration functions in validation (default: false)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --name: string
  --description: string
  --rsid: string # The report suite id for which the component was created/updated
  --owner: record # shape: {id: int, name?: string, login?: string}
  --polarity: string@polarity-completer # Set metric polarity, which indicates whether it's good or bad if a given metric goes up. Default=positive
  --precision: int # Number of decimal places to include in calculated metric result (format: int32)
  --type: string@type-completer
  definition: record
  --categories: list
  --tags: list # item shape: {id?: int, name?: string, description?: string, components?: list}
  --siteTitle: string
  --modified: string # format: date-time
]: any -> record<id: string, name: string, description: string, rsid: string, reportSuiteName: string, owner: record<id: int, name: string, login: string>, polarity: string, precision: int, type: string, definition: record, categories: list<string>, tags: table<id: int, name: string, description: string, components: list>, siteTitle: string, modified: string, created: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "migrating" $migrating "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/calculatedmetrics/validate" $qp)
  let body = {name: $name, description: $description, rsid: $rsid, owner: $owner, polarity: $polarity, precision: $precision, type: $type, definition: $definition, categories: $categories, tags: $tags, siteTitle: $siteTitle, modified: $modified} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a single calculated metric by ID
#
# GET /{globalCompanyId}/calculatedmetrics/{id}
# operationId: findOneCalculatedMetric
export def "calculatedmetrics findOneCalculatedMetric" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale (default: en_US)
  --expansion: list@expansion-completer # Comma-delimited list of additional calculated metric metadata fields to include on response.
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<id: string, name: string, description: string, rsid: string, reportSuiteName: string, owner: record<id: int, name: string, login: string>, polarity: string, precision: int, type: string, definition: record, categories: list<string>, tags: table<id: int, name: string, description: string, components: list>, siteTitle: string, modified: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "expansion" $expansion "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/calculatedmetrics/($id)" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing calculated metric
#
# PUT /{globalCompanyId}/calculatedmetrics/{id}
# operationId: calculatedmetrics_updateCalculatedMetric
# --owner shape: {id: int, name?: string, login?: string}
# --tags item shape: {id?: int, name?: string, description?: string, components?: list}
export def "calculatedmetrics updateCalculatedMetric" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale (default: en_US)
  --expansion: list@expansion-completer # Comma-delimited list of additional calculated metric metadata fields to include on response.
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --name: string
  --description: string
  --rsid: string # The report suite id for which the component was created/updated
  --owner: record # shape: {id: int, name?: string, login?: string}
  --polarity: string@polarity-completer # Set metric polarity, which indicates whether it's good or bad if a given metric goes up. Default=positive
  --precision: int # Number of decimal places to include in calculated metric result (format: int32)
  --type: string@type-completer
  definition: record
  --categories: list
  --tags: list # item shape: {id?: int, name?: string, description?: string, components?: list}
  --siteTitle: string
  --modified: string # format: date-time
]: any -> record<id: string, name: string, description: string, rsid: string, reportSuiteName: string, owner: record<id: int, name: string, login: string>, polarity: string, precision: int, type: string, definition: record, categories: list<string>, tags: table<id: int, name: string, description: string, components: list>, siteTitle: string, modified: string, created: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "expansion" $expansion "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/calculatedmetrics/($id)" $qp)
  let body = {name: $name, description: $description, rsid: $rsid, owner: $owner, polarity: $polarity, precision: $precision, type: $type, definition: $definition, categories: $categories, tags: $tags, siteTitle: $siteTitle, modified: $modified} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete calculated metrics by ID
#
# DELETE /{globalCompanyId}/calculatedmetrics/{id}
# operationId: calculatedmetrics_deleteCalculatedMetric
export def "calculatedmetrics delete" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale (default: en_US)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<result: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/calculatedmetrics/($id)" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve components shared by user
#
# GET /{globalCompanyId}/componentmetadata/shares
export def "componentmetadata-shares list" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeType: list # Include additional shares not owned by the user
  --userid: int # The user ID to return details for. Only admins may use this option. (format: int32)
  --limit: int # Number of results per page (default: 10)
  --page: int # Page number (base 0 - first page is "0") (default: 0)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> table<shareId: string, imsOrgId: string, shareToId: int, shareToImsId: string, shareToType: string, shareFromImsId: string, componentType: string, componentId: string, shareToDisplayName: string, shareToLogin: string, accessLevel: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeType" $includeType "csv") (serialize-qp "userid" $userid "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/componentmetadata/shares" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Share component with user
#
# POST /{globalCompanyId}/componentmetadata/shares
export def "componentmetadata-shares post" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale (default: en_US)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --shareId: string
  --imsOrgId: string
  --shareToId: int # format: int32
  --shareToImsId: string
  --shareToType: string
  --shareFromImsId: string
  --componentType: string
  --componentId: string
  --shareToDisplayName: string
  --shareToLogin: string
  --accessLevel: string
]: any -> record<shareId: string, imsOrgId: string, shareToId: int, shareToImsId: string, shareToType: string, shareFromImsId: string, componentType: string, componentId: string, shareToDisplayName: string, shareToLogin: string, accessLevel: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/componentmetadata/shares" $qp)
  let body = {shareId: $shareId, imsOrgId: $imsOrgId, shareToId: $shareToId, shareToImsId: $shareToImsId, shareToType: $shareToType, shareFromImsId: $shareFromImsId, componentType: $componentType, componentId: $componentId, shareToDisplayName: $shareToDisplayName, shareToLogin: $shareToLogin, accessLevel: $accessLevel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update shared components with users
#
# PUT /{globalCompanyId}/componentmetadata/shares
# operationId: modifyShares
export def "componentmetadata-shares modifyShares" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale (default: en_US)
  --useCache: string@bool-completer # Use caching for faster requests (default: true)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --body: record
]: any -> record<componentType: string, componentId: string, shares: table<shareToId: int, shareToImsId: string, shareToType: string, accessLevel: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "useCache" $useCache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/componentmetadata/shares" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create search for shared components
#
# POST /{globalCompanyId}/componentmetadata/shares/component/search
# operationId: searchComponentTags
export def "componentmetadata-shares-component-search searchComponentTags" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale (default: en_US)
  --expansion: list # Comma-delimited list of additional project metadata fields to include on response.
  --limit: int # Number of results per page (default: 10)
  --page: int # Page number (base 0 - first page is "0") (default: 0)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --componentType: string
  --componentIds: list
]: any -> record<componentType: string, componentId: string, shares: table<shareId: string, imsOrgId: string, shareToId: int, shareToImsId: string, shareToType: string, shareFromImsId: string, componentType: string, componentId: string, shareToDisplayName: string, shareToLogin: string, accessLevel: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "expansion" $expansion "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/componentmetadata/shares/component/search" $qp)
  let body = {componentType: $componentType, componentIds: $componentIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve details of share by ID
#
# GET /{globalCompanyId}/componentmetadata/shares/{id}
# operationId: getShare
export def "componentmetadata-shares get" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<shareId: string, imsOrgId: string, shareToId: int, shareToImsId: string, shareToType: string, shareFromImsId: string, componentType: string, componentId: string, shareToDisplayName: string, shareToLogin: string, accessLevel: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($globalCompanyId)/componentmetadata/shares/($id)")
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete share by ID
#
# DELETE /{globalCompanyId}/componentmetadata/shares/{id}
# operationId: deleteShare_1
export def "componentmetadata-shares delete-by-globalCompanyId-id" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale (default: en_US)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/componentmetadata/shares/($id)" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve component IDs shared with user
#
# GET /{globalCompanyId}/componentmetadata/shares/sharedto/me
# operationId: findAllSharesToCurrentUser
export def "componentmetadata-shares-sharedto-me findAllSharesToCurrentUser" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --componentType: string # ComponentType to return
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "componentType" $componentType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/componentmetadata/shares/sharedto/me" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create search for component tags
#
# POST /{globalCompanyId}/componentmetadata/tags/component/search
# operationId: searchComponentTags_2
export def "componentmetadata-tags-component-search searchComponentTags-by-globalCompanyId" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results per page (default: 10)
  --page: int # Page number (base 0 - first page is "0") (default: 0)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --componentType: string
  --componentIds: list
]: any -> record<componentType: string, componentId: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/componentmetadata/tags/component/search" $qp)
  let body = {componentType: $componentType, componentIds: $componentIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve tags for current user company
#
# GET /{globalCompanyId}/componentmetadata/tags
# operationId: findAllForCompany
export def "componentmetadata-tags findAllForCompany" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results per page (default: 10)
  --page: int # Page number (base 0 - first page is "0") (default: 0)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> table<id: int, name: string, description: string, components: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/componentmetadata/tags" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create tags for current user company
#
# POST /{globalCompanyId}/componentmetadata/tags
# operationId: saveTagList
export def "componentmetadata-tags saveTagList" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --body: record
]: any -> table<id: int, name: string, description: string, components: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($globalCompanyId)/componentmetadata/tags")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete tags from components
#
# DELETE /{globalCompanyId}/componentmetadata/tags
# operationId: deleteTagItems
export def "componentmetadata-tags delete-by-globalCompanyId" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --componentIds: string # Comma-separated list of componentIds to operate on.
  --componentType: string@componentType-completer # The component type to operate on.
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "componentIds" $componentIds "scalar") (serialize-qp "componentType" $componentType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/componentmetadata/tags" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve component tags by component ID and component type
#
# GET /{globalCompanyId}/componentmetadata/tags/search
# operationId: getTagListByComponentIdAndComponentType
export def "componentmetadata-tags-search get" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --componentId: string # The componentId to operate on. Currently this is just the segmentId.
  --componentType: string@componentType-completer # The component type to operate on.
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> table<id: int, name: string, description: string, components: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "componentId" $componentId "scalar") (serialize-qp "componentType" $componentType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/componentmetadata/tags/search" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update tags for component
#
# PUT /{globalCompanyId}/componentmetadata/tags/tagitems
# operationId: saveTagComponentList
export def "componentmetadata-tags-tagitems saveTagComponentList" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --body: record
]: any -> table<componentType: string, componentId: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($globalCompanyId)/componentmetadata/tags/tagitems")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve tag by ID
#
# GET /{globalCompanyId}/componentmetadata/tags/{id}
# operationId: getTagById
export def "componentmetadata-tags get" [
  globalCompanyId: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<id: int, name: string, description: string, components: table<componentType: string, componentId: string, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($globalCompanyId)/componentmetadata/tags/($id)")
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete tag from component
#
# DELETE /{globalCompanyId}/componentmetadata/tags/{id}
# operationId: deleteTag
export def "componentmetadata-tags delete-by-globalCompanyId-id" [
  globalCompanyId: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($globalCompanyId)/componentmetadata/tags/($id)")
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve component IDs associated with tag names
#
# GET /{globalCompanyId}/componentmetadata/tags/tagnames
# operationId: getComponentsByTagName
export def "componentmetadata-tags-tagnames get" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tagNames: string # Comma separated list of tag names.
  --componentType: string@componentType-completer # The component type to operate on.
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tagNames" $tagNames "scalar") (serialize-qp "componentType" $componentType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/componentmetadata/tags/tagnames" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve configuration for a date range
#
# GET /{globalCompanyId}/dateranges/{id}
# operationId: getDateRange_1
export def "dateranges get-by-globalCompanyId-id" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expansion: list # Comma-delimited list of additional date range metadata fields to include on response.
  --newDefinition: string@bool-completer # Use the new JSON def (default: false)
  --locale: string # Locale (default: en_US)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<id: string, name: string, description: string, modified: string, companyId: int, owner: record, definition: record, template: bool, createDate: string, disabledDate: string, alternateVariableNames: record<name: string, baseName: string, curatedName: string>, curatedItem: bool, imsOrgId: string, systemUserOwned: bool, tags: list<record>, shares: list<record>, approved: bool, favorite: bool, usageSummary: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expansion" $expansion "csv") (serialize-qp "newDefinition" $newDefinition "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/dateranges/($id)" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update configuration for a date range
#
# PUT /{globalCompanyId}/dateranges/{id}
# --alternateVariableNames shape: {name?: string, baseName?: string, curatedName?: string}
export def "dateranges put" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expansion: list # Comma-delimited list of additional date range metadata fields to include on response.
  --newDefinition: string@bool-completer # Use the new JSON def (default: false)
  --locale: string # Locale (default: en_US)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --body-id: string
  --name: string
  --description: string
  --modified: string # format: date-time
  --companyId: int # format: int32
  --owner: record
  --definition: record
  --template: string@bool-completer
  --createDate: string # format: date-time
  --disabledDate: string # format: date-time
  --alternateVariableNames: record # shape: {name?: string, baseName?: string, curatedName?: string}
  --curatedItem: string@bool-completer
  --imsOrgId: string
  --systemUserOwned: string@bool-completer
  --tags: list
  --shares: list
  --approved: string@bool-completer
  --favorite: string@bool-completer
  --usageSummary: record
]: any -> record<id: string, name: string, description: string, modified: string, companyId: int, owner: record, definition: record, template: bool, createDate: string, disabledDate: string, alternateVariableNames: record<name: string, baseName: string, curatedName: string>, curatedItem: bool, imsOrgId: string, systemUserOwned: bool, tags: list<record>, shares: list<record>, approved: bool, favorite: bool, usageSummary: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expansion" $expansion "csv") (serialize-qp "newDefinition" $newDefinition "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/dateranges/($id)" $qp)
  let body = {id: $body_id, name: $name, description: $description, modified: $modified, companyId: $companyId, owner: $owner, definition: $definition, template: $template, createDate: $createDate, disabledDate: $disabledDate, alternateVariableNames: $alternateVariableNames, curatedItem: $curatedItem, imsOrgId: $imsOrgId, systemUserOwned: $systemUserOwned, tags: $tags, shares: $shares, approved: $approved, favorite: $favorite, usageSummary: $usageSummary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a date range
#
# DELETE /{globalCompanyId}/dateranges/{id}
export def "dateranges delete" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale (default: en_US)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<result: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/dateranges/($id)" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve user's date ranges
#
# GET /{globalCompanyId}/dateranges
# operationId: getDateRanges_1
export def "dateranges get-by-globalCompanyId" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeType: list # Include additional dateranges not owned by user. The "all" option takes precedence over "shared"
  --expansion: list # Comma-delimited list of additional date range metadata fields to include on response.
  --locale: string # Locale (default: en_US)
  --filterByIds: string # Filter list to only include date ranges in the specified list (comma-delimited list of IDs)
  --newDefinition: string@bool-completer # Use the new JSON def (default: false)
  --filterByModifiedAfter: string # Filter list to only include date ranges modified since this date (ISO8601 format)
  --curatedRsid: string # Include the curatedItem status for given Rsid
  --limit: int # Number of results per page (default: 10)
  --page: int # Page number (base 0 - first page is "0") (default: 0)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<id: string, name: string, description: string, modified: string, companyId: int, owner: record, definition: record, template: bool, createDate: string, disabledDate: string, alternateVariableNames: record<name: string, baseName: string, curatedName: string>, curatedItem: bool, imsOrgId: string, systemUserOwned: bool, tags: list<record>, shares: list<record>, approved: bool, favorite: bool, usageSummary: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeType" $includeType "csv") (serialize-qp "expansion" $expansion "csv") (serialize-qp "locale" $locale "scalar") (serialize-qp "filterByIds" $filterByIds "scalar") (serialize-qp "newDefinition" $newDefinition "scalar") (serialize-qp "filterByModifiedAfter" $filterByModifiedAfter "scalar") (serialize-qp "curatedRsid" $curatedRsid "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/dateranges" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a date range
#
# POST /{globalCompanyId}/dateranges
# --alternateVariableNames shape: {name?: string, baseName?: string, curatedName?: string}
export def "dateranges post" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expansion: list # Comma-delimited list of additional date range metadata fields to include on response.
  --newDefinition: string@bool-completer # Use the new JSON def (default: false)
  --locale: string # Locale (default: en_US)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --id: string
  --name: string
  --description: string
  --modified: string # format: date-time
  --companyId: int # format: int32
  --owner: record
  --definition: record
  --template: string@bool-completer
  --createDate: string # format: date-time
  --disabledDate: string # format: date-time
  --alternateVariableNames: record # shape: {name?: string, baseName?: string, curatedName?: string}
  --curatedItem: string@bool-completer
  --imsOrgId: string
  --systemUserOwned: string@bool-completer
  --tags: list
  --shares: list
  --approved: string@bool-completer
  --favorite: string@bool-completer
  --usageSummary: record
]: any -> record<id: string, name: string, description: string, modified: string, companyId: int, owner: record, definition: record, template: bool, createDate: string, disabledDate: string, alternateVariableNames: record<name: string, baseName: string, curatedName: string>, curatedItem: bool, imsOrgId: string, systemUserOwned: bool, tags: list<record>, shares: list<record>, approved: bool, favorite: bool, usageSummary: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expansion" $expansion "csv") (serialize-qp "newDefinition" $newDefinition "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/dateranges" $qp)
  let body = {id: $id, name: $name, description: $description, modified: $modified, companyId: $companyId, owner: $owner, definition: $definition, template: $template, createDate: $createDate, disabledDate: $disabledDate, alternateVariableNames: $alternateVariableNames, curatedItem: $curatedItem, imsOrgId: $imsOrgId, systemUserOwned: $systemUserOwned, tags: $tags, shares: $shares, approved: $approved, favorite: $favorite, usageSummary: $usageSummary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve dimensions for a report suite
#
# GET /{globalCompanyId}/dimensions
# operationId: dimensions_getDimensions
export def "dimensions list" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rsid: string # A report suite ID
  --locale: string # Locale (default: en_US)
  --segmentable: string@bool-completer # Only include dimensions that are valid within a segment.
  --reportable: string@bool-completer # Only include dimensions that are valid within a report.
  --classifiable: string@bool-completer # Only include classifiable dimensions. (default: false)
  --expansion: list@expansion-completer-1 # Add extra metadata to items (comma-delimited list)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> table<id: string, title: string, name: string, type: string, category: string, categories: list<string>, support: list<string>, pathable: bool, parent: string, extraTitleInfo: string, segmentable: bool, reportable: list<string>, description: string, allowedForReporting: bool, attributionModel: record, noneSettings: record<includeNoneByDefault: bool, noneChangeable: bool>, tags: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rsid" $rsid "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "segmentable" $segmentable "scalar") (serialize-qp "reportable" $reportable "scalar") (serialize-qp "classifiable" $classifiable "scalar") (serialize-qp "expansion" $expansion "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/dimensions" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a dimension by ID
#
# GET /{globalCompanyId}/dimensions/{id}
# operationId: dimensions_getDimension
export def "dimensions get" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rsid: string # The report suite ID.
  --locale: string # The locale to use for returning system named dimensions. (default: en_US)
  --expansion: list@expansion-completer-1 # Add extra metadata to items (comma-delimited list)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<id: string, title: string, name: string, type: string, category: string, categories: list<string>, support: list<string>, pathable: bool, parent: string, extraTitleInfo: string, segmentable: bool, reportable: list<string>, description: string, allowedForReporting: bool, attributionModel: record, noneSettings: record<includeNoneByDefault: bool, noneChangeable: bool>, tags: table<id: int, name: string, description: string, components: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rsid" $rsid "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "expansion" $expansion "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/dimensions/($id)" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve metrics for a report suite
#
# GET /{globalCompanyId}/metrics
# operationId: getMetrics
export def "metrics list" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rsid: string # ID of desired report suite
  --locale: string # Locale that system named metrics should be returned in (default: en_US)
  --segmentable: string@bool-completer # Filter the metrics by if they are valid in a segment. (default: false)
  --expansion: list@expansion-completer-2 # Add extra metadata to items (comma-delimited list)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<id: string, title: string, name: string, type: string, extraTitleInfo: string, category: string, categories: list<string>, support: list<string>, allocation: bool, precision: int, calculated: bool, segmentable: bool, description: string, polarity: string, helpLink: string, allowedForReporting: bool, tags: table<id: int, name: string, description: string, components: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rsid" $rsid "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "segmentable" $segmentable "scalar") (serialize-qp "expansion" $expansion "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/metrics" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a metric by ID
#
# GET /{globalCompanyId}/metrics/{id}
# operationId: getMetric
export def "metrics get" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rsid: string # ID of desired report suite
  --locale: string # Locale that system named metrics should be returned in (default: en_US)
  --expansion: list@expansion-completer-2 # Add extra metadata to items (comma-delimited list)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<id: string, title: string, name: string, type: string, extraTitleInfo: string, category: string, categories: list<string>, support: list<string>, allocation: bool, precision: int, calculated: bool, segmentable: bool, description: string, polarity: string, helpLink: string, allowedForReporting: bool, tags: table<id: int, name: string, description: string, components: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rsid" $rsid "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "expansion" $expansion "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/metrics/($id)" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve project configuration
#
# GET /{globalCompanyId}/projects/{id}
# operationId: projects_getProject
export def "projects get" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expansion: list # Comma-delimited list of additional project metadata fields to include on response.
  --locale: string # Locale (default: en_US)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<id: string, name: string, description: string, rsid: string, reportSuiteName: string, migratedIds: list<string>, companyTemplate: bool, template: bool, type: string, definition: record<valueNode: bool, floatingPointNumber: bool, containerNode: bool, missingNode: bool, pojo: bool, integralNumber: bool, short: bool, int: bool, long: bool, double: bool, bigDecimal: bool, bigInteger: bool, textual: bool, binary: bool, float: bool, nodeType: string, boolean: bool, number: bool, object: bool, array: bool, null: bool>, externalReferences: record, accessLevel: string, versionNotes: string, tags: list<record>, shares: list<record>, approved: bool, favorite: bool, usageSummary: record, complexity: record, owner: record<id: int, name: string, login: string>, siteTitle: string, modified: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expansion" $expansion "csv") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/projects/($id)" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a project configuration
#
# PUT /{globalCompanyId}/projects/{id}
# operationId: projects_updateProject
# --definition shape: {valueNode?: bool, floatingPointNumber?: bool, containerNode?: bool, missingNode?: bool, pojo?: bool, integralNumber?: bool, short?: bool, int?: bool, long?: bool, double?: bool, bigDecimal?: bool, bigInteger?: bool, textual?: bool, binary?: bool, float?: bool, nodeType?: "ARRAY"|"BINARY"|"BOOLEAN"|"MISSING"|"NULL"|"NUMBER"|"OBJECT"|"POJO"|"STRING", boolean?: bool, number?: bool, object?: bool, array?: bool, null?: bool}
# --owner shape: {id: int, name?: string, login?: string}
export def "projects updateProject" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expansion: list # Comma-delimited list of additional project metadata fields to include on response.
  --locale: string # Locale (default: en_US)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --name: string
  --description: string
  --rsid: string # The report suite id for which the component was created/updated
  --migratedIds: list
  --companyTemplate: string@bool-completer
  --template: string@bool-completer
  --type: string@type-completer-1
  --definition: record # shape: {valueNode?: bool, floatingPointNumber?: bool, containerNode?: bool, missingNode?: bool, pojo?: bool, integralNumber?: bool, short?: bool, int?: bool, long?: bool, double?: bool, bigDecimal?: bool, bigInteger?: bool, textual?: bool, binary?: bool, float?: bool, nodeType?: "ARRAY"|"BINARY"|"BOOLEAN"|"MISSING"|"NULL"|"NUMBER"|"OBJECT"|"POJO"|"STRING", boolean?: bool, number?: bool, object?: bool, array?: bool, null?: bool}
  --externalReferences: record
  --accessLevel: string
  --versionNotes: string
  --tags: list
  --shares: list
  --approved: string@bool-completer
  --favorite: string@bool-completer
  --usageSummary: record
  --complexity: record
  --owner: record # shape: {id: int, name?: string, login?: string}
  --siteTitle: string
  --modified: string # format: date-time
  --created: string # format: date-time
]: any -> record<id: string, name: string, description: string, rsid: string, reportSuiteName: string, migratedIds: list<string>, companyTemplate: bool, template: bool, type: string, definition: record<valueNode: bool, floatingPointNumber: bool, containerNode: bool, missingNode: bool, pojo: bool, integralNumber: bool, short: bool, int: bool, long: bool, double: bool, bigDecimal: bool, bigInteger: bool, textual: bool, binary: bool, float: bool, nodeType: string, boolean: bool, number: bool, object: bool, array: bool, null: bool>, externalReferences: record, accessLevel: string, versionNotes: string, tags: list<record>, shares: list<record>, approved: bool, favorite: bool, usageSummary: record, complexity: record, owner: record<id: int, name: string, login: string>, siteTitle: string, modified: string, created: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expansion" $expansion "csv") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/projects/($id)" $qp)
  let body = {name: $name, description: $description, rsid: $rsid, migratedIds: $migratedIds, companyTemplate: $companyTemplate, template: $template, type: $type, definition: $definition, externalReferences: $externalReferences, accessLevel: $accessLevel, versionNotes: $versionNotes, tags: $tags, shares: $shares, approved: $approved, favorite: $favorite, usageSummary: $usageSummary, complexity: $complexity, owner: $owner, siteTitle: $siteTitle, modified: $modified, created: $created} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a project
#
# DELETE /{globalCompanyId}/projects/{id}
# operationId: projects_deleteProject
export def "projects delete" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale (default: en_US)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<result: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/projects/($id)" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a valid project definition
#
# POST /{globalCompanyId}/projects/validate
# operationId: projects_validateProject
# --definition shape: {valueNode?: bool, floatingPointNumber?: bool, containerNode?: bool, missingNode?: bool, pojo?: bool, integralNumber?: bool, short?: bool, int?: bool, long?: bool, double?: bool, bigDecimal?: bool, bigInteger?: bool, textual?: bool, binary?: bool, float?: bool, nodeType?: "ARRAY"|"BINARY"|"BOOLEAN"|"MISSING"|"NULL"|"NUMBER"|"OBJECT"|"POJO"|"STRING", boolean?: bool, number?: bool, object?: bool, array?: bool, null?: bool}
# --owner shape: {id: int, name?: string, login?: string}
export def "projects-validate validateProject" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale (default: en_US)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --name: string
  --description: string
  --rsid: string # The report suite id for which the component was created/updated
  --migratedIds: list
  --companyTemplate: string@bool-completer
  --template: string@bool-completer
  --type: string@type-completer-1
  --definition: record # shape: {valueNode?: bool, floatingPointNumber?: bool, containerNode?: bool, missingNode?: bool, pojo?: bool, integralNumber?: bool, short?: bool, int?: bool, long?: bool, double?: bool, bigDecimal?: bool, bigInteger?: bool, textual?: bool, binary?: bool, float?: bool, nodeType?: "ARRAY"|"BINARY"|"BOOLEAN"|"MISSING"|"NULL"|"NUMBER"|"OBJECT"|"POJO"|"STRING", boolean?: bool, number?: bool, object?: bool, array?: bool, null?: bool}
  --externalReferences: record
  --accessLevel: string
  --versionNotes: string
  --tags: list
  --shares: list
  --approved: string@bool-completer
  --favorite: string@bool-completer
  --usageSummary: record
  --complexity: record
  --owner: record # shape: {id: int, name?: string, login?: string}
  --siteTitle: string
  --modified: string # format: date-time
  --created: string # format: date-time
]: any -> record<valid: bool, validatorVersion: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/projects/validate" $qp)
  let body = {name: $name, description: $description, rsid: $rsid, migratedIds: $migratedIds, companyTemplate: $companyTemplate, template: $template, type: $type, definition: $definition, externalReferences: $externalReferences, accessLevel: $accessLevel, versionNotes: $versionNotes, tags: $tags, shares: $shares, approved: $approved, favorite: $favorite, usageSummary: $usageSummary, complexity: $complexity, owner: $owner, siteTitle: $siteTitle, modified: $modified, created: $created} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve user's projects
#
# GET /{globalCompanyId}/projects
# operationId: projects_getProjects
export def "projects list" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeType: list # Include additional projects not owned by user. The "all" option takes precedence over "shared". If neither guided, or project is included, both types are returned
  --expansion: list # Comma-delimited list of additional project metadata fields to include on response.
  --filterByIds: string # Filter list to only include projects in the specified list (comma-delimited list of IDs)
  --locale: string # Locale (default: en_US)
  --pagination: string@pagination-completer # return paginated results (default: false)
  --ownerId: int # Filter list to only include projects owned by the specified loginId (format: int32)
  --limit: int # Number of results per page (default: 10)
  --page: int # Page number (base 0 - first page is "0") (default: 0)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> table<id: string, name: string, description: string, rsid: string, reportSuiteName: string, migratedIds: list<string>, companyTemplate: bool, template: bool, type: string, definition: record<valueNode: bool, floatingPointNumber: bool, containerNode: bool, missingNode: bool, pojo: bool, integralNumber: bool, short: bool, int: bool, long: bool, double: bool, bigDecimal: bool, bigInteger: bool, textual: bool, binary: bool, float: bool, nodeType: string, boolean: bool, number: bool, object: bool, array: bool, null: bool>, externalReferences: record, accessLevel: string, versionNotes: string, tags: list<record>, shares: list<record>, approved: bool, favorite: bool, usageSummary: record, complexity: record, owner: record<id: int, name: string, login: string>, siteTitle: string, modified: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeType" $includeType "csv") (serialize-qp "expansion" $expansion "csv") (serialize-qp "filterByIds" $filterByIds "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "pagination" $pagination "scalar") (serialize-qp "ownerId" $ownerId "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/projects" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a project
#
# POST /{globalCompanyId}/projects
# operationId: projects_createProject
# --definition shape: {valueNode?: bool, floatingPointNumber?: bool, containerNode?: bool, missingNode?: bool, pojo?: bool, integralNumber?: bool, short?: bool, int?: bool, long?: bool, double?: bool, bigDecimal?: bool, bigInteger?: bool, textual?: bool, binary?: bool, float?: bool, nodeType?: "ARRAY"|"BINARY"|"BOOLEAN"|"MISSING"|"NULL"|"NUMBER"|"OBJECT"|"POJO"|"STRING", boolean?: bool, number?: bool, object?: bool, array?: bool, null?: bool}
# --owner shape: {id: int, name?: string, login?: string}
export def "projects createProject" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expansion: list # Comma-delimited list of additional project metadata fields to include on response.
  --locale: string # Locale (default: en_US)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --name: string
  --description: string
  --rsid: string # The report suite id for which the component was created/updated
  --migratedIds: list
  --companyTemplate: string@bool-completer
  --template: string@bool-completer
  --type: string@type-completer-1
  --definition: record # shape: {valueNode?: bool, floatingPointNumber?: bool, containerNode?: bool, missingNode?: bool, pojo?: bool, integralNumber?: bool, short?: bool, int?: bool, long?: bool, double?: bool, bigDecimal?: bool, bigInteger?: bool, textual?: bool, binary?: bool, float?: bool, nodeType?: "ARRAY"|"BINARY"|"BOOLEAN"|"MISSING"|"NULL"|"NUMBER"|"OBJECT"|"POJO"|"STRING", boolean?: bool, number?: bool, object?: bool, array?: bool, null?: bool}
  --externalReferences: record
  --accessLevel: string
  --versionNotes: string
  --tags: list
  --shares: list
  --approved: string@bool-completer
  --favorite: string@bool-completer
  --usageSummary: record
  --complexity: record
  --owner: record # shape: {id: int, name?: string, login?: string}
  --siteTitle: string
  --modified: string # format: date-time
  --created: string # format: date-time
]: any -> record<id: string, name: string, description: string, rsid: string, reportSuiteName: string, migratedIds: list<string>, companyTemplate: bool, template: bool, type: string, definition: record<valueNode: bool, floatingPointNumber: bool, containerNode: bool, missingNode: bool, pojo: bool, integralNumber: bool, short: bool, int: bool, long: bool, double: bool, bigDecimal: bool, bigInteger: bool, textual: bool, binary: bool, float: bool, nodeType: string, boolean: bool, number: bool, object: bool, array: bool, null: bool>, externalReferences: record, accessLevel: string, versionNotes: string, tags: list<record>, shares: list<record>, approved: bool, favorite: bool, usageSummary: record, complexity: record, owner: record<id: int, name: string, login: string>, siteTitle: string, modified: string, created: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expansion" $expansion "csv") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/projects" $qp)
  let body = {name: $name, description: $description, rsid: $rsid, migratedIds: $migratedIds, companyTemplate: $companyTemplate, template: $template, type: $type, definition: $definition, externalReferences: $externalReferences, accessLevel: $accessLevel, versionNotes: $versionNotes, tags: $tags, shares: $shares, approved: $approved, favorite: $favorite, usageSummary: $usageSummary, complexity: $complexity, owner: $owner, siteTitle: $siteTitle, modified: $modified, created: $created} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a report
#
# POST /{globalCompanyId}/reports
# operationId: runReport
# --locale shape: {language?: string, script?: string, country?: string, variant?: string, extensionKeys?: list, unicodeLocaleAttributes?: list, unicodeLocaleKeys?: list, iso3Language?: string, iso3Country?: string, displayLanguage?: string, displayScript?: string, displayCountry?: string, displayVariant?: string, displayName?: string}
# --globalFilters item shape: {id?: string, type?: "dateRange"|"breakdown"|"segment"|"excludeItemIds", dimension?: string, itemId?: string, itemIds?: list, segmentId?: string, segmentDefinition?: record, dateRange?: string, dateRangeRelative?: string, excludeItemIds?: list}
# --search shape: {clause?: string, excludeItemIds?: list, itemIds?: list, includeSearchTotal?: bool, empty?: bool}
# --settings shape: {limit?: int, page?: int, dimensionSort?: string, countRepeatInstances?: bool, reflectRequest?: bool, includeAnomalyDetection?: bool, includeForecasting?: bool, includePercentChange?: bool, includeLatLong?: bool, nonesBehavior?: string}
# --statistics shape: {functions?: list, ignoreZeroes?: bool}
# --metricContainer shape: {metricFilters?: list, metrics?: list}
# --rowContainer shape: {rowFilters?: list, rows?: list}
export def "reports runReport" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --rsid: string
  --dimension: string
  --locale: record # shape: {language?: string, script?: string, country?: string, variant?: string, extensionKeys?: list, unicodeLocaleAttributes?: list, unicodeLocaleKeys?: list, iso3Language?: string, iso3Country?: string, displayLanguage?: string, displayScript?: string, displayCountry?: string, displayVariant?: string, displayName?: string}
  --globalFilters: list # item shape: {id?: string, type?: "dateRange"|"breakdown"|"segment"|"excludeItemIds", dimension?: string, itemId?: string, itemIds?: list, segmentId?: string, segmentDefinition?: record, dateRange?: string, dateRangeRelative?: string, excludeItemIds?: list}
  --search: record # shape: {clause?: string, excludeItemIds?: list, itemIds?: list, includeSearchTotal?: bool, empty?: bool}
  --settings: record # shape: {limit?: int, page?: int, dimensionSort?: string, countRepeatInstances?: bool, reflectRequest?: bool, includeAnomalyDetection?: bool, includeForecasting?: bool, includePercentChange?: bool, includeLatLong?: bool, nonesBehavior?: string}
  --statistics: record # shape: {functions?: list, ignoreZeroes?: bool}
  --metricContainer: record # shape: {metricFilters?: list, metrics?: list}
  --rowContainer: record # shape: {rowFilters?: list, rows?: list}
  --anchorDate: string
]: any -> record<totalPages: int, firstPage: bool, lastPage: bool, numberOfElements: int, number: int, totalElements: int, message: string, request: record<rsid: string, dimension: string, locale: record<language: string, script: string, country: string, variant: string, extensionKeys: list, unicodeLocaleAttributes: list, unicodeLocaleKeys: list, iso3Language: string, iso3Country: string, displayLanguage: string, displayScript: string, displayCountry: string, displayVariant: string, displayName: string>, globalFilters: list<record>, search: record<clause: string, excludeItemIds: list, itemIds: list, includeSearchTotal: bool, empty: bool>, settings: record<limit: int, page: int, dimensionSort: string, countRepeatInstances: bool, reflectRequest: bool, includeAnomalyDetection: bool, includeForecasting: bool, includePercentChange: bool, includeLatLong: bool, nonesBehavior: string>, statistics: record<functions: list, ignoreZeroes: bool>, metricContainer: record<metricFilters: list, metrics: list>, rowContainer: record<rowFilters: list, rows: list>, anchorDate: string>, reportId: string, columns: record<dimension: record<id: string, type: string>, columnIds: list<string>, columnErrors: list<record>>, rows: table<itemId: string, value: string, rowId: string, data: list, dataExpected: list, dataUpperBound: list, dataLowerBound: list, dataAnomalyDetected: list, percentChange: list, latitude: float, longitude: float, dataForecasted: list, dataForecastedUpperBound: list, dataForecastedLowerBound: list>, summaryData: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($globalCompanyId)/reports")
  let body = {rsid: $rsid, dimension: $dimension, locale: $locale, globalFilters: $globalFilters, search: $search, settings: $settings, statistics: $statistics, metricContainer: $metricContainer, rowContainer: $rowContainer, anchorDate: $anchorDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a realtime report
#
# POST /{globalCompanyId}/reports/realtime
# operationId: runRealtimeReport
# --locale shape: {language?: string, script?: string, country?: string, variant?: string, extensionKeys?: list, unicodeLocaleAttributes?: list, unicodeLocaleKeys?: list, iso3Language?: string, iso3Country?: string, displayLanguage?: string, displayScript?: string, displayCountry?: string, displayVariant?: string, displayName?: string}
# --globalFilters item shape: {id?: string, type?: "dateRange"|"breakdown"|"segment"|"excludeItemIds", dimension?: string, itemId?: string, itemIds?: list, segmentId?: string, segmentDefinition?: record, dateRange?: string, dateRangeRelative?: string, excludeItemIds?: list}
# --search shape: {clause?: string, excludeItemIds?: list, itemIds?: list, includeSearchTotal?: bool, empty?: bool}
# --settings shape: {limit?: int, page?: int, dimensionSort?: string, countRepeatInstances?: bool, reflectRequest?: bool, includeAnomalyDetection?: bool, includeForecasting?: bool, includePercentChange?: bool, includeLatLong?: bool, nonesBehavior?: string}
# --statistics shape: {functions?: list, ignoreZeroes?: bool}
# --metricContainer shape: {metricFilters?: list, metrics?: list}
# --rowContainer shape: {rowFilters?: list, rows?: list}
export def "reports-realtime runRealtimeReport" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --rsid: string
  --dimension: string
  --locale: record # shape: {language?: string, script?: string, country?: string, variant?: string, extensionKeys?: list, unicodeLocaleAttributes?: list, unicodeLocaleKeys?: list, iso3Language?: string, iso3Country?: string, displayLanguage?: string, displayScript?: string, displayCountry?: string, displayVariant?: string, displayName?: string}
  --globalFilters: list # item shape: {id?: string, type?: "dateRange"|"breakdown"|"segment"|"excludeItemIds", dimension?: string, itemId?: string, itemIds?: list, segmentId?: string, segmentDefinition?: record, dateRange?: string, dateRangeRelative?: string, excludeItemIds?: list}
  --search: record # shape: {clause?: string, excludeItemIds?: list, itemIds?: list, includeSearchTotal?: bool, empty?: bool}
  --settings: record # shape: {limit?: int, page?: int, dimensionSort?: string, countRepeatInstances?: bool, reflectRequest?: bool, includeAnomalyDetection?: bool, includeForecasting?: bool, includePercentChange?: bool, includeLatLong?: bool, nonesBehavior?: string}
  --statistics: record # shape: {functions?: list, ignoreZeroes?: bool}
  --metricContainer: record # shape: {metricFilters?: list, metrics?: list}
  --rowContainer: record # shape: {rowFilters?: list, rows?: list}
  --anchorDate: string
]: any -> record<totalPages: int, firstPage: bool, lastPage: bool, numberOfElements: int, number: int, totalElements: int, message: string, request: record<rsid: string, dimension: string, locale: record<language: string, script: string, country: string, variant: string, extensionKeys: list, unicodeLocaleAttributes: list, unicodeLocaleKeys: list, iso3Language: string, iso3Country: string, displayLanguage: string, displayScript: string, displayCountry: string, displayVariant: string, displayName: string>, globalFilters: list<record>, search: record<clause: string, excludeItemIds: list, itemIds: list, includeSearchTotal: bool, empty: bool>, settings: record<limit: int, page: int, dimensionSort: string, countRepeatInstances: bool, reflectRequest: bool, includeAnomalyDetection: bool, includeForecasting: bool, includePercentChange: bool, includeLatLong: bool, nonesBehavior: string>, statistics: record<functions: list, ignoreZeroes: bool>, metricContainer: record<metricFilters: list, metrics: list>, rowContainer: record<rowFilters: list, rows: list>, anchorDate: string>, reportId: string, columns: record<dimension: record<id: string, type: string>, columnIds: list<string>, columnErrors: list<record>>, rows: table<itemId: string, value: string, rowId: string, data: list, dataExpected: list, dataUpperBound: list, dataLowerBound: list, dataAnomalyDetected: list, percentChange: list, latitude: float, longitude: float, dataForecasted: list, dataForecastedUpperBound: list, dataForecastedLowerBound: list>, summaryData: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($globalCompanyId)/reports/realtime")
  let body = {rsid: $rsid, dimension: $dimension, locale: $locale, globalFilters: $globalFilters, search: $search, settings: $settings, statistics: $statistics, metricContainer: $metricContainer, rowContainer: $rowContainer, anchorDate: $anchorDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve top items report
#
# GET /{globalCompanyId}/reports/topItems
# operationId: runTopItemReport
export def "reports-top-items runTopItemReport" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rsid: string # ID of desired report suite ie. myrsid
  --dimension: string # Dimension to run the report against. Example: 'variables/page'
  --locale: string # Locale that system named metrics should be returned in (default: en_US)
  --dateRange: string # Format: YYYY-MM-DD/YYYY-MM-DD
  --search-clause: string # General search string; wrap with single quotes. Example: 'PageABC'
  --startDate: string # Format: YYYY-MM-DD
  --endDate: string # Format: YYYY-MM-DD
  --searchAnd: string # Search terms that will be AND-ed together. Space delimited.
  --searchOr: string # Search terms that will be OR-ed together. Space delimited.
  --searchNot: string # Search terms that will be treated as NOT including. Space delimited.
  --searchPhrase: string # A full search phrase that will be searched for.
  --lookupNoneValues: string@bool-completer # Controls None values to be included (default: true)
  --limit: int # Number of results per page (default: 10)
  --page: int # Page number (base 0 - first page is "0") (default: 0)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<totalPages: int, firstPage: bool, lastPage: bool, numberOfElements: int, number: int, totalElements: int, message: string, reportId: string, searchAnd: string, searchOr: string, searchNot: string, searchPhrase: string, oberonRequestXML: string, oberonResponseXML: string, rows: table<itemId: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rsid" $rsid "scalar") (serialize-qp "dimension" $dimension "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "dateRange" $dateRange "scalar") (serialize-qp "search-clause" $search_clause "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "searchAnd" $searchAnd "scalar") (serialize-qp "searchOr" $searchOr "scalar") (serialize-qp "searchNot" $searchNot "scalar") (serialize-qp "searchPhrase" $searchPhrase "scalar") (serialize-qp "lookupNoneValues" $lookupNoneValues "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/reports/topItems" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all segments
#
# GET /{globalCompanyId}/segments
# operationId: segments_getSegments
export def "segments list" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rsids: string # Filter list to only include segments tied to specified RSID list (comma-delimited)
  --segmentFilter: string # Filter list to only include segments in the specified list (comma-delimited list of IDs)
  --locale: string # Locale (default: en_US)
  --name: string # Filter list to only include segments that contains the Name
  --tagNames: string # Filter list to only include segments that contains one of the tags
  --filterByPublishedSegments: string@filterByPublishedSegments-completer # Filter list to only include segments where the published field is set to one of the allowable values (all, true, false). (default: all)
  --limit: int # Number of results per page (default: 10)
  --page: int # Page number (base 0 - first page is "0") (default: 0)
  --sortDirection: string # Sort direction (ASC or DESC (default: ASC)
  --sortProperty: string # Property to sort by (name, modified_date, id is currently allowed) (default: id)
  --expansion: list@expansion-completer-3 # Comma-delimited list of additional segment metadata fields to include on response.
  --includeType: list@includeType-completer # Include additional segments not owned by user. The "all" option takes precedence over "shared"
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<id: string, name: string, description: string, rsid: string, reportSuiteName: string, owner: record<id: int, name: string, login: string>, definition: record<container: record<context: string, func: string, pred: record>, func: string, version: list<int>>, compatibility: record<valid: bool, message: string, validator_version: string, supported_products: list<string>, supported_schema: list<string>, supported_features: list<string>>, definitionLastModified: string, categories: list<string>, siteTitle: string, tags: table<id: int, name: string, description: string, components: list>, modified: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rsids" $rsids "scalar") (serialize-qp "segmentFilter" $segmentFilter "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "tagNames" $tagNames "scalar") (serialize-qp "filterByPublishedSegments" $filterByPublishedSegments "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "sortProperty" $sortProperty "scalar") (serialize-qp "expansion" $expansion "csv") (serialize-qp "includeType" $includeType "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/segments" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a segment
#
# POST /{globalCompanyId}/segments
# operationId: segments_createSegment
# --owner shape: {id: int, name?: string, login?: string}
# --definition shape: {container?: record, func?: string, version?: list}
# --compatibility shape: {valid?: bool, message?: string, validator_version?: string, supported_products?: list, supported_schema?: list, supported_features?: list}
# --tags item shape: {id?: int, name?: string, description?: string, components?: list}
export def "segments createSegment" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale. Valid values include 'en_US', 'fr_FR', 'ja_JP', 'de_DE', 'es_ES', 'ko_KR', 'pt_BR', 'zh_CN', and 'zh_TW'. (default: en_US)
  --expansion: list@expansion-completer-3 # Comma-delimited list of additional segment metadata fields to include on response.
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --name: string # A name for the segment.
  --description: string # A description of the segment.
  --rsid: string # The report suite id.
  --reportSuiteName: string # The friendly name for the report suite id.
  --owner: record # shape: {id: int, name?: string, login?: string}
  --definition: record # shape: {container?: record, func?: string, version?: list}
  --compatibility: record # shape: {valid?: bool, message?: string, validator_version?: string, supported_products?: list, supported_schema?: list, supported_features?: list}
  --definitionLastModified: string # format: date-time
  --categories: list
  --siteTitle: string # A name for the report suite.  This is deprecated and should use the report suite name instead.
  --tags: list # All existing tags associated with the segment. — item shape: {id?: int, name?: string, description?: string, components?: list}
  --modified: string # format: date-time
  --created: string # format: date-time
]: any -> record<id: string, name: string, description: string, rsid: string, reportSuiteName: string, owner: record<id: int, name: string, login: string>, definition: record<container: record<context: string, func: string, pred: record>, func: string, version: list<int>>, compatibility: record<valid: bool, message: string, validator_version: string, supported_products: list<string>, supported_schema: list<string>, supported_features: list<string>>, definitionLastModified: string, categories: list<string>, siteTitle: string, tags: table<id: int, name: string, description: string, components: list>, modified: string, created: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "expansion" $expansion "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/segments" $qp)
  let body = {name: $name, description: $description, rsid: $rsid, reportSuiteName: $reportSuiteName, owner: $owner, definition: $definition, compatibility: $compatibility, definitionLastModified: $definitionLastModified, categories: $categories, siteTitle: $siteTitle, tags: $tags, modified: $modified, created: $created} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create validation for segment
#
# POST /{globalCompanyId}/segments/validate
# operationId: segments_validateSegment
export def "segments-validate validateSegment" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rsid: string # RSID to run the report against
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --body: record
]: any -> record<valid: bool, message: string, validator_version: string, supported_products: list<string>, supported_schema: list<string>, supported_features: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rsid" $rsid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/segments/validate" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a segment by ID
#
# GET /{globalCompanyId}/segments/{id}
# operationId: segments_getSegment
export def "segments get" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale. Valid values include 'en_US', 'fr_FR', 'ja_JP', 'de_DE', 'es_ES', 'ko_KR', 'pt_BR', 'zh_CN', and 'zh_TW'. (default: en_US)
  --expansion: list@expansion-completer-3 # Comma-delimited list of additional segment metadata fields to include on response.
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<id: string, name: string, description: string, rsid: string, reportSuiteName: string, owner: record<id: int, name: string, login: string>, definition: record<container: record<context: string, func: string, pred: record>, func: string, version: list<int>>, compatibility: record<valid: bool, message: string, validator_version: string, supported_products: list<string>, supported_schema: list<string>, supported_features: list<string>>, definitionLastModified: string, categories: list<string>, siteTitle: string, tags: table<id: int, name: string, description: string, components: list>, modified: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "expansion" $expansion "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/segments/($id)" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a segment by ID
#
# PUT /{globalCompanyId}/segments/{id}
# operationId: segments_updateSegment
export def "segments updateSegment" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale. Valid values include 'en_US', 'fr_FR', 'ja_JP', 'de_DE', 'es_ES', 'ko_KR', 'pt_BR', 'zh_CN', and 'zh_TW'. (default: en_US)
  --expansion: list@expansion-completer-3 # Comma-delimited list of additional segment metadata fields to include on response.
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
  --body: record
]: any -> record<id: string, name: string, description: string, rsid: string, reportSuiteName: string, owner: record<id: int, name: string, login: string>, definition: record<container: record<context: string, func: string, pred: record>, func: string, version: list<int>>, compatibility: record<valid: bool, message: string, validator_version: string, supported_products: list<string>, supported_schema: list<string>, supported_features: list<string>>, definitionLastModified: string, categories: list<string>, siteTitle: string, tags: table<id: int, name: string, description: string, components: list>, modified: string, created: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "expansion" $expansion "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/segments/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a segment by ID
#
# DELETE /{globalCompanyId}/segments/{id}
# operationId: segments_deleteSegment
export def "segments delete" [
  globalCompanyId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale. Valid values include 'en_US', 'fr_FR', 'ja_JP', 'de_DE', 'es_ES', 'ko_KR', 'pt_BR', 'zh_CN', and 'zh_TW'. (default: en_US)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/segments/($id)" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve users for current company
#
# GET /{globalCompanyId}/users
export def "users get" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results per page (default: 10)
  --page: int # Page number (base 0 - first page is "0") (default: 0)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> table<companyid: int, loginId: int, login: string, changePassword: bool, createDate: string, disabled: bool, email: string, firstName: string, fullName: string, imsUserId: string, lastName: string, lastAccess: string, phoneNumber: string, tempLoginEnd: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/users" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve current user
#
# GET /{globalCompanyId}/users/me
# operationId: getCurrentUser
export def "users-me get" [
  globalCompanyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<companyid: int, loginId: int, login: string, changePassword: bool, createDate: string, disabled: bool, email: string, firstName: string, fullName: string, imsUserId: string, lastName: string, lastAccess: string, phoneNumber: string, tempLoginEnd: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($globalCompanyId)/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve logs for provided search criteria
#
# GET /{globalCompanyId}/auditlogs/usage
# operationId: getUsageAccessLogs
export def "auditlogs-usage get" [
  globalCompanyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startDate: string # Start date for the maximum of a 3 month period. (default: 2021-01-01T00:00:00-07)
  --endDate: string # End date for the maximum of a 3 month period. (default: 2021-01-02T14:32:33-07)
  --login: string # The login value of the user you want to filter logs by.
  --ip: string # The IP address you want to filter logs by.
  --rsid: string # The report suite ID you want to filter logs by.
  --eventType: string # The numeric id for the event type you want to filter logs by.
  --event: string # The event description you want to filter logs by. No wildcards permitted.
  --limit: int # Number of results per page. (format: int32, default: 10)
  --page: int # Page number (base 0 - first page is "0"). (format: int32, default: 0)
  --Authorization: string # The access token copied from your AA API client integration, prefixed with "Bearer ".
  --x-api-key: string # The API key copied from your AA API client integration. For more information on how to obtain this value, see [Getting started with the Analytics API](https://developer.adobe.com/analytics-apis/docs/2.0/guides/).
]: nothing -> record<content: table<dateCreated: string, eventDescription: string, ipAddress: string, rsid: string, eventType: string, login: string>, totalElements: int, lastPage: bool, numberOfElements: int, totalPages: int, firstPage: bool, sort: string, size: int, number: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "login" $login "scalar") (serialize-qp "ip" $ip "scalar") (serialize-qp "rsid" $rsid "scalar") (serialize-qp "eventType" $eventType "scalar") (serialize-qp "event" $event "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($globalCompanyId)/auditlogs/usage" $qp)
  let extra_headers = {"Authorization": $Authorization, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
