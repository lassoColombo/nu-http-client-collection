# Auto-generated client for DataShareManagementClient v2019-11-01
# Source: https://api.apis.guru/v2/specs/azure.com/datashare-DataShare/2019-11-01/swagger.json
# Auth: --token flag or $env.DATASHAREMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DATASHAREMANAGEMENTCLIENT_TOKEN | default "" }
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def synchronization-mode-completer [] { ["FullSync" "Incremental"] }
def kind-completer [] { ["AdlsGen2File" "AdlsGen2FileSystem" "AdlsGen2Folder" "Blob" "BlobFolder" "Container" "KustoCluster" "KustoDatabase" "SqlDBTable" "SqlDWTable"] }
def kind-completer-1 [] { ["ScheduleBased"] }
def kind-completer-2 [] { ["AdlsGen1File" "AdlsGen1Folder" "AdlsGen2File" "AdlsGen2FileSystem" "AdlsGen2Folder" "Blob" "BlobFolder" "Container" "KustoCluster" "KustoDatabase" "SqlDBTable" "SqlDWTable"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-data-share-list-invitations list-consumer" } } | get name | first)
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

# List the invitations
#
# GET /providers/Microsoft.DataShare/ListInvitations
# operationId: ConsumerInvitations_ListInvitations
export def "providers-microsoft-data-share-list-invitations list-consumer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --skip-token: string # The continuation token
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.DataShare/ListInvitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$skipToken": $skip_token} | compact), body: null}
}

# Rejects the invitation identified by invitationId
#
# POST /providers/Microsoft.DataShare/locations/{location}/RejectInvitation
# operationId: ConsumerInvitations_RejectInvitation
# --properties shape: {invitationId: string}
export def "providers-microsoft-data-share-locations-reject-invitation reject-consumer" [
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  properties: record # Properties of consumer invitation — shape: {invitationId: string}
]: any -> record<properties: record<dataSetCount: int, description: string, invitationId: string, invitationStatus: string, location: string, providerEmail: string, providerName: string, providerTenantName: string, respondedAt: string, sentAt: string, shareName: string, termsOfUse: string, userEmail: string, userName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location: (encode-path-segment $location)} | format pattern "/providers/Microsoft.DataShare/locations/{location}/RejectInvitation") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the invitation identified by invitationId
#
# GET /providers/Microsoft.DataShare/locations/{location}/consumerInvitations/{invitationId}
# operationId: ConsumerInvitations_Get
export def "providers-microsoft-data-share-locations-consumer-invitations get" [
  location: string
  invitation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<properties: record<dataSetCount: int, description: string, invitationId: string, invitationStatus: string, location: string, providerEmail: string, providerName: string, providerTenantName: string, respondedAt: string, sentAt: string, shareName: string, termsOfUse: string, userEmail: string, userName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($invitation_id | is-empty) { error make --unspanned { msg: "path parameter 'invitationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location: (encode-path-segment $location), invitation_id: (encode-path-segment $invitation_id)} | format pattern "/providers/Microsoft.DataShare/locations/{location}/consumerInvitations/{invitation_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists the available operations
#
# GET /providers/Microsoft.DataShare/operations
# operationId: Operations_List
export def "providers-microsoft-data-share-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<nextLink: string, value: table<display: record, name: string, origin: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.DataShare/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# List Accounts in a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DataShare/accounts
# operationId: Accounts_ListBySubscription
export def "subscriptions-providers-microsoft-data-share-accounts list" [
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
  --api-version: string # The api version to use.
  --skip-token: string # Continuation token
]: nothing -> record<nextLink: string, value: table<identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.DataShare/accounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$skipToken": $skip_token} | compact), body: null}
}

# List Accounts in a resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts
# operationId: Accounts_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --skip-token: string # Continuation token
]: nothing -> record<nextLink: string, value: table<identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$skipToken": $skip_token} | compact), body: null}
}

# Delete an account
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}
# operationId: Accounts_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<endTime: string, error: record<code: string, details: list<any>, message: string, target: string>, startTime: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Get an account under a resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}
# operationId: Accounts_Get
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<identity: record<principalId: string, tenantId: string, type: string>, properties: record<createdAt: string, provisioningState: string, userEmail: string, userName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Patch a given account
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}
# operationId: Accounts_Update
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts update" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --tags: record # Tags on the azure resource.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string>, properties: record<createdAt: string, provisioningState: string, userEmail: string, userName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}") $qp)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Create an account in the given resource group
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}
# operationId: Accounts_Create
# --identity shape: {type?: "SystemAssigned"}
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  identity: record # Identity of resource — shape: {type?: "SystemAssigned"}
  --properties: record # Account property bag.
  --location: string # Location of the azure resource.
  --tags: record # Tags on the azure resource.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string>, properties: record<createdAt: string, provisioningState: string, userEmail: string, userName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}") $qp)
  let req_body = {"identity": $identity, "properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# List of available share subscriptions under an account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shareSubscriptions
# operationId: ShareSubscriptions_ListByAccount
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-share-subscriptions list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --skip-token: string # Continuation Token
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shareSubscriptions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$skipToken": $skip_token} | compact), body: null}
}

