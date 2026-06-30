# Auto-generated client for ETSI GS MEC 010-2 - Part 2: Application lifecycle, rules and requirements management v2.1.1
# Source: https://api.apis.guru/v2/specs/etsi.local/MEC010-2_AppPkgMgmt/2.1.1/openapi.json
# Auth: --token flag or $env.ETSI_GS_MEC_010_2_PART_2_APPLICATION_LIFECYCLE_RULES_AND_REQUIREMENTS_MANAGEMENT_TOKEN

const BASE_URL = "http://etsi.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o ETSI_GS_MEC_010_2_PART_2_APPLICATION_LIFECYCLE_RULES_AND_REQUIREMENTS_MANAGEMENT_TOKEN | default "" }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
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
  let full_url = (build-url $base "/app_packages" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"filter": $filter, "all_fields": $all_fields, "fields": $fields, "exclude_fields": $exclude_fields, "exclude_default": $exclude_default} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/app_packages" $auth.query)
  let req_body = {"appPkgName": $app_pkg_name, "appPkgPath": $app_pkg_path, "appPkgVersion": $app_pkg_version, "appProvider": $app_provider, "checksum": $checksum, "userDefinedData": $user_defined_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
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
  let full_url = (build-url $base ({app_pkg_id: (encode-path-segment $app_pkg_id)} | format pattern "/app_packages/{app_pkg_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
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
  let full_url = (build-url $base ({app_pkg_id: (encode-path-segment $app_pkg_id)} | format pattern "/app_packages/{app_pkg_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({app_pkg_id: (encode-path-segment $app_pkg_id)} | format pattern "/app_packages/{app_pkg_id}") $auth.query)
  let req_body = {"operationState": $operation_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
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
]: nothing -> record<appDId: string, appDNSRule: table<dnsRuleId: string, domainName: string, ipAddress: string, ipAddressType: string, ttl: int>, appDVersion: string, appDescription: string, appExtCpd: table<inherited_attributes: record, virtualNetworkInterfaceRequirements: list>, appFeatureOptional: table<featureName: string, version: string>, appFeatureRequired: table<featureName: string, version: string>, appInfoName: string, appLatency: record<maxLatency: int>, appName: string, appProvider: string, appServiceOptional: table<requestedPermissions: list, serCategory: any, serName: string, serTransportDependencies: list, version: string>, appServiceProduced: table<serCategory: any, serName: string, transportsSupported: record, version: string>, appServiceRequired: table<requestedPermissions: list, serCategory: any, serName: string, serTransportDependencies: list, version: string>, appSoftVersion: string, appTrafficRule: table<action: string, dstInterface: list, filterType: string, priority: int, trafficFilter: list, trafficRuleId: string>, changeAppInstanceStateOpConfig: string, mecVersion: list<string>, swImageDescriptor: string, terminateAppInstanceOpConfig: string, transportDependencies: table<labels: list, serializers: list, transport: record>, virtualComputeDescriptor: string, virtualStorageDescriptor: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_pkg_id | is-empty) { error make --unspanned { msg: "path parameter 'appPkgId' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "all_fields" $all_fields "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "exclude_fields" $exclude_fields "scalar") (serialize-qp "exclude_default" $exclude_default "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_pkg_id: (encode-path-segment $app_pkg_id)} | format pattern "/app_packages/{app_pkg_id}/appd") $qp $auth.query)
  let accept_val = ($accept | default "application/zip")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"filter": $filter, "all_fields": $all_fields, "fields": $fields, "exclude_fields": $exclude_fields, "exclude_default": $exclude_default} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({app_pkg_id: (encode-path-segment $app_pkg_id)} | format pattern "/app_packages/{app_pkg_id}/package_content") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 206]
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
  let full_url = (build-url $base ({app_pkg_id: (encode-path-segment $app_pkg_id)} | format pattern "/app_packages/{app_pkg_id}/package_content") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/zip"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
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
]: nothing -> record<appDId: string, appDNSRule: table<dnsRuleId: string, domainName: string, ipAddress: string, ipAddressType: string, ttl: int>, appDVersion: string, appDescription: string, appExtCpd: table<inherited_attributes: record, virtualNetworkInterfaceRequirements: list>, appFeatureOptional: table<featureName: string, version: string>, appFeatureRequired: table<featureName: string, version: string>, appInfoName: string, appLatency: record<maxLatency: int>, appName: string, appProvider: string, appServiceOptional: table<requestedPermissions: list, serCategory: any, serName: string, serTransportDependencies: list, version: string>, appServiceProduced: table<serCategory: any, serName: string, transportsSupported: record, version: string>, appServiceRequired: table<requestedPermissions: list, serCategory: any, serName: string, serTransportDependencies: list, version: string>, appSoftVersion: string, appTrafficRule: table<action: string, dstInterface: list, filterType: string, priority: int, trafficFilter: list, trafficRuleId: string>, changeAppInstanceStateOpConfig: string, mecVersion: list<string>, swImageDescriptor: string, terminateAppInstanceOpConfig: string, transportDependencies: table<labels: list, serializers: list, transport: record>, virtualComputeDescriptor: string, virtualStorageDescriptor: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_d_id | is-empty) { error make --unspanned { msg: "path parameter 'appDId' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "all_fields" $all_fields "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "exclude_fields" $exclude_fields "scalar") (serialize-qp "exclude_default" $exclude_default "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_d_id: (encode-path-segment $app_d_id)} | format pattern "/onboarded_app_packages/{app_d_id}/appd") $qp $auth.query)
  let accept_val = ($accept | default "application/zip")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"filter": $filter, "all_fields": $all_fields, "fields": $fields, "exclude_fields": $exclude_fields, "exclude_default": $exclude_default} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({app_d_id: (encode-path-segment $app_d_id)} | format pattern "/onboarded_app_packages/{app_d_id}/package_content") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 206]
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
  let full_url = (build-url $base ({app_d_id: (encode-path-segment $app_d_id)} | format pattern "/onboarded_app_packages/{app_d_id}/package_content") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/zip"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
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
  let full_url = (build-url $base "/subscriptions" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/subscriptions" $auth.query)
  let req_body = {"appPkgFilter": $app_pkg_filter, "callbackUri": $callback_uri, "subsctiptionType": $subsctiption_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/user_defined_notification" $auth.query)
  let req_body = {"_links": $links, "appDId": $app_d_id, "appPkgId": $app_pkg_id, "id": $id, "notificationType": $notification_type, "operationalState": $operational_state, "subscriptionId": $subscription_id, "timeStamp": $time_stamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}
