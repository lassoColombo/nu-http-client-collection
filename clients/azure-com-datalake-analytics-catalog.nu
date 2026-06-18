# Auto-generated client for DataLakeAnalyticsCatalogManagementClient v2016-11-01
# Source: https://api.apis.guru/v2/specs/azure.com/datalake-analytics-catalog/2016-11-01/swagger.json
# Auth: --token flag or $env.DATALAKEANALYTICSCATALOGMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://azure.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DATALAKEANALYTICSCATALOGMANAGEMENTCLIENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://azure.local"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "catalog-usql-acl list" } } | get name | first)
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

# Retrieves the list of access control list (ACL) entries for the Data Lake Analytics catalog.
#
# GET /catalog/usql/acl
# operationId: Catalog_ListAcls
export def "catalog-usql-acl list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<aceType: string, permission: string, principalId: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/catalog/usql/acl" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the list of databases from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases
# operationId: Catalog_ListDatabases
export def "catalog-usql-databases list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<databaseName: string, computeAccountName: string, version: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/catalog/usql/databases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the specified database from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}
# operationId: Catalog_GetDatabase
export def "catalog-usql-databases get" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<databaseName: string, computeAccountName: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name)} | format pattern "/catalog/usql/databases/{database_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the list of access control list (ACL) entries for the database from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/acl
# operationId: Catalog_ListAclsByDatabase
export def "catalog-usql-databases-acl list" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<aceType: string, permission: string, principalId: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name)} | format pattern "/catalog/usql/databases/{database_name}/acl") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the list of assemblies from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/assemblies
# operationId: Catalog_ListAssemblies
export def "catalog-usql-databases-assemblies list" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<assemblyClrName: string, clrName: string, databaseName: string, computeAccountName: string, version: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name)} | format pattern "/catalog/usql/databases/{database_name}/assemblies") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the specified assembly from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/assemblies/{assemblyName}
# operationId: Catalog_GetAssembly
export def "catalog-usql-databases-assemblies get-assembly" [
  database_name: string
  assembly_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<assemblyName: string, clrName: string, databaseName: string, dependencies: table<entityId: record>, files: table<contentPath: string, originalPath: string, type: string>, isUserDefined: bool, isVisible: bool, computeAccountName: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), assembly_name: (encode-path-segment $assembly_name)} | format pattern "/catalog/usql/databases/{database_name}/assemblies/{assembly_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the list of credentials from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/credentials
# operationId: Catalog_ListCredentials
export def "catalog-usql-databases-credentials list" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<credentialName: string, computeAccountName: string, version: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name)} | format pattern "/catalog/usql/databases/{database_name}/credentials") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the specified credential from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/credentials/{credentialName}
# operationId: Catalog_GetCredential
export def "catalog-usql-databases-credentials get" [
  database_name: string
  credential_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<credentialName: string, computeAccountName: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), credential_name: (encode-path-segment $credential_name)} | format pattern "/catalog/usql/databases/{database_name}/credentials/{credential_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Modifies the specified credential for use with external data sources in the specified database