# Delete shareSubscription in an account.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shareSubscriptions/{shareSubscriptionName}
# operationId: ShareSubscriptions_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-share-subscriptions delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<endTime: string, error: record<code: string, details: list<any>, message: string, target: string>, startTime: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_subscription_name | is-empty) { error make --unspanned { msg: "path parameter 'shareSubscriptionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_subscription_name: (encode-path-segment $share_subscription_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shareSubscriptions/{share_subscription_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Get shareSubscription in an account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shareSubscriptions/{shareSubscriptionName}
# operationId: ShareSubscriptions_Get
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-share-subscriptions get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<properties: record<createdAt: string, invitationId: string, providerEmail: string, providerName: string, providerTenantName: string, provisioningState: string, shareDescription: string, shareKind: string, shareName: string, shareSubscriptionStatus: string, shareTerms: string, sourceShareLocation: string, userEmail: string, userName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_subscription_name | is-empty) { error make --unspanned { msg: "path parameter 'shareSubscriptionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_subscription_name: (encode-path-segment $share_subscription_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shareSubscriptions/{share_subscription_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Create shareSubscription in an account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shareSubscriptions/{shareSubscriptionName}
# operationId: ShareSubscriptions_Create
# --properties shape: {invitationId: string, sourceShareLocation: string}
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-share-subscriptions create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  properties: record # Share subscription property bag. — shape: {invitationId: string, sourceShareLocation: string}
]: any -> record<properties: record<createdAt: string, invitationId: string, providerEmail: string, providerName: string, providerTenantName: string, provisioningState: string, shareDescription: string, shareKind: string, shareName: string, shareSubscriptionStatus: string, shareTerms: string, sourceShareLocation: string, userEmail: string, userName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_subscription_name | is-empty) { error make --unspanned { msg: "path parameter 'shareSubscriptionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_subscription_name: (encode-path-segment $share_subscription_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shareSubscriptions/{share_subscription_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Get source dataSets of a shareSubscription.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shareSubscriptions/{shareSubscriptionName}/ConsumerSourceDataSets
# operationId: ConsumerSourceDataSets_ListByShareSubscription
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-share-subscriptions-consumer-source-data-sets list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --skip-token: string # Continuation token
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_subscription_name | is-empty) { error make --unspanned { msg: "path parameter 'shareSubscriptionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_subscription_name: (encode-path-segment $share_subscription_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shareSubscriptions/{share_subscription_name}/ConsumerSourceDataSets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$skipToken": $skip_token} | compact), body: null}
}

