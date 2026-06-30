# Auto-generated client for IntuneResourceManagementClient v2015-01-14-privatepreview
# Source: https://api.apis.guru/v2/specs/azure.com/intune/2015-01-14-privatepreview/swagger.json
# Auth: --token flag or $env.INTUNERESOURCEMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o INTUNERESOURCEMANAGEMENTCLIENT_TOKEN | default "" }
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-intune-locations get" } } | get name | first)
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

# Returns location for user tenant.
#
# GET /providers/Microsoft.Intune/locations
# operationId: GetLocations
export def "providers-microsoft-intune-locations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
]: nothing -> record<nextlink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Intune/locations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns location for given tenant.
#
# GET /providers/Microsoft.Intune/locations/hostName
# operationId: GetLocationByHostName
export def "providers-microsoft-intune-locations-host-name get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
]: nothing -> record<properties: record<hostName: string>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Intune/locations/hostName" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get apps for an AndroidMAMPolicy.
#
# GET /providers/Microsoft.Intune/locations/{hostName}/AndroidPolicies/{policyName}/apps
# operationId: Android_GetAppForMAMPolicy
export def "providers-microsoft-intune-locations-android-policies-apps get-for-mam-policy" [
  host_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --filter: string # The filter to apply on the operation.
  --top: int # format: int32
  --select: string # select specific fields in entity.
]: nothing -> record<nextlink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/AndroidPolicies/{policy_name}/apps") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter, "$top": $top, "$select": $select} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns Intune Android policies.
#
# GET /providers/Microsoft.Intune/locations/{hostName}/androidPolicies
# operationId: Android_GetMAMPolicies
export def "providers-microsoft-intune-locations-android-policies get-mam" [
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --filter: string # The filter to apply on the operation.
  --top: int # format: int32
  --select: string # select specific fields in entity.
]: nothing -> record<nextlink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/androidPolicies") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter, "$top": $top, "$select": $select} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete Android Policy
#
# DELETE /providers/Microsoft.Intune/locations/{hostName}/androidPolicies/{policyName}
# operationId: Android_DeleteMAMPolicy
export def "providers-microsoft-intune-locations-android-policies delete-mam-policy" [
  host_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/androidPolicies/{policy_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Returns AndroidMAMPolicy with given name.
#
# GET /providers/Microsoft.Intune/locations/{hostName}/androidPolicies/{policyName}
# operationId: Android_GetMAMPolicyByName
export def "providers-microsoft-intune-locations-android-policies get-mam-policy-by-name" [
  host_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --select: string # select specific fields in entity.
]: nothing -> record<properties: record<fileEncryption: string, screenCapture: string, accessRecheckOfflineTimeout: string, accessRecheckOnlineTimeout: string, appSharingFromLevel: string, appSharingToLevel: string, authentication: string, clipboardSharingLevel: string, dataBackup: string, description: string, deviceCompliance: string, fileSharingSaveAs: string, friendlyName: string, groupStatus: string, lastModifiedTime: string, managedBrowser: string, numOfApps: int, offlineWipeTimeout: string, pin: string, pinNumRetry: int>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/androidPolicies/{policy_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$select": $select} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Patch AndroidMAMPolicy.
#
# PATCH /providers/Microsoft.Intune/locations/{hostName}/androidPolicies/{policyName}
# operationId: Android_PatchMAMPolicy
# --properties shape: {fileEncryption?: "required"|"notRequired", screenCapture?: "allow"|"block", accessRecheckOfflineTimeout?: string, accessRecheckOnlineTimeout?: string, appSharingFromLevel?: "none"|"policyManagedApps"|"allApps", appSharingToLevel?: "none"|"policyManagedApps"|"allApps", authentication?: "required"|"notRequired", clipboardSharingLevel?: "blocked"|"policyManagedApps"|"policyManagedAppsWithPasteIn"|"allApps", dataBackup?: "allow"|"block", description?: string, deviceCompliance?: "enable"|"disable", ... (6 more fields)}
export def "providers-microsoft-intune-locations-android-policies update-mam-policy" [
  host_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --properties: any # Intune MAM iOS Policy Properties. — shape: {fileEncryption?: "required"|"notRequired", screenCapture?: "allow"|"block", accessRecheckOfflineTimeout?: string, accessRecheckOnlineTimeout?: string, appSharingFromLevel?: "none"|"policyManagedApps"|"allApps", appSharingToLevel?: "none"|"policyManagedApps"|"allApps", authentication?: "required"|"notRequired", clipboardSharingLevel?: "blocked"|"policyManagedApps"|"policyManagedAppsWithPasteIn"|"allApps", dataBackup?: "allow"|"block", description?: string, deviceCompliance?: "enable"|"disable", ... (6 more fields)}
  --location: string # Resource Location
  --tags: record # Resource Tags
]: any -> record<properties: record<fileEncryption: string, screenCapture: string, accessRecheckOfflineTimeout: string, accessRecheckOnlineTimeout: string, appSharingFromLevel: string, appSharingToLevel: string, authentication: string, clipboardSharingLevel: string, dataBackup: string, description: string, deviceCompliance: string, fileSharingSaveAs: string, friendlyName: string, groupStatus: string, lastModifiedTime: string, managedBrowser: string, numOfApps: int, offlineWipeTimeout: string, pin: string, pinNumRetry: int>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/androidPolicies/{policy_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates or updates AndroidMAMPolicy.
#
# PUT /providers/Microsoft.Intune/locations/{hostName}/androidPolicies/{policyName}
# operationId: Android_CreateOrUpdateMAMPolicy
# --properties shape: {fileEncryption?: "required"|"notRequired", screenCapture?: "allow"|"block", accessRecheckOfflineTimeout?: string, accessRecheckOnlineTimeout?: string, appSharingFromLevel?: "none"|"policyManagedApps"|"allApps", appSharingToLevel?: "none"|"policyManagedApps"|"allApps", authentication?: "required"|"notRequired", clipboardSharingLevel?: "blocked"|"policyManagedApps"|"policyManagedAppsWithPasteIn"|"allApps", dataBackup?: "allow"|"block", description?: string, deviceCompliance?: "enable"|"disable", ... (6 more fields)}
export def "providers-microsoft-intune-locations-android-policies create-or-update-mam-policy" [
  host_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --properties: any # Intune MAM iOS Policy Properties. — shape: {fileEncryption?: "required"|"notRequired", screenCapture?: "allow"|"block", accessRecheckOfflineTimeout?: string, accessRecheckOnlineTimeout?: string, appSharingFromLevel?: "none"|"policyManagedApps"|"allApps", appSharingToLevel?: "none"|"policyManagedApps"|"allApps", authentication?: "required"|"notRequired", clipboardSharingLevel?: "blocked"|"policyManagedApps"|"policyManagedAppsWithPasteIn"|"allApps", dataBackup?: "allow"|"block", description?: string, deviceCompliance?: "enable"|"disable", ... (6 more fields)}
  --location: string # Resource Location
  --tags: record # Resource Tags
]: any -> record<properties: record<fileEncryption: string, screenCapture: string, accessRecheckOfflineTimeout: string, accessRecheckOnlineTimeout: string, appSharingFromLevel: string, appSharingToLevel: string, authentication: string, clipboardSharingLevel: string, dataBackup: string, description: string, deviceCompliance: string, fileSharingSaveAs: string, friendlyName: string, groupStatus: string, lastModifiedTime: string, managedBrowser: string, numOfApps: int, offlineWipeTimeout: string, pin: string, pinNumRetry: int>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/androidPolicies/{policy_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete App for Android Policy
#
# DELETE /providers/Microsoft.Intune/locations/{hostName}/androidPolicies/{policyName}/apps/{appName}
# operationId: Android_DeleteAppForMAMPolicy
export def "providers-microsoft-intune-locations-android-policies-apps delete-for-mam-policy" [
  host_name: string
  policy_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name), app_name: (encode-path-segment $app_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/androidPolicies/{policy_name}/apps/{app_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Add app to an AndroidMAMPolicy.
#
# PUT /providers/Microsoft.Intune/locations/{hostName}/androidPolicies/{policyName}/apps/{appName}
# operationId: Android_AddAppForMAMPolicy
# --properties shape: {url: string}
export def "providers-microsoft-intune-locations-android-policies-apps create-for-mam-policy" [
  host_name: string
  policy_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --properties: any # Android Policy request body for Intune MAM. — shape: {url: string}
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name), app_name: (encode-path-segment $app_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/androidPolicies/{policy_name}/apps/{app_name}") $qp $auth.query)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# Returns groups for a given AndroidMAMPolicy.
#
# GET /providers/Microsoft.Intune/locations/{hostName}/androidPolicies/{policyName}/groups
# operationId: Android_GetGroupsForMAMPolicy
export def "providers-microsoft-intune-locations-android-policies-groups get-for-mam-policy" [
  host_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
]: nothing -> record<nextlink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/androidPolicies/{policy_name}/groups") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete Group for Android Policy
#
# DELETE /providers/Microsoft.Intune/locations/{hostName}/androidPolicies/{policyName}/groups/{groupId}
# operationId: Android_DeleteGroupForMAMPolicy
export def "providers-microsoft-intune-locations-android-policies-groups delete-for-mam-policy" [
  host_name: string
  policy_name: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name), group_id: (encode-path-segment $group_id)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/androidPolicies/{policy_name}/groups/{group_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Add group to an AndroidMAMPolicy.
#
# PUT /providers/Microsoft.Intune/locations/{hostName}/androidPolicies/{policyName}/groups/{groupId}
# operationId: Android_AddGroupForMAMPolicy
# --properties shape: {url: string}
export def "providers-microsoft-intune-locations-android-policies-groups create-for-mam-policy" [
  host_name: string
  policy_name: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --properties: any # Android Policy request body for Intune MAM. — shape: {url: string}
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name), group_id: (encode-path-segment $group_id)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/androidPolicies/{policy_name}/groups/{group_id}") $qp $auth.query)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# Returns Intune Manageable apps.
#
# GET /providers/Microsoft.Intune/locations/{hostName}/apps
# operationId: GetApps
export def "providers-microsoft-intune-locations-apps get" [
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --filter: string # The filter to apply on the operation.
  --top: int # format: int32
  --select: string # select specific fields in entity.
]: nothing -> record<nextlink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/apps") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter, "$top": $top, "$select": $select} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns Intune flagged user collection
#
# GET /providers/Microsoft.Intune/locations/{hostName}/flaggedUsers
# operationId: GetMAMFlaggedUsers
export def "providers-microsoft-intune-locations-flagged-users get-mam" [
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --filter: string # The filter to apply on the operation.
  --top: int # format: int32
  --select: string # select specific fields in entity.
]: nothing -> record<nextlink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/flaggedUsers") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter, "$top": $top, "$select": $select} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns Intune flagged user details
#
# GET /providers/Microsoft.Intune/locations/{hostName}/flaggedUsers/{userName}
# operationId: GetMAMFlaggedUserByName
export def "providers-microsoft-intune-locations-flagged-users get-mam-by-name" [
  host_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --select: string # select specific fields in entity.
]: nothing -> record<properties: record<errorCount: int, friendlyName: string>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), user_name: (encode-path-segment $user_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/flaggedUsers/{user_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$select": $select} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns Intune flagged enrolled app collection for the User
#
# GET /providers/Microsoft.Intune/locations/{hostName}/flaggedUsers/{userName}/flaggedEnrolledApps
# operationId: GetMAMUserFlaggedEnrolledApps
export def "providers-microsoft-intune-locations-flagged-users-flagged-enrolled-apps get-mam" [
  host_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --filter: string # The filter to apply on the operation.
  --top: int # format: int32
  --select: string # select specific fields in entity.
]: nothing -> record<nextlink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), user_name: (encode-path-segment $user_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/flaggedUsers/{user_name}/flaggedEnrolledApps") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter, "$top": $top, "$select": $select} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns Intune iOSPolicies.
#
# GET /providers/Microsoft.Intune/locations/{hostName}/iosPolicies
# operationId: Ios_GetMAMPolicies
export def "providers-microsoft-intune-locations-ios-policies get-mam" [
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --filter: string # The filter to apply on the operation.
  --top: int # format: int32
  --select: string # select specific fields in entity.
]: nothing -> record<nextlink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/iosPolicies") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter, "$top": $top, "$select": $select} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete Ios Policy
#
# DELETE /providers/Microsoft.Intune/locations/{hostName}/iosPolicies/{policyName}
# operationId: Ios_DeleteMAMPolicy
export def "providers-microsoft-intune-locations-ios-policies delete-mam-policy" [
  host_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/iosPolicies/{policy_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Returns Intune iOS policies.
#
# GET /providers/Microsoft.Intune/locations/{hostName}/iosPolicies/{policyName}
# operationId: Ios_GetMAMPolicyByName
export def "providers-microsoft-intune-locations-ios-policies get-mam-policy-by-name" [
  host_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --select: string # select specific fields in entity.
]: nothing -> record<properties: record<fileEncryptionLevel: string, touchId: string, accessRecheckOfflineTimeout: string, accessRecheckOnlineTimeout: string, appSharingFromLevel: string, appSharingToLevel: string, authentication: string, clipboardSharingLevel: string, dataBackup: string, description: string, deviceCompliance: string, fileSharingSaveAs: string, friendlyName: string, groupStatus: string, lastModifiedTime: string, managedBrowser: string, numOfApps: int, offlineWipeTimeout: string, pin: string, pinNumRetry: int>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/iosPolicies/{policy_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$select": $select} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# patch an iOSMAMPolicy.
#
# PATCH /providers/Microsoft.Intune/locations/{hostName}/iosPolicies/{policyName}
# operationId: Ios_PatchMAMPolicy
# --properties shape: {fileEncryptionLevel?: "deviceLocked"|"deviceLockedExceptFilesOpen"|"afterDeviceRestart"|"useDeviceSettings", touchId?: "enable"|"disable", accessRecheckOfflineTimeout?: string, accessRecheckOnlineTimeout?: string, appSharingFromLevel?: "none"|"policyManagedApps"|"allApps", appSharingToLevel?: "none"|"policyManagedApps"|"allApps", authentication?: "required"|"notRequired", clipboardSharingLevel?: "blocked"|"policyManagedApps"|"policyManagedAppsWithPasteIn"|"allApps", dataBackup?: "allow"|"block", ... (8 more fields)}
export def "providers-microsoft-intune-locations-ios-policies update-mam-policy" [
  host_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --properties: any # Intune MAM iOS Policy Properties. — shape: {fileEncryptionLevel?: "deviceLocked"|"deviceLockedExceptFilesOpen"|"afterDeviceRestart"|"useDeviceSettings", touchId?: "enable"|"disable", accessRecheckOfflineTimeout?: string, accessRecheckOnlineTimeout?: string, appSharingFromLevel?: "none"|"policyManagedApps"|"allApps", appSharingToLevel?: "none"|"policyManagedApps"|"allApps", authentication?: "required"|"notRequired", clipboardSharingLevel?: "blocked"|"policyManagedApps"|"policyManagedAppsWithPasteIn"|"allApps", dataBackup?: "allow"|"block", ... (8 more fields)}
  --location: string # Resource Location
  --tags: record # Resource Tags
]: any -> record<properties: record<fileEncryptionLevel: string, touchId: string, accessRecheckOfflineTimeout: string, accessRecheckOnlineTimeout: string, appSharingFromLevel: string, appSharingToLevel: string, authentication: string, clipboardSharingLevel: string, dataBackup: string, description: string, deviceCompliance: string, fileSharingSaveAs: string, friendlyName: string, groupStatus: string, lastModifiedTime: string, managedBrowser: string, numOfApps: int, offlineWipeTimeout: string, pin: string, pinNumRetry: int>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/iosPolicies/{policy_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates or updates iOSMAMPolicy.
#
# PUT /providers/Microsoft.Intune/locations/{hostName}/iosPolicies/{policyName}
# operationId: Ios_CreateOrUpdateMAMPolicy
# --properties shape: {fileEncryptionLevel?: "deviceLocked"|"deviceLockedExceptFilesOpen"|"afterDeviceRestart"|"useDeviceSettings", touchId?: "enable"|"disable", accessRecheckOfflineTimeout?: string, accessRecheckOnlineTimeout?: string, appSharingFromLevel?: "none"|"policyManagedApps"|"allApps", appSharingToLevel?: "none"|"policyManagedApps"|"allApps", authentication?: "required"|"notRequired", clipboardSharingLevel?: "blocked"|"policyManagedApps"|"policyManagedAppsWithPasteIn"|"allApps", dataBackup?: "allow"|"block", ... (8 more fields)}
export def "providers-microsoft-intune-locations-ios-policies create-or-update-mam-policy" [
  host_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --properties: any # Intune MAM iOS Policy Properties. — shape: {fileEncryptionLevel?: "deviceLocked"|"deviceLockedExceptFilesOpen"|"afterDeviceRestart"|"useDeviceSettings", touchId?: "enable"|"disable", accessRecheckOfflineTimeout?: string, accessRecheckOnlineTimeout?: string, appSharingFromLevel?: "none"|"policyManagedApps"|"allApps", appSharingToLevel?: "none"|"policyManagedApps"|"allApps", authentication?: "required"|"notRequired", clipboardSharingLevel?: "blocked"|"policyManagedApps"|"policyManagedAppsWithPasteIn"|"allApps", dataBackup?: "allow"|"block", ... (8 more fields)}
  --location: string # Resource Location
  --tags: record # Resource Tags
]: any -> record<properties: record<fileEncryptionLevel: string, touchId: string, accessRecheckOfflineTimeout: string, accessRecheckOnlineTimeout: string, appSharingFromLevel: string, appSharingToLevel: string, authentication: string, clipboardSharingLevel: string, dataBackup: string, description: string, deviceCompliance: string, fileSharingSaveAs: string, friendlyName: string, groupStatus: string, lastModifiedTime: string, managedBrowser: string, numOfApps: int, offlineWipeTimeout: string, pin: string, pinNumRetry: int>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/iosPolicies/{policy_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get apps for an iOSMAMPolicy.
#
# GET /providers/Microsoft.Intune/locations/{hostName}/iosPolicies/{policyName}/apps
# operationId: Ios_GetAppForMAMPolicy
export def "providers-microsoft-intune-locations-ios-policies-apps get-for-mam-policy" [
  host_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --filter: string # The filter to apply on the operation.
  --top: int # format: int32
  --select: string # select specific fields in entity.
]: nothing -> record<nextlink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/iosPolicies/{policy_name}/apps") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter, "$top": $top, "$select": $select} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete App for Ios Policy
#
# DELETE /providers/Microsoft.Intune/locations/{hostName}/iosPolicies/{policyName}/apps/{appName}
# operationId: Ios_DeleteAppForMAMPolicy
export def "providers-microsoft-intune-locations-ios-policies-apps delete-for-mam-policy" [
  host_name: string
  policy_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name), app_name: (encode-path-segment $app_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/iosPolicies/{policy_name}/apps/{app_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Add app to an iOSMAMPolicy.
#
# PUT /providers/Microsoft.Intune/locations/{hostName}/iosPolicies/{policyName}/apps/{appName}
# operationId: Ios_AddAppForMAMPolicy
# --properties shape: {url: string}
export def "providers-microsoft-intune-locations-ios-policies-apps create-for-mam-policy" [
  host_name: string
  policy_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --properties: any # Android Policy request body for Intune MAM. — shape: {url: string}
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  if ($app_name | is-empty) { error make --unspanned { msg: "path parameter 'appName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name), app_name: (encode-path-segment $app_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/iosPolicies/{policy_name}/apps/{app_name}") $qp $auth.query)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# Returns groups for a given iOSMAMPolicy.
#
# GET /providers/Microsoft.Intune/locations/{hostName}/iosPolicies/{policyName}/groups
# operationId: Ios_GetGroupsForMAMPolicy
export def "providers-microsoft-intune-locations-ios-policies-groups get-for-mam-policy" [
  host_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
]: nothing -> record<nextlink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/iosPolicies/{policy_name}/groups") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete Group for iOS Policy
#
# DELETE /providers/Microsoft.Intune/locations/{hostName}/iosPolicies/{policyName}/groups/{groupId}
# operationId: Ios_DeleteGroupForMAMPolicy
export def "providers-microsoft-intune-locations-ios-policies-groups delete-for-mam-policy" [
  host_name: string
  policy_name: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name), group_id: (encode-path-segment $group_id)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/iosPolicies/{policy_name}/groups/{group_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Add group to an iOSMAMPolicy.
#
# PUT /providers/Microsoft.Intune/locations/{hostName}/iosPolicies/{policyName}/groups/{groupId}
# operationId: Ios_AddGroupForMAMPolicy
# --properties shape: {url: string}
export def "providers-microsoft-intune-locations-ios-policies-groups create-for-mam-policy" [
  host_name: string
  policy_name: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --properties: any # Android Policy request body for Intune MAM. — shape: {url: string}
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), policy_name: (encode-path-segment $policy_name), group_id: (encode-path-segment $group_id)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/iosPolicies/{policy_name}/groups/{group_id}") $qp $auth.query)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# Returns operationResults.
#
# GET /providers/Microsoft.Intune/locations/{hostName}/operationResults
# operationId: GetOperationResults
export def "providers-microsoft-intune-locations-operation-results get" [
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --filter: string # The filter to apply on the operation.
  --top: int # format: int32
  --select: string # select specific fields in entity.
]: nothing -> record<nextlink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/operationResults") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter, "$top": $top, "$select": $select} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns Intune Tenant level statuses.
#
# GET /providers/Microsoft.Intune/locations/{hostName}/statuses/default
# operationId: GetMAMStatuses
export def "providers-microsoft-intune-locations-statuses-default get-mam" [
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
]: nothing -> record<properties: record<deployedPolicies: int, enrolledUsers: int, flaggedUsers: int, lastModifiedTime: string, policyAppliedUsers: int, status: string, wipeFailedApps: int, wipePendingApps: int, wipeSucceededApps: int>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/statuses/default") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get devices for a user.
#
# GET /providers/Microsoft.Intune/locations/{hostName}/users/{userName}/devices
# operationId: GetMAMUserDevices
export def "providers-microsoft-intune-locations-users-devices get-mam" [
  host_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --filter: string # The filter to apply on the operation.
  --top: int # format: int32
  --select: string # select specific fields in entity.
]: nothing -> record<nextlink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), user_name: (encode-path-segment $user_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/users/{user_name}/devices") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter, "$top": $top, "$select": $select} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a unique device for a user.
#
# GET /providers/Microsoft.Intune/locations/{hostName}/users/{userName}/devices/{deviceName}
# operationId: GetMAMUserDeviceByDeviceName
export def "providers-microsoft-intune-locations-users-devices get-mam-by-name" [
  host_name: string
  user_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
  --select: string # select specific fields in entity.
]: nothing -> record<properties: record<deviceType: string, friendlyName: string, platform: string, platformVersion: string, userId: string>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($device_name | is-empty) { error make --unspanned { msg: "path parameter 'deviceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), user_name: (encode-path-segment $user_name), device_name: (encode-path-segment $device_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/users/{user_name}/devices/{device_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$select": $select} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Wipe a device for a user.
#
# POST /providers/Microsoft.Intune/locations/{hostName}/users/{userName}/devices/{deviceName}/wipe
# operationId: WipeMAMUserDevice
export def "providers-microsoft-intune-locations-users-devices-wipe create-mam" [
  host_name: string
  user_name: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Service Api Version.
]: nothing -> record<properties: record<value: string>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_name | is-empty) { error make --unspanned { msg: "path parameter 'hostName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($device_name | is-empty) { error make --unspanned { msg: "path parameter 'deviceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({host_name: (encode-path-segment $host_name), user_name: (encode-path-segment $user_name), device_name: (encode-path-segment $device_name)} | format pattern "/providers/Microsoft.Intune/locations/{host_name}/users/{user_name}/devices/{device_name}/wipe") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}
