# Auto-generated client for ETSI GS MEC 010-2 - Part 2: Application lifecycle, rules and requirements management v2.1.1
# Source: https://api.apis.guru/v2/specs/etsi.local/MEC010-2_AppPkgMgmt/2.1.1/openapi.json
# Auth: --token flag or $env.ETSI_GS_MEC_010_2_PART_2__APPLICATION_LIFECYCLE__RULES_AND_REQUIREMENTS_MANAGEMENT_TOKEN

const BASE_URL = "http://etsi.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ETSI_GS_MEC_010_2_PART_2__APPLICATION_LIFECYCLE__RULES_AND_REQUIREMENTS_MANAGEMENT_TOKEN | default "" }
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

def base-url-completer [] { ["http://etsi.local" "https://localhost/app_pkgm/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def operationState-completer [] { ["DISABLED" "ENABLED"] }
def accept-completer [] { ["application/zip" "text/plain"] }
def subsctiptionType-completer [] { ["AppPacakgeOperationChange" "AppPackageDeletion" "AppPackageOnBoarding"] }
def notificationType-completer [] { ["AppPacakgeDisabled" "AppPacakgeEnabled" "AppPackageDeleted" "AppPackageOnBoarded"] }
def operationalState-completer [] { ["DISABLED" "ENABLED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "app-packages packagesGET" } } | get name | first)
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

# Queries information relating to on-boarded application packages in the MEO
#
# GET /app_packages
# operationId: app_packagesGET
export def "app-packages packagesGET" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Attribute-based filtering parameters according to ETSI GS MEC 009
  --all-fields: string # Include all complex attributes in the response.
  --fields: string # Complex attributes of AppPkgInfo to be included into the response
  --exclude-fields: string # Complex attributes of AppPkgInfo to be excluded from the response.
  --exclude-default: string # Indicates to exclude the following complex attributes of AppPkgInfo from the response.
]: nothing -> table<_links: record<appD: record, appPkgContent: record, self: record>, additionalArtifacts: any, appDId: string, appDVersion: string, appName: string, appProvider: string, appSoftwareVersion: string, checksum: record<algorithm: string, hash: string>, id: string, onboardingState: string, operationalState: string, softwareImages: any, usageState: string, userDefinedData: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "all_fields" $all_fields "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "exclude_fields" $exclude_fields "scalar") (serialize-qp "exclude_default" $exclude_default "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/app_packages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a resource for on-boarding an application package to a MEO
#
# POST /app_packages
# operationId: app_packagesPOST
# --checksum shape: {algorithm: string, hash: string}
export def "app-packages packagesPOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  appPkgName: string # Name of the application package to be onboarded.
  appPkgPath: string
  appPkgVersion: string # Version of the application package to be onboarded. The appPkgName with appPkgVersion can be used to uniquely identify the application package.
  --appProvider: string # The provider's name of the application package to be onboarded.
  checksum: record # shape: {algorithm: string, hash: string}
  --userDefinedData: record # 'This data type represents a list of key-value pairs. The order of the pairs in the list is not significant. In JSON, a set of key-value pairs is represented as an object. It shall comply with the provisions defined in clause 4 of IETF RFC 8259'
]: any -> table<_links: record<appD: record, appPkgContent: record, self: record>, additionalArtifacts: any, appDId: string, appDVersion: string, appName: string, appProvider: string, appSoftwareVersion: string, checksum: record<algorithm: string, hash: string>, id: string, onboardingState: string, operationalState: string, softwareImages: any, usageState: string, userDefinedData: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/app_packages")
  let body = {appPkgName: $appPkgName, appPkgPath: $appPkgPath, appPkgVersion: $appPkgVersion, appProvider: $appProvider, checksum: $checksum, userDefinedData: $userDefinedData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an individual application package resources
#
# DELETE /app_packages/{appPkgId}
# operationId: app_packageDELETE
export def "app-packages packageDELETE" [
  appPkgId: string
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
  let full_url = (build-url $base $"/app_packages/($appPkgId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Queries the information related to individual application package resources
#
# GET /app_packages/{appPkgId}
# operationId: app_packageGET
export def "app-packages packageGET" [
  appPkgId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<appD: record<href: string>, appPkgContent: record<href: string>, self: record<href: string>>, additionalArtifacts: any, appDId: string, appDVersion: string, appName: string, appProvider: string, appSoftwareVersion: string, checksum: record<algorithm: string, hash: string>, id: string, onboardingState: string, operationalState: string, softwareImages: any, usageState: string, userDefinedData: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/app_packages/($appPkgId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the operational state of an individual application package resource
#
# PATCH /app_packages/{appPkgId}
# operationId: app_packagePATCH
export def "app-packages packagePATCH" [
  appPkgId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  operationState: string@operationState-completer
]: any -> record<operationState: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/app_packages/($appPkgId)")
  let body = {operationState: $operationState} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reads the content of the AppD of on-boarded individual application package resources.
#
# GET /app_packages/{appPkgId}/appd
# operationId: appPkgIdGET
export def "app-packages-appd appPkgIdGET" [
  appPkgId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # Attribute-based filtering parameters according to ETSI GS MEC 009
  --all-fields: string # Include all complex attributes in the response.
  --fields: string # Complex attributes of AppPkgInfo to be included into the response
  --exclude-fields: string # Complex attributes of AppPkgInfo to be excluded from the response.
  --exclude-default: string # Indicates to exclude the following complex attributes of AppPkgInfo from the response.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "all_fields" $all_fields "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "exclude_fields" $exclude_fields "scalar") (serialize-qp "exclude_default" $exclude_default "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/app_packages/($appPkgId)/appd" $qp)
  let accept_val = ($accept | default "application/zip")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the onboarded application package content identified by appPkgId or appDId.
#
# GET /app_packages/{appPkgId}/package_content
# operationId: appPkgGET
export def "app-packages-package-content appPkgGET" [
  appPkgId: string
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
  let full_url = (build-url $base $"/app_packages/($appPkgId)/package_content")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Uploads the content of application package.
#
# PUT /app_packages/{appPkgId}/package_content
# operationId: appPkgPUT
export def "app-packages-package-content appPkgPUT" [
  appPkgId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/app_packages/($appPkgId)/package_content")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/zip" $body
}

# Reads the content of the AppD of on-boarded individual application package resources.
#
# GET /onboarded_app_packages/{appDId}/appd
# operationId: appDGET
export def "onboarded-app-packages-appd appDGET" [
  appDId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # Attribute-based filtering parameters according to ETSI GS MEC 009
  --all-fields: string # Include all complex attributes in the response.
  --fields: string # Complex attributes of AppPkgInfo to be included into the response
  --exclude-fields: string # Complex attributes of AppPkgInfo to be excluded from the response.
  --exclude-default: string # Indicates to exclude the following complex attributes of AppPkgInfo from the response.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "all_fields" $all_fields "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "exclude_fields" $exclude_fields "scalar") (serialize-qp "exclude_default" $exclude_default "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onboarded_app_packages/($appDId)/appd" $qp)
  let accept_val = ($accept | default "application/zip")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the onboarded application package content identified by appPkgId or appDId.
#
# GET /onboarded_app_packages/{appDId}/package_content
# operationId: appDIdGET
export def "onboarded-app-packages-package-content appDIdGET" [
  appDId: string
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
  let full_url = (build-url $base $"/onboarded_app_packages/($appDId)/package_content")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Uploads the content of application package.
#
# PUT /onboarded_app_packages/{appDId}/package_content
# operationId: appDIdPUT
export def "onboarded-app-packages-package-content appDIdPUT" [
  appDId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/onboarded_app_packages/($appDId)/package_content")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/zip" $body
}

# used to retrieve the information of subscriptions to individual application package resource in MEO
#
# GET /subscriptions
# operationId: subscriptionsGET
export def "subscriptions subscriptionsGET" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<self: record<href: string>, subscriptions: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscriptions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe to notifications about on-boarding an application package
#
# POST /subscriptions
# operationId: subscriptionsPOST
export def "subscriptions subscriptionsPOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appPkgFilter: list
  callbackUri: string # The URI of the endpoint for the notification to be sent to. (format: uri)
  subsctiptionType: string@subsctiptionType-completer # 'Subscribed notification type'
]: any -> record<_links: record<self: record<href: string>>, callbackUri: string, id: string, subscriptionType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscriptions")
  let body = {appPkgFilter: $appPkgFilter, callbackUri: $callbackUri, subsctiptionType: $subsctiptionType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the individual subscription to notifications about application package changes in MEO.
#
# DELETE /subscriptions/{subscriptionId}
# operationId: individualSubscriptionDELETE
export def "subscriptions individualSubscriptionDELETE" [
  subscriptionId: string
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
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Used to represent an individual subscription to notifications about application package changes.
#
# GET /subscriptions/{subscriptionId}
# operationId: individualSubscriptionGET
export def "subscriptions individualSubscriptionGET" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<self: record<href: string>>, callbackUri: string, id: string, subscriptionType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Registers a notification endpoint to notify application package operations
#
# POST /user_defined_notification
# operationId: app_pkg_notificationPOST
# --_links shape: {subscription: record}
# --timeStamp shape: {nanoSeconds: int, seconds: int}
export def "user-defined-notification notificationPOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  links: record # Links to resources related to this resource. — shape: {subscription: record}
  appDId: string # Identifier of this MEC application descriptor. This attribute shall be globally unique.
  appPkgId: string # Identifier of the onboarded application package.
  id: string # ''
  notificationType: string@notificationType-completer # Discriminator for the different notification types
  operationalState: string@operationalState-completer
  subscriptionId: string # Identifier of the subscription related to this notification.
  timeStamp: record # shape: {nanoSeconds: int, seconds: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_defined_notification")
  let body = {_links: $links, appDId: $appDId, appPkgId: $appPkgId, id: $id, notificationType: $notificationType, operationalState: $operationalState, subscriptionId: $subscriptionId, timeStamp: $timeStamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
