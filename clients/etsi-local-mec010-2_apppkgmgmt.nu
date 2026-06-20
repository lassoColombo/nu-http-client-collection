# Auto-generated client for ETSI GS MEC 010-2 - Part 2: Application lifecycle, rules and requirements management v2.1.1
# Source: https://api.apis.guru/v2/specs/etsi.local/MEC010-2_AppPkgMgmt/2.1.1/openapi.json
# Auth: --token flag or $env.ETSI_GS_MEC_010_2_PART_2_APPLICATION_LIFECYCLE_RULES_AND_REQUIREMENTS_MANAGEMENT_TOKEN

const BASE_URL = "http://etsi.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ETSI_GS_MEC_010_2_PART_2_APPLICATION_LIFECYCLE_RULES_AND_REQUIREMENTS_MANAGEMENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["http://etsi.local" "https://localhost/app_pkgm/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def operation-state-completer [] { ["DISABLED" "ENABLED"] }
def accept-completer [] { ["application/zip" "text/plain"] }
def subsctiption-type-completer [] { ["AppPacakgeOperationChange" "AppPackageDeletion" "AppPackageOnBoarding"] }
def notification-type-completer [] { ["AppPacakgeDisabled" "AppPacakgeEnabled" "AppPackageDeleted" "AppPackageOnBoarded"] }
def operational-state-completer [] { ["DISABLED" "ENABLED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "app-packages list" } } | get name | first)
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
export def "app-packages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "all_fields": $all_fields, "fields": $fields, "exclude_fields": $exclude_fields, "exclude_default": $exclude_default} | compact), body: null}
}

# Create a resource for on-boarding an application package to a MEO
#
# POST /app_packages
# operationId: app_packagesPOST
# --checksum shape: {algorithm: string, hash: string}
export def "app-packages create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  app_pkg_name: string # Name of the application package to be onboarded.
  app_pkg_path: string
  app_pkg_version: string # Version of the application package to be onboarded. The appPkgName with appPkgVersion can be used to uniquely identify the application package.
  --app-provider: string # The provider's name of the application package to be onboarded.
  checksum: record # shape: {algorithm: string, hash: string}
  --user-defined-data: record # 'This data type represents a list of key-value pairs. The order of the pairs in the list is not significant. In JSON, a set of key-value pairs is represented as an object. It shall comply with the provisions defined in clause 4 of IETF RFC 8259'
]: any -> table<_links: record<appD: record, appPkgContent: record, self: record>, additionalArtifacts: any, appDId: string, appDVersion: string, appName: string, appProvider: string, appSoftwareVersion: string, checksum: record<algorithm: string, hash: string>, id: string, onboardingState: string, operationalState: string, softwareImages: any, usageState: string, userDefinedData: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/app_packages")
  let req_body = {"appPkgName": $app_pkg_name, "appPkgPath": $app_pkg_path, "appPkgVersion": $app_pkg_version, "appProvider": $app_provider, "checksum": $checksum, "userDefinedData": $user_defined_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an individual application package resources
#
# DELETE /app_packages/{appPkgId}
# operationId: app_packageDELETE
export def "app-packages delete" [
  app_pkg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_pkg_id | is-empty) { error make --unspanned { msg: "path parameter 'appPkgId' must be non-empty" } }
  let full_url = (build-url $base ({app_pkg_id: (encode-path-segment $app_pkg_id)} | format pattern "/app_packages/{app_pkg_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Queries the information related to individual application package resources
#
# GET /app_packages/{appPkgId}
# operationId: app_packageGET
export def "app-packages get" [
  app_pkg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<appD: record<href: string>, appPkgContent: record<href: string>, self: record<href: string>>, additionalArtifacts: any, appDId: string, appDVersion: string, appName: string, appProvider: string, appSoftwareVersion: string, checksum: record<algorithm: string, hash: string>, id: string, onboardingState: string, operationalState: string, softwareImages: any, usageState: string, userDefinedData: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_pkg_id | is-empty) { error make --unspanned { msg: "path parameter 'appPkgId' must be non-empty" } }
  let full_url = (build-url $base ({app_pkg_id: (encode-path-segment $app_pkg_id)} | format pattern "/app_packages/{app_pkg_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the operational state of an individual application package resource
#
# PATCH /app_packages/{appPkgId}
# operationId: app_packagePATCH
export def "app-packages update" [
  app_pkg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  operation_state: string@operation-state-completer
]: any -> record<operationState: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_pkg_id | is-empty) { error make --unspanned { msg: "path parameter 'appPkgId' must be non-empty" } }
  let full_url = (build-url $base ({app_pkg_id: (encode-path-segment $app_pkg_id)} | format pattern "/app_packages/{app_pkg_id}"))
  let req_body = {"operationState": $operation_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Reads the content of the AppD of on-boarded individual application package resources.
#
# GET /app_packages/{appPkgId}/appd
# operationId: appPkgIdGET
export def "app-packages-appd get-pkg" [
  app_pkg_id: string
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
  --filter: string # Attribute-based filtering parameters according to ETSI GS MEC 009
  --all-fields: string # Include all complex attributes in the response.
  --fields: string # Complex attributes of AppPkgInfo to be included into the response
  --exclude-fields: string # Complex attributes of AppPkgInfo to be excluded from the response.
  --exclude-default: string # Indicates to exclude the following complex attributes of AppPkgInfo from the response.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_pkg_id | is-empty) { error make --unspanned { msg: "path parameter 'appPkgId' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "all_fields" $all_fields "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "exclude_fields" $exclude_fields "scalar") (serialize-qp "exclude_default" $exclude_default "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_pkg_id: (encode-path-segment $app_pkg_id)} | format pattern "/app_packages/{app_pkg_id}/appd") $qp)
  let accept_val = ($accept | default "application/zip")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "all_fields": $all_fields, "fields": $fields, "exclude_fields": $exclude_fields, "exclude_default": $exclude_default} | compact), body: null}
}

# Fetch the onboarded application package content identified by appPkgId or appDId.
#
# GET /app_packages/{appPkgId}/package_content
# operationId: appPkgGET
export def "app-packages-package-content get-pkg" [
  app_pkg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_pkg_id | is-empty) { error make --unspanned { msg: "path parameter 'appPkgId' must be non-empty" } }
  let full_url = (build-url $base ({app_pkg_id: (encode-path-segment $app_pkg_id)} | format pattern "/app_packages/{app_pkg_id}/package_content"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Uploads the content of application package.
#
# PUT /app_packages/{appPkgId}/package_content
# operationId: appPkgPUT
export def "app-packages-package-content update-pkg" [
  app_pkg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_pkg_id | is-empty) { error make --unspanned { msg: "path parameter 'appPkgId' must be non-empty" } }
  let full_url = (build-url $base ({app_pkg_id: (encode-path-segment $app_pkg_id)} | format pattern "/app_packages/{app_pkg_id}/package_content"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/zip" $req_body {query: {}, body: $req_body}
}

# Reads the content of the AppD of on-boarded individual application package resources.
#
# GET /onboarded_app_packages/{appDId}/appd
# operationId: appDGET
export def "onboarded-app-packages-appd get-dget" [
  app_d_id: string
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
  --filter: string # Attribute-based filtering parameters according to ETSI GS MEC 009
  --all-fields: string # Include all complex attributes in the response.
  --fields: string # Complex attributes of AppPkgInfo to be included into the response
  --exclude-fields: string # Complex attributes of AppPkgInfo to be excluded from the response.
  --exclude-default: string # Indicates to exclude the following complex attributes of AppPkgInfo from the response.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_d_id | is-empty) { error make --unspanned { msg: "path parameter 'appDId' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "all_fields" $all_fields "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "exclude_fields" $exclude_fields "scalar") (serialize-qp "exclude_default" $exclude_default "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_d_id: (encode-path-segment $app_d_id)} | format pattern "/onboarded_app_packages/{app_d_id}/appd") $qp)
  let accept_val = ($accept | default "application/zip")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "all_fields": $all_fields, "fields": $fields, "exclude_fields": $exclude_fields, "exclude_default": $exclude_default} | compact), body: null}
}

# Fetch the onboarded application package content identified by appPkgId or appDId.
#
# GET /onboarded_app_packages/{appDId}/package_content
# operationId: appDIdGET
export def "onboarded-app-packages-package-content get-d" [
  app_d_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_d_id | is-empty) { error make --unspanned { msg: "path parameter 'appDId' must be non-empty" } }
  let full_url = (build-url $base ({app_d_id: (encode-path-segment $app_d_id)} | format pattern "/onboarded_app_packages/{app_d_id}/package_content"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Uploads the content of application package.
#
# PUT /onboarded_app_packages/{appDId}/package_content
# operationId: appDIdPUT
export def "onboarded-app-packages-package-content update-d" [
  app_d_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_d_id | is-empty) { error make --unspanned { msg: "path parameter 'appDId' must be non-empty" } }
  let full_url = (build-url $base ({app_d_id: (encode-path-segment $app_d_id)} | format pattern "/onboarded_app_packages/{app_d_id}/package_content"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/zip" $req_body {query: {}, body: $req_body}
}

# used to retrieve the information of subscriptions to individual application package resource in MEO
#
# GET /subscriptions
# operationId: subscriptionsGET
export def "subscriptions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<self: record<href: string>, subscriptions: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscriptions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Subscribe to notifications about on-boarding an application package
#
# POST /subscriptions
# operationId: subscriptionsPOST
export def "subscriptions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-pkg-filter: list<string>
  callback_uri: string # The URI of the endpoint for the notification to be sent to. (format: uri)
  subsctiption_type: string@subsctiption-type-completer # 'Subscribed notification type'
]: any -> record<_links: record<self: record<href: string>>, callbackUri: string, id: string, subscriptionType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscriptions")
  let req_body = {"appPkgFilter": $app_pkg_filter, "callbackUri": $callback_uri, "subsctiptionType": $subsctiption_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the individual subscription to notifications about application package changes in MEO.
#
# DELETE /subscriptions/{subscriptionId}
# operationId: individualSubscriptionDELETE
export def "subscriptions delete-individual" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Used to represent an individual subscription to notifications about application package changes.
#
# GET /subscriptions/{subscriptionId}
# operationId: individualSubscriptionGET
export def "subscriptions get-individual" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<self: record<href: string>>, callbackUri: string, id: string, subscriptionType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Registers a notification endpoint to notify application package operations
#
# POST /user_defined_notification
# operationId: app_pkg_notificationPOST
# --_links shape: {subscription: record}
# --timeStamp shape: {nanoSeconds: int, seconds: int}
export def "user-defined-notification create-app-pkg" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  links: record # Links to resources related to this resource. — shape: {subscription: record}
  app_d_id: string # Identifier of this MEC application descriptor. This attribute shall be globally unique.
  app_pkg_id: string # Identifier of the onboarded application package.
  id: string # ''
  notification_type: string@notification-type-completer # Discriminator for the different notification types
  operational_state: string@operational-state-completer
  subscription_id: string # Identifier of the subscription related to this notification.
  time_stamp: record # shape: {nanoSeconds: int, seconds: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_defined_notification")
  let req_body = {"_links": $links, "appDId": $app_d_id, "appPkgId": $app_pkg_id, "id": $id, "notificationType": $notification_type, "operationalState": $operational_state, "subscriptionId": $subscription_id, "timeStamp": $time_stamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