# Initiate an asynchronous data share job
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shareSubscriptions/{shareSubscriptionName}/Synchronize
# operationId: ShareSubscriptions_Synchronize
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-share-subscriptions-synchronize create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --synchronization-mode: string@synchronization-mode-completer # Mode of synchronization used in triggers and snapshot sync. Incremental by default
]: any -> record<durationMs: int, endTime: string, message: string, startTime: string, status: string, synchronizationId: string, synchronizationMode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_subscription_name | is-empty) { error make --unspanned { msg: "path parameter 'shareSubscriptionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_subscription_name: (encode-path-segment $share_subscription_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shareSubscriptions/{share_subscription_name}/Synchronize") $qp)
  let req_body = {"synchronizationMode": $synchronization_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Request cancellation of a data share snapshot
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shareSubscriptions/{shareSubscriptionName}/cancelSynchronization
# operationId: ShareSubscriptions_CancelSynchronization
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-share-subscriptions-cancel-synchronization cancel" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  synchronization_id: string # Synchronization id
]: any -> record<durationMs: int, endTime: string, message: string, startTime: string, status: string, synchronizationId: string, synchronizationMode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_subscription_name | is-empty) { error make --unspanned { msg: "path parameter 'shareSubscriptionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_subscription_name: (encode-path-segment $share_subscription_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shareSubscriptions/{share_subscription_name}/cancelSynchronization") $qp)
  let req_body = {"synchronizationId": $synchronization_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# List DataSetMappings in a share subscription.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shareSubscriptions/{shareSubscriptionName}/dataSetMappings
# operationId: DataSetMappings_ListByShareSubscription
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-share-subscriptions-data-set-mappings list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --skip-token: string # Continuation token
]: nothing -> record<nextLink: string, value: table<kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_subscription_name | is-empty) { error make --unspanned { msg: "path parameter 'shareSubscriptionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_subscription_name: (encode-path-segment $share_subscription_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shareSubscriptions/{share_subscription_name}/dataSetMappings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$skipToken": $skip_token} | compact), body: null}
}

# Delete DataSetMapping in a shareSubscription.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shareSubscriptions/{shareSubscriptionName}/dataSetMappings/{dataSetMappingName}
# operationId: DataSetMappings_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-share-subscriptions-data-set-mappings delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_subscription_name: string
  data_set_mapping_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_subscription_name | is-empty) { error make --unspanned { msg: "path parameter 'shareSubscriptionName' must be non-empty" } }
  if ($data_set_mapping_name | is-empty) { error make --unspanned { msg: "path parameter 'dataSetMappingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_subscription_name: (encode-path-segment $share_subscription_name), data_set_mapping_name: (encode-path-segment $data_set_mapping_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shareSubscriptions/{share_subscription_name}/dataSetMappings/{data_set_mapping_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Get DataSetMapping in a shareSubscription.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shareSubscriptions/{shareSubscriptionName}/dataSetMappings/{dataSetMappingName}
# operationId: DataSetMappings_Get
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-share-subscriptions-data-set-mappings get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_subscription_name: string
  data_set_mapping_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_subscription_name | is-empty) { error make --unspanned { msg: "path parameter 'shareSubscriptionName' must be non-empty" } }
  if ($data_set_mapping_name | is-empty) { error make --unspanned { msg: "path parameter 'dataSetMappingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_subscription_name: (encode-path-segment $share_subscription_name), data_set_mapping_name: (encode-path-segment $data_set_mapping_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shareSubscriptions/{share_subscription_name}/dataSetMappings/{data_set_mapping_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Maps a source data set in the source share to a sink data set in the share subscription. Enables copying the data set from source to destination.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shareSubscriptions/{shareSubscriptionName}/dataSetMappings/{dataSetMappingName}
# Discriminator (request): kind
# operationId: DataSetMappings_Create
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-share-subscriptions-data-set-mappings create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_subscription_name: string
  data_set_mapping_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  kind: string@kind-completer # Kind of data set mapping.
]: any -> record<kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_subscription_name | is-empty) { error make --unspanned { msg: "path parameter 'shareSubscriptionName' must be non-empty" } }
  if ($data_set_mapping_name | is-empty) { error make --unspanned { msg: "path parameter 'dataSetMappingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_subscription_name: (encode-path-segment $share_subscription_name), data_set_mapping_name: (encode-path-segment $data_set_mapping_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shareSubscriptions/{share_subscription_name}/dataSetMappings/{data_set_mapping_name}") $qp)
  let req_body = {"kind": $kind} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Get source share synchronization settings for a shareSubscription.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shareSubscriptions/{shareSubscriptionName}/listSourceShareSynchronizationSettings
# operationId: ShareSubscriptions_ListSourceShareSynchronizationSettings
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-share-subscriptions-list-source-share-synchronization-settings list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --skip-token: string # Continuation token
]: nothing -> record<nextLink: string, value: table<kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_subscription_name | is-empty) { error make --unspanned { msg: "path parameter 'shareSubscriptionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_subscription_name: (encode-path-segment $share_subscription_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shareSubscriptions/{share_subscription_name}/listSourceShareSynchronizationSettings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$skipToken": $skip_token} | compact), body: null}
}