#
# PATCH /catalog/usql/databases/{databaseName}/credentials/{credentialName}
# operationId: Catalog_UpdateCredential
export def "catalog-usql-databases-credentials update" [
  database_name: string
  credential_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --new-password: string # the new password for the credential and user with access to the data source.
  --password: string # the current password for the credential and user with access to the data source. This is required if the requester is not the account owner.
  --uri: string # the URI identifier for the data source this credential can connect to in the format :
  --user-id: string # the object identifier for the user associated with this credential with access to the data source.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), credential_name: (encode-path-segment $credential_name)} | format pattern "/catalog/usql/databases/{database_name}/credentials/{credential_name}") $qp)
  let req_body = {"newPassword": $new_password, "password": $password, "uri": $uri, "userId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the specified credential in the specified database
#
# POST /catalog/usql/databases/{databaseName}/credentials/{credentialName}
# operationId: Catalog_DeleteCredential
export def "catalog-usql-databases-credentials delete" [
  database_name: string
  credential_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cascade: oneof<nothing, bool> # Indicates if the delete should be a cascading delete (which deletes all resources dependent on the credential as well as the credential) or not. If false will fail if there are any resources relying on the credential. (default: false)
  --api-version: string # Client Api Version.
  --password: string # the current password for the credential and user with access to the data source. This is required if the requester is not the account owner.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cascade" $cascade "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), credential_name: (encode-path-segment $credential_name)} | format pattern "/catalog/usql/databases/{database_name}/credentials/{credential_name}") $qp)
  let req_body = {"password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates the specified credential for use with external data sources in the specified database.
#
# PUT /catalog/usql/databases/{databaseName}/credentials/{credentialName}
# operationId: Catalog_CreateCredential
export def "catalog-usql-databases-credentials create" [
  database_name: string
  credential_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  password: string # the password for the credential and user with access to the data source.
  uri: string # the URI identifier for the data source this credential can connect to in the format :
  user_id: string # the object identifier for the user associated with this credential with access to the data source.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), credential_name: (encode-path-segment $credential_name)} | format pattern "/catalog/usql/databases/{database_name}/credentials/{credential_name}") $qp)
  let req_body = {"password": $password, "uri": $uri, "userId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves the list of external data sources from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/externaldatasources
# operationId: Catalog_ListExternalDataSources
export def "catalog-usql-databases-externaldatasources list-external-data-sources" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<databaseName: string, externalDataSourceName: string, provider: string, providerString: string, pushdownTypes: list, computeAccountName: string, version: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name)} | format pattern "/catalog/usql/databases/{database_name}/externaldatasources") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the specified external data source from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/externaldatasources/{externalDataSourceName}
# operationId: Catalog_GetExternalDataSource
export def "catalog-usql-databases-externaldatasources get-external-data-source" [
  database_name: string
  external_data_source_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<databaseName: string, externalDataSourceName: string, provider: string, providerString: string, pushdownTypes: list<string>, computeAccountName: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), external_data_source_name: (encode-path-segment $external_data_source_name)} | format pattern "/catalog/usql/databases/{database_name}/externaldatasources/{external_data_source_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the list of schemas from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas
# operationId: Catalog_ListSchemas
export def "catalog-usql-databases-schemas list" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<databaseName: string, schemaName: string, computeAccountName: string, version: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the specified schema from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}
# operationId: Catalog_GetSchema
export def "catalog-usql-databases-schemas get" [
  database_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<databaseName: string, schemaName: string, computeAccountName: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the list of packages from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/packages
# operationId: Catalog_ListPackages
export def "catalog-usql-databases-schemas-packages list" [
  database_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<databaseName: string, definition: string, packageName: string, schemaName: string, computeAccountName: string, version: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/packages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the specified package from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/packages/{packageName}
# operationId: Catalog_GetPackage
export def "catalog-usql-databases-schemas-packages get" [
  database_name: string
  schema_name: string
  package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<databaseName: string, definition: string, packageName: string, schemaName: string, computeAccountName: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name), package_name: (encode-path-segment $package_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/packages/{package_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the list of procedures from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/procedures
# operationId: Catalog_ListProcedures
export def "catalog-usql-databases-schemas-procedures list" [
  database_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<databaseName: string, definition: string, procName: string, schemaName: string, computeAccountName: string, version: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/procedures") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the specified procedure from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/procedures/{procedureName}
# operationId: Catalog_GetProcedure
export def "catalog-usql-databases-schemas-procedures get" [
  database_name: string
  schema_name: string
  procedure_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<databaseName: string, definition: string, procName: string, schemaName: string, computeAccountName: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name), procedure_name: (encode-path-segment $procedure_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/procedures/{procedure_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the list of all table statistics within the specified schema from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/statistics
# operationId: Catalog_ListTableStatisticsByDatabaseAndSchema
export def "catalog-usql-databases-schemas-statistics list-table-by-and" [
  database_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<colNames: list, createTime: string, databaseName: string, filterDefinition: string, hasFilter: bool, isAutoCreated: bool, isUserCreated: bool, schemaName: string, statDataPath: string, statisticsName: string, tableName: string, updateTime: string, userStatName: string, computeAccountName: string, version: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/statistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the list of tables from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/tables
# operationId: Catalog_ListTables
export def "catalog-usql-databases-schemas-tables list" [
  database_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --basic: oneof<nothing, bool> # The basic switch indicates what level of information to return when listing tables. When basic is true, only database_name, schema_name, table_name and version are returned for each table, otherwise all table metadata is returned. By default, it is false. Optional. (default: false)
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<columnList: list, databaseName: string, distributionInfo: record, externalTable: record, indexList: list, partitionKeyList: list, schemaName: string, tableName: string, computeAccountName: string, version: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "basic" $basic "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/tables") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the specified table from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/tables/{tableName}
# operationId: Catalog_GetTable
export def "catalog-usql-databases-schemas-tables get" [
  database_name: string
  schema_name: string
  table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<columnList: table<name: string, type: string>, databaseName: string, distributionInfo: record<count: int, dynamicCount: int, keys: list<record>, type: int>, externalTable: record<dataSource: record<name: record, version: string>, tableName: string>, indexList: table<columns: list, distributionInfo: record, indexId: int, indexKeys: list, isColumnstore: bool, isUnique: bool, name: string, partitionFunction: string, partitionKeyList: list, streamNames: list>, partitionKeyList: list<string>, schemaName: string, tableName: string, computeAccountName: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name), table_name: (encode-path-segment $table_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/tables/{table_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the list of table partitions from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/tables/{tableName}/partitions
# operationId: Catalog_ListTablePartitions
export def "catalog-usql-databases-schemas-tables-partitions list" [
  database_name: string
  schema_name: string
  table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<createDate: string, databaseName: string, indexId: int, label: list, parentName: record, partitionName: string, schemaName: string, computeAccountName: string, version: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name), table_name: (encode-path-segment $table_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/tables/{table_name}/partitions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the specified table partition from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/tables/{tableName}/partitions/{partitionName}
# operationId: Catalog_GetTablePartition
export def "catalog-usql-databases-schemas-tables-partitions get" [
  database_name: string
  schema_name: string
  table_name: string
  partition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<createDate: string, databaseName: string, indexId: int, label: list<string>, parentName: record<firstPart: string, secondPart: string, server: string, thirdPart: string>, partitionName: string, schemaName: string, computeAccountName: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name), table_name: (encode-path-segment $table_name), partition_name: (encode-path-segment $partition_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/tables/{table_name}/partitions/{partition_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a preview set of rows in given partition.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/tables/{tableName}/partitions/{partitionName}/previewrows
# operationId: Catalog_PreviewTablePartition
export def "catalog-usql-databases-schemas-tables-partitions-previewrows get-preview" [
  database_name: string
  schema_name: string
  table_name: string
  partition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-rows: int # The maximum number of preview rows to be retrieved.Rows returned may be less than or equal to this number depending on row sizes and number of rows in the partition. (format: int64)
  --max-columns: int # The maximum number of columns to be retrieved. (format: int64)
  --api-version: string # Client Api Version.
]: nothing -> record<rows: list<list<string>>, schema: table<name: string, type: string>, totalColumnCount: int, totalRowCount: int, truncated: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxRows" $max_rows "scalar") (serialize-qp "maxColumns" $max_columns "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name), table_name: (encode-path-segment $table_name), partition_name: (encode-path-segment $partition_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/tables/{table_name}/partitions/{partition_name}/previewrows") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a preview set of rows in given table.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/tables/{tableName}/previewrows
# operationId: Catalog_PreviewTable
export def "catalog-usql-databases-schemas-tables-previewrows get-preview" [
  database_name: string
  schema_name: string
  table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-rows: int # The maximum number of preview rows to be retrieved. Rows returned may be less than or equal to this number depending on row sizes and number of rows in the table. (format: int64)
  --max-columns: int # The maximum number of columns to be retrieved. (format: int64)
  --api-version: string # Client Api Version.
]: nothing -> record<rows: list<list<string>>, schema: table<name: string, type: string>, totalColumnCount: int, totalRowCount: int, truncated: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxRows" $max_rows "scalar") (serialize-qp "maxColumns" $max_columns "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name), table_name: (encode-path-segment $table_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/tables/{table_name}/previewrows") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the list of table statistics from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/tables/{tableName}/statistics
# operationId: Catalog_ListTableStatistics
export def "catalog-usql-databases-schemas-tables-statistics list" [
  database_name: string
  schema_name: string
  table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<colNames: list, createTime: string, databaseName: string, filterDefinition: string, hasFilter: bool, isAutoCreated: bool, isUserCreated: bool, schemaName: string, statDataPath: string, statisticsName: string, tableName: string, updateTime: string, userStatName: string, computeAccountName: string, version: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name), table_name: (encode-path-segment $table_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/tables/{table_name}/statistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the specified table statistics from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/tables/{tableName}/statistics/{statisticsName}
# operationId: Catalog_GetTableStatistic
export def "catalog-usql-databases-schemas-tables-statistics get" [
  database_name: string
  schema_name: string
  table_name: string
  statistics_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<colNames: list<string>, createTime: string, databaseName: string, filterDefinition: string, hasFilter: bool, isAutoCreated: bool, isUserCreated: bool, schemaName: string, statDataPath: string, statisticsName: string, tableName: string, updateTime: string, userStatName: string, computeAccountName: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name), table_name: (encode-path-segment $table_name), statistics_name: (encode-path-segment $statistics_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/tables/{table_name}/statistics/{statistics_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the list of table fragments from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/tables/{tableName}/tablefragments
# operationId: Catalog_ListTableFragments
export def "catalog-usql-databases-schemas-tables-tablefragments list-fragments" [
  database_name: string
  schema_name: string
  table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<createDate: string, fragmentId: string, indexId: int, parentId: string, rowCount: int, size: int, streamPath: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name), table_name: (encode-path-segment $table_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/tables/{table_name}/tablefragments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the list of table types from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/tabletypes
# operationId: Catalog_ListTableTypes
export def "catalog-usql-databases-schemas-tabletypes list-table-types" [
  database_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<columns: list, cSharpName: string, databaseName: string, fullCSharpName: string, isAssemblyType: bool, isComplexType: bool, isNullable: bool, isTableType: bool, isUserDefined: bool, principalId: int, schemaId: int, schemaName: string, systemTypeId: int, typeFamily: string, typeName: string, userTypeId: int>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/tabletypes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the specified table type from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/tabletypes/{tableTypeName}
# operationId: Catalog_GetTableType
export def "catalog-usql-databases-schemas-tabletypes get-table-type" [
  database_name: string
  schema_name: string
  table_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<columns: table<name: string, type: string>, cSharpName: string, databaseName: string, fullCSharpName: string, isAssemblyType: bool, isComplexType: bool, isNullable: bool, isTableType: bool, isUserDefined: bool, principalId: int, schemaId: int, schemaName: string, systemTypeId: int, typeFamily: string, typeName: string, userTypeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name), table_type_name: (encode-path-segment $table_type_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/tabletypes/{table_type_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the list of table valued functions from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/tablevaluedfunctions
# operationId: Catalog_ListTableValuedFunctions
export def "catalog-usql-databases-schemas-tablevaluedfunctions list-table-valued-functions" [
  database_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<databaseName: string, definition: string, schemaName: string, tvfName: string, computeAccountName: string, version: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/tablevaluedfunctions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the specified table valued function from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/tablevaluedfunctions/{tableValuedFunctionName}
# operationId: Catalog_GetTableValuedFunction
export def "catalog-usql-databases-schemas-tablevaluedfunctions get-table-valued-function" [
  database_name: string
  schema_name: string
  table_valued_function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<databaseName: string, definition: string, schemaName: string, tvfName: string, computeAccountName: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name), table_valued_function_name: (encode-path-segment $table_valued_function_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/tablevaluedfunctions/{table_valued_function_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the list of types within the specified database and schema from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/types
# operationId: Catalog_ListTypes
export def "catalog-usql-databases-schemas-types list" [
  database_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<cSharpName: string, databaseName: string, fullCSharpName: string, isAssemblyType: bool, isComplexType: bool, isNullable: bool, isTableType: bool, isUserDefined: bool, principalId: int, schemaId: int, schemaName: string, systemTypeId: int, typeFamily: string, typeName: string, userTypeId: int, computeAccountName: string, version: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/types") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the list of views from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/views
# operationId: Catalog_ListViews
export def "catalog-usql-databases-schemas-views list" [
  database_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<databaseName: string, definition: string, schemaName: string, viewName: string, computeAccountName: string, version: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/views") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the specified view from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/schemas/{schemaName}/views/{viewName}
# operationId: Catalog_GetView
export def "catalog-usql-databases-schemas-views get" [
  database_name: string
  schema_name: string
  view_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<databaseName: string, definition: string, schemaName: string, viewName: string, computeAccountName: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), schema_name: (encode-path-segment $schema_name), view_name: (encode-path-segment $view_name)} | format pattern "/catalog/usql/databases/{database_name}/schemas/{schema_name}/views/{view_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes all secrets in the specified database. This is deprecated and will be removed in the next release. In the future, please only drop individual credentials using DeleteCredential
#
# DELETE /catalog/usql/databases/{databaseName}/secrets
# DEPRECATED
# operationId: Catalog_DeleteAllSecrets
@deprecated
export def "catalog-usql-databases-secrets delete-list" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name)} | format pattern "/catalog/usql/databases/{database_name}/secrets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes the specified secret in the specified database. This is deprecated and will be removed in the next release. Please use DeleteCredential instead.
#
# DELETE /catalog/usql/databases/{databaseName}/secrets/{secretName}
# DEPRECATED
# operationId: Catalog_DeleteSecret
@deprecated
export def "catalog-usql-databases-secrets delete" [
  database_name: string
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), secret_name: (encode-path-segment $secret_name)} | format pattern "/catalog/usql/databases/{database_name}/secrets/{secret_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the specified secret in the specified database. This is deprecated and will be removed in the next release. Please use GetCredential instead.
#
# GET /catalog/usql/databases/{databaseName}/secrets/{secretName}
# DEPRECATED
# operationId: Catalog_GetSecret
@deprecated
export def "catalog-usql-databases-secrets get" [
  database_name: string
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<creationTime: string, databaseName: string, password: string, secretName: string, uri: string, computeAccountName: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), secret_name: (encode-path-segment $secret_name)} | format pattern "/catalog/usql/databases/{database_name}/secrets/{secret_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Modifies the specified secret for use with external data sources in the specified database. This is deprecated and will be removed in the next release. Please use UpdateCredential instead.
#
# PATCH /catalog/usql/databases/{databaseName}/secrets/{secretName}
# DEPRECATED
# operationId: Catalog_UpdateSecret
@deprecated
export def "catalog-usql-databases-secrets update" [
  database_name: string
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  password: string # the password for the secret to pass in
  --uri: string # the URI identifier for the secret in the format :
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), secret_name: (encode-path-segment $secret_name)} | format pattern "/catalog/usql/databases/{database_name}/secrets/{secret_name}") $qp)
  let req_body = {"password": $password, "uri": $uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates the specified secret for use with external data sources in the specified database. This is deprecated and will be removed in the next release. Please use CreateCredential instead.
#
# PUT /catalog/usql/databases/{databaseName}/secrets/{secretName}
# DEPRECATED
# operationId: Catalog_CreateSecret
@deprecated
export def "catalog-usql-databases-secrets create" [
  database_name: string
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  password: string # the password for the secret to pass in
  --uri: string # the URI identifier for the secret in the format :
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), secret_name: (encode-path-segment $secret_name)} | format pattern "/catalog/usql/databases/{database_name}/secrets/{secret_name}") $qp)
  let req_body = {"password": $password, "uri": $uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves the list of all statistics in a database from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/statistics
# operationId: Catalog_ListTableStatisticsByDatabase
export def "catalog-usql-databases-statistics list-table" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<colNames: list, createTime: string, databaseName: string, filterDefinition: string, hasFilter: bool, isAutoCreated: bool, isUserCreated: bool, schemaName: string, statDataPath: string, statisticsName: string, tableName: string, updateTime: string, userStatName: string, computeAccountName: string, version: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name)} | format pattern "/catalog/usql/databases/{database_name}/statistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the list of all tables in a database from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/tables
# operationId: Catalog_ListTablesByDatabase
export def "catalog-usql-databases-tables list" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --basic: oneof<nothing, bool> # The basic switch indicates what level of information to return when listing tables. When basic is true, only database_name, schema_name, table_name and version are returned for each table, otherwise all table metadata is returned. By default, it is false (default: false)
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<columnList: list, databaseName: string, distributionInfo: record, externalTable: record, indexList: list, partitionKeyList: list, schemaName: string, tableName: string, computeAccountName: string, version: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "basic" $basic "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name)} | format pattern "/catalog/usql/databases/{database_name}/tables") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the list of all table valued functions in a database from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/tablevaluedfunctions
# operationId: Catalog_ListTableValuedFunctionsByDatabase
export def "catalog-usql-databases-tablevaluedfunctions list-table-valued-functions" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<databaseName: string, definition: string, schemaName: string, tvfName: string, computeAccountName: string, version: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name)} | format pattern "/catalog/usql/databases/{database_name}/tablevaluedfunctions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the list of all views in a database from the Data Lake Analytics catalog.
#
# GET /catalog/usql/databases/{databaseName}/views
# operationId: Catalog_ListViewsByDatabase
export def "catalog-usql-databases-views list" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<databaseName: string, definition: string, schemaName: string, viewName: string, computeAccountName: string, version: string>, nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name)} | format pattern "/catalog/usql/databases/{database_name}/views") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