# List data set level details for a share subscription synchronization
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shareSubscriptions/{shareSubscriptionName}/listSynchronizationDetails
# operationId: ShareSubscriptions_ListSynchronizationDetails
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-share-subscriptions-list-synchronization-details list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --skip-token: string # Continuation token
  synchronization_id: string # Synchronization id
]: any -> record<nextLink: string, value: table<dataSetId: string, dataSetType: string, durationMs: int, endTime: string, filesRead: int, filesWritten: int, message: string, name: string, rowsCopied: int, rowsRead: int, sizeRead: int, sizeWritten: int, startTime: string, status: string, vCore: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_subscription_name | is-empty) { error make --unspanned { msg: "path parameter 'shareSubscriptionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_subscription_name: (encode-path-segment $share_subscription_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shareSubscriptions/{share_subscription_name}/listSynchronizationDetails") $qp)
  let req_body = {"synchronizationId": $synchronization_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "$skipToken": $skip_token} | compact), body: $req_body}
}

# List Synchronizations in a share subscription.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shareSubscriptions/{shareSubscriptionName}/listSynchronizations
# operationId: ShareSubscriptions_ListSynchronizations
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-share-subscriptions-list-synchronizations list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --skip-token: string # Continuation token
]: nothing -> record<nextLink: string, value: table<durationMs: int, endTime: string, message: string, startTime: string, status: string, synchronizationId: string, synchronizationMode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_subscription_name | is-empty) { error make --unspanned { msg: "path parameter 'shareSubscriptionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_subscription_name: (encode-path-segment $share_subscription_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shareSubscriptions/{share_subscription_name}/listSynchronizations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$skipToken": $skip_token} | compact), body: null}
}

# List Triggers in a share subscription.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shareSubscriptions/{shareSubscriptionName}/triggers
# operationId: Triggers_ListByShareSubscription
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-share-subscriptions-triggers list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_subscription_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --skip-token: string # Continuation token
]: nothing -> record<nextLink: string, value: table<kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_subscription_name | is-empty) { error make --unspanned { msg: "path parameter 'shareSubscriptionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_subscription_name: (encode-path-segment $share_subscription_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shareSubscriptions/{share_subscription_name}/triggers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$skipToken": $skip_token} | compact), body: null}
}

# Delete Trigger in a shareSubscription.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shareSubscriptions/{shareSubscriptionName}/triggers/{triggerName}
# operationId: Triggers_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-share-subscriptions-triggers delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_subscription_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<endTime: string, error: record<code: string, details: list<any>, message: string, target: string>, startTime: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_subscription_name | is-empty) { error make --unspanned { msg: "path parameter 'shareSubscriptionName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_subscription_name: (encode-path-segment $share_subscription_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shareSubscriptions/{share_subscription_name}/triggers/{trigger_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Get Trigger in a shareSubscription.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shareSubscriptions/{shareSubscriptionName}/triggers/{triggerName}
# operationId: Triggers_Get
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-share-subscriptions-triggers get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_subscription_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_subscription_name | is-empty) { error make --unspanned { msg: "path parameter 'shareSubscriptionName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_subscription_name: (encode-path-segment $share_subscription_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shareSubscriptions/{share_subscription_name}/triggers/{trigger_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# This method creates a trigger for a share subscription
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shareSubscriptions/{shareSubscriptionName}/triggers/{triggerName}
# Discriminator (request): kind
# operationId: Triggers_Create
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-share-subscriptions-triggers create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_subscription_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  kind: string@kind-completer-1 # Kind of synchronization
]: any -> record<kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_subscription_name | is-empty) { error make --unspanned { msg: "path parameter 'shareSubscriptionName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_subscription_name: (encode-path-segment $share_subscription_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shareSubscriptions/{share_subscription_name}/triggers/{trigger_name}") $qp)
  let req_body = {"kind": $kind} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# List of available shares under an account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares
# operationId: Shares_ListByAccount
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --skip-token: string # Continuation Token
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$skipToken": $skip_token} | compact), body: null}
}

# Deletes a share
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}
# operationId: Shares_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<endTime: string, error: record<code: string, details: list<any>, message: string, target: string>, startTime: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Get a specified share
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}
# operationId: Shares_Get
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<properties: record<createdAt: string, description: string, provisioningState: string, shareKind: string, terms: string, userEmail: string, userName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Create a share in the given account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}
# operationId: Shares_Create
# --properties shape: {description?: string, shareKind?: "CopyBased"|"InPlace", terms?: string}
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --properties: record # Share property bag. — shape: {description?: string, shareKind?: "CopyBased"|"InPlace", terms?: string}
]: any -> record<properties: record<createdAt: string, description: string, provisioningState: string, shareKind: string, terms: string, userEmail: string, userName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# List DataSets in a share.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}/dataSets
# operationId: DataSets_ListByShare
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares-data-sets list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --skip-token: string # continuation token
]: nothing -> record<nextLink: string, value: table<kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}/dataSets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$skipToken": $skip_token} | compact), body: null}
}

# Delete DataSet in a share.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}/dataSets/{dataSetName}
# operationId: DataSets_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares-data-sets delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  data_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  if ($data_set_name | is-empty) { error make --unspanned { msg: "path parameter 'dataSetName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name), data_set_name: (encode-path-segment $data_set_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}/dataSets/{data_set_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Get DataSet in a share.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}/dataSets/{dataSetName}
# operationId: DataSets_Get
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares-data-sets get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  data_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  if ($data_set_name | is-empty) { error make --unspanned { msg: "path parameter 'dataSetName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name), data_set_name: (encode-path-segment $data_set_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}/dataSets/{data_set_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Adds a new data set to an existing share or updates it if existing.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}/dataSets/{dataSetName}
# Discriminator (request): kind
# operationId: DataSets_Create
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares-data-sets create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  data_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  kind: string@kind-completer-2 # Kind of data set.
]: any -> record<kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  if ($data_set_name | is-empty) { error make --unspanned { msg: "path parameter 'dataSetName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name), data_set_name: (encode-path-segment $data_set_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}/dataSets/{data_set_name}") $qp)
  let req_body = {"kind": $kind} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# List all Invitations in a share.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}/invitations
# operationId: Invitations_ListByShare
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares-invitations list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --skip-token: string # The continuation token
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}/invitations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$skipToken": $skip_token} | compact), body: null}
}

# Delete Invitation in a share.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}/invitations/{invitationName}
# operationId: Invitations_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares-invitations delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  invitation_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  if ($invitation_name | is-empty) { error make --unspanned { msg: "path parameter 'invitationName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name), invitation_name: (encode-path-segment $invitation_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}/invitations/{invitation_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Get Invitation in a share.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}/invitations/{invitationName}
# operationId: Invitations_Get
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares-invitations get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  invitation_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<properties: record<invitationId: string, invitationStatus: string, respondedAt: string, sentAt: string, targetActiveDirectoryId: string, targetEmail: string, targetObjectId: string, userEmail: string, userName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  if ($invitation_name | is-empty) { error make --unspanned { msg: "path parameter 'invitationName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name), invitation_name: (encode-path-segment $invitation_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}/invitations/{invitation_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Sends a new invitation to a recipient to access a share.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}/invitations/{invitationName}
# operationId: Invitations_Create
# --properties shape: {targetActiveDirectoryId?: string, targetEmail?: string, targetObjectId?: string}
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares-invitations create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  invitation_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --properties: record # Invitation property bag. — shape: {targetActiveDirectoryId?: string, targetEmail?: string, targetObjectId?: string}
]: any -> record<properties: record<invitationId: string, invitationStatus: string, respondedAt: string, sentAt: string, targetActiveDirectoryId: string, targetEmail: string, targetObjectId: string, userEmail: string, userName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  if ($invitation_name | is-empty) { error make --unspanned { msg: "path parameter 'invitationName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name), invitation_name: (encode-path-segment $invitation_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}/invitations/{invitation_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# List data set level details for a share synchronization
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}/listSynchronizationDetails
# operationId: Shares_ListSynchronizationDetails
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares-list-synchronization-details list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --skip-token: string # Continuation token
  --consumer-email: string # Email of the user who created the synchronization
  --consumer-name: string # Name of the user who created the synchronization
  --consumer-tenant-name: string # Tenant name of the consumer who created the synchronization
  --duration-ms: int # synchronization duration (format: int32)
  --end-time: string # End time of synchronization (format: date-time)
  --message: string # message of synchronization
  --start-time: string # start time of synchronization (format: date-time)
  --status: string # Raw Status
  --synchronization-id: string # Synchronization id
]: any -> record<nextLink: string, value: table<dataSetId: string, dataSetType: string, durationMs: int, endTime: string, filesRead: int, filesWritten: int, message: string, name: string, rowsCopied: int, rowsRead: int, sizeRead: int, sizeWritten: int, startTime: string, status: string, vCore: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}/listSynchronizationDetails") $qp)
  let req_body = {"consumerEmail": $consumer_email, "consumerName": $consumer_name, "consumerTenantName": $consumer_tenant_name, "durationMs": $duration_ms, "endTime": $end_time, "message": $message, "startTime": $start_time, "status": $status, "synchronizationId": $synchronization_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "$skipToken": $skip_token} | compact), body: $req_body}
}

# List Synchronizations in a share
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}/listSynchronizations
# operationId: Shares_ListSynchronizations
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares-list-synchronizations list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --skip-token: string # Continuation token
]: nothing -> record<nextLink: string, value: table<consumerEmail: string, consumerName: string, consumerTenantName: string, durationMs: int, endTime: string, message: string, startTime: string, status: string, synchronizationId: string, synchronizationMode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}/listSynchronizations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$skipToken": $skip_token} | compact), body: null}
}

# List of available share subscriptions to a provider share.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}/providerShareSubscriptions
# operationId: ProviderShareSubscriptions_ListByShare
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares-provider-share-subscriptions list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --skip-token: string # Continuation Token
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}/providerShareSubscriptions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$skipToken": $skip_token} | compact), body: null}
}

# Get share subscription in a provider share.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}/providerShareSubscriptions/{providerShareSubscriptionId}
# operationId: ProviderShareSubscriptions_GetByShare
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares-provider-share-subscriptions get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  provider_share_subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<properties: record<consumerEmail: string, consumerName: string, consumerTenantName: string, createdAt: string, providerEmail: string, providerName: string, shareSubscriptionObjectId: string, shareSubscriptionStatus: string, sharedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  if ($provider_share_subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'providerShareSubscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name), provider_share_subscription_id: (encode-path-segment $provider_share_subscription_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}/providerShareSubscriptions/{provider_share_subscription_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Reinstate share subscription in a provider share.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}/providerShareSubscriptions/{providerShareSubscriptionId}/reinstate
# operationId: ProviderShareSubscriptions_Reinstate
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares-provider-share-subscriptions-reinstate create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  provider_share_subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<properties: record<consumerEmail: string, consumerName: string, consumerTenantName: string, createdAt: string, providerEmail: string, providerName: string, shareSubscriptionObjectId: string, shareSubscriptionStatus: string, sharedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  if ($provider_share_subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'providerShareSubscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name), provider_share_subscription_id: (encode-path-segment $provider_share_subscription_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}/providerShareSubscriptions/{provider_share_subscription_id}/reinstate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Revoke share subscription in a provider share.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}/providerShareSubscriptions/{providerShareSubscriptionId}/revoke
# operationId: ProviderShareSubscriptions_Revoke
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares-provider-share-subscriptions-revoke delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  provider_share_subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<properties: record<consumerEmail: string, consumerName: string, consumerTenantName: string, createdAt: string, providerEmail: string, providerName: string, shareSubscriptionObjectId: string, shareSubscriptionStatus: string, sharedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  if ($provider_share_subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'providerShareSubscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name), provider_share_subscription_id: (encode-path-segment $provider_share_subscription_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}/providerShareSubscriptions/{provider_share_subscription_id}/revoke") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# List synchronizationSettings in a share.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}/synchronizationSettings
# operationId: SynchronizationSettings_ListByShare
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares-synchronization-settings list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  --skip-token: string # continuation token
]: nothing -> record<nextLink: string, value: table<kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}/synchronizationSettings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$skipToken": $skip_token} | compact), body: null}
}

# Delete synchronizationSetting in a share.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}/synchronizationSettings/{synchronizationSettingName}
# operationId: SynchronizationSettings_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares-synchronization-settings delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  synchronization_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<endTime: string, error: record<code: string, details: list<any>, message: string, target: string>, startTime: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  if ($synchronization_setting_name | is-empty) { error make --unspanned { msg: "path parameter 'synchronizationSettingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name), synchronization_setting_name: (encode-path-segment $synchronization_setting_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}/synchronizationSettings/{synchronization_setting_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Get synchronizationSetting in a share.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}/synchronizationSettings/{synchronizationSettingName}
# operationId: SynchronizationSettings_Get
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares-synchronization-settings get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  synchronization_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
]: nothing -> record<kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  if ($synchronization_setting_name | is-empty) { error make --unspanned { msg: "path parameter 'synchronizationSettingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name), synchronization_setting_name: (encode-path-segment $synchronization_setting_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}/synchronizationSettings/{synchronization_setting_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Adds a new synchronization setting to an existing share or updates it if existing.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataShare/accounts/{accountName}/shares/{shareName}/synchronizationSettings/{synchronizationSettingName}
# Discriminator (request): kind
# operationId: SynchronizationSettings_Create
export def "subscriptions-resource-groups-providers-microsoft-data-share-accounts-shares-synchronization-settings create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  share_name: string
  synchronization_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The api version to use.
  kind: string@kind-completer-1 # Kind of synchronization
]: any -> record<kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($share_name | is-empty) { error make --unspanned { msg: "path parameter 'shareName' must be non-empty" } }
  if ($synchronization_setting_name | is-empty) { error make --unspanned { msg: "path parameter 'synchronizationSettingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), share_name: (encode-path-segment $share_name), synchronization_setting_name: (encode-path-segment $synchronization_setting_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataShare/accounts/{account_name}/shares/{share_name}/synchronizationSettings/{synchronization_setting_name}") $qp)
  let req_body = {"kind": $kind} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}
