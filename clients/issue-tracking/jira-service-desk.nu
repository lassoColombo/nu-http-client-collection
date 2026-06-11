# Auto-generated client for Service Management Public REST API v1001.0.0-SNAPSHOT-fc7a4733e5b961216b9bf0a12338994ae0045171
# Source: https://developer.atlassian.com/cloud/jira/service-desk/swagger.v3.json
# Auth: --token flag or $env.SERVICE_MANAGEMENT_PUBLIC_REST_API_TOKEN

const BASE_URL = "https://your-domain.atlassian.net"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SERVICE_MANAGEMENT_PUBLIC_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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
def base-url-completer [] { ["https://your-domain.atlassian.net"] }
def auth-scheme-completer [] { ["bearer" "basic"] }

# Completers for enum parameters
def decision-completer [] { ["approve" "decline"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "rest-servicedeskapi-assets-workspace get" } } | get name | first)
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

# Get assets workspaces
#
# GET /rest/servicedeskapi/assets/workspace
# operationId: getAssetsWorkspaces
export def "rest-servicedeskapi-assets-workspace get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # The starting index of the returned workspace IDs. Base index: 0 See the [Pagination](#pagination) section for more details. (format: int32, default: 0)
  --limit: int # The maximum number of workspace IDs to return per page. Default: 50 See the [Pagination](#pagination) section for more details. (format: int32, default: 50)
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/servicedeskapi/assets/workspace" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create customer
#
# POST /rest/servicedeskapi/customer
# operationId: createCustomer
export def "rest-servicedeskapi-customer createCustomer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --strictConflictStatusCode: string@bool-completer # Optional boolean flag to return 409 Conflict status code for duplicate customer creation request
  --displayName: string # Customer's name for display in the UI.
  --email: string # Customer's email address.
  --fullName: string # Deprecated, please use 'displayName'.
]: any -> record<_links: record<avatarUrls: record, jiraRest: string, self: string>, accountId: string, active: bool, displayName: string, emailAddress: string, key: string, name: string, timeZone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "strictConflictStatusCode" $strictConflictStatusCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/servicedeskapi/customer" $qp)
  let body = {displayName: $displayName, email: $email, fullName: $fullName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke portal only access for user
#
# PUT /rest/servicedeskapi/customer/user/{accountId}/revoke-portal-only-access
# operationId: revokePortalOnlyAccessForUser
export def "rest-servicedeskapi-customer-user-revoke-portal-only-access revokePortalOnlyAccessForUser" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/customer/user/($accountId)/revoke-portal-only-access")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get info
#
# GET /rest/servicedeskapi/info
# operationId: getInfo
export def "rest-servicedeskapi-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<self: string>, buildChangeSet: string, buildDate: record<epochMillis: int, friendly: string, iso8601: string, jira: string>, isLicensedForUse: bool, platformVersion: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/servicedeskapi/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get insight workspaces
#
# GET /rest/servicedeskapi/insight/workspace
# operationId: getInsightWorkspaces
export def "rest-servicedeskapi-insight-workspace get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # format: int32, default: 0
  --limit: int # format: int32, default: 50
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/servicedeskapi/insight/workspace" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get articles
#
# GET /rest/servicedeskapi/knowledgebase/article
# operationId: getArticles
export def "rest-servicedeskapi-knowledgebase-article get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The string used to filter the articles (required).
  --highlight: string@bool-completer # If set to true matching query term in the title and excerpt will be highlighted using the `@@@hl@@@term@@@endhl@@@` syntax. Default: false. (default: false)
  --start: int # (Deprecated) The starting index of the returned objects. Base index: 0. (format: int32)
  --limit: int # The maximum number of items to return per page. Default: 50. (format: int32)
  --cursor: string # Pointer to a set of search results, returned as part of the next or prev URL from the previous search call.
  --prev: string@bool-completer # Should navigate to the previous page. Defaulted to false. Set to true as part of prev URL from the previous search call. (default: false)
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<content: record, excerpt: string, source: record, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "highlight" $highlight "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "prev" $prev "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/servicedeskapi/knowledgebase/article" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View knowledge base article
#
# GET /rest/servicedeskapi/knowledgebase/article/view/{pageId}
# operationId: viewArticle
export def "rest-servicedeskapi-knowledgebase-article-view viewArticle" [
  pageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/knowledgebase/article/view/($pageId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organizations
#
# GET /rest/servicedeskapi/organization
# operationId: getOrganizations
export def "rest-servicedeskapi-organization list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # The starting index of the returned objects. Base index: 0. See the [Pagination](#pagination) section for more details. (format: int32)
  --limit: int # The maximum number of organizations to return per page. Default: 50. See the [Pagination](#pagination) section for more details. (format: int32)
  --accountId: string # The account ID of the user, which uniquely identifies the user across all Atlassian products. For example, *5b10ac8d82e05b22cc7d4ef5*.
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<_links: record, created: record, id: string, name: string, scimManaged: bool, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "accountId" $accountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/servicedeskapi/organization" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create organization
#
# POST /rest/servicedeskapi/organization
# operationId: createOrganization
export def "rest-servicedeskapi-organization createOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the organization. Must contain 1-200 characters.
]: any -> record<_links: record<self: string>, created: record<epochMillis: int, friendly: string, iso8601: string, jira: string>, id: string, name: string, scimManaged: bool, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/servicedeskapi/organization")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete organization
#
# DELETE /rest/servicedeskapi/organization/{organizationId}
# operationId: deleteOrganization
export def "rest-servicedeskapi-organization delete" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/organization/($organizationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization
#
# GET /rest/servicedeskapi/organization/{organizationId}
# operationId: getOrganization
export def "rest-servicedeskapi-organization get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<self: string>, created: record<epochMillis: int, friendly: string, iso8601: string, jira: string>, id: string, name: string, scimManaged: bool, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/organization/($organizationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get properties keys
#
# GET /rest/servicedeskapi/organization/{organizationId}/property
# operationId: getPropertiesKeys
export def "rest-servicedeskapi-organization-property list" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<keys: table<key: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/organization/($organizationId)/property")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete property
#
# DELETE /rest/servicedeskapi/organization/{organizationId}/property/{propertyKey}
# operationId: deleteProperty
export def "rest-servicedeskapi-organization-property delete" [
  organizationId: string
  propertyKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/organization/($organizationId)/property/($propertyKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get property
#
# GET /rest/servicedeskapi/organization/{organizationId}/property/{propertyKey}
# operationId: getProperty
export def "rest-servicedeskapi-organization-property get" [
  organizationId: string
  propertyKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/organization/($organizationId)/property/($propertyKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set property
#
# PUT /rest/servicedeskapi/organization/{organizationId}/property/{propertyKey}
# operationId: setProperty
export def "rest-servicedeskapi-organization-property setProperty" [
  organizationId: string
  propertyKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/organization/($organizationId)/property/($propertyKey)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove users from organization
#
# DELETE /rest/servicedeskapi/organization/{organizationId}/user
# operationId: removeUsersFromOrganization
export def "rest-servicedeskapi-organization-user removeUsersFromOrganization" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountIds: list # List of customers, specific by account IDs, to add to or remove from the organization.
  --body-organizationId: int # The organizationId in which users need to be added (format: int32)
  --usernames: list # This property is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details. Use `accountIds` instead.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/organization/($organizationId)/user")
  let body = {accountIds: $accountIds, organizationId: $body_organizationId, usernames: $usernames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get users in organization
#
# GET /rest/servicedeskapi/organization/{organizationId}/user
# operationId: getUsersInOrganization
export def "rest-servicedeskapi-organization-user get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # The starting index of the returned objects. Base index: 0. See the [Pagination](#pagination) section for more details. (format: int32)
  --limit: int # The maximum number of users to return per page. Default: 50. See the [Pagination](#pagination) section for more details. (format: int32)
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<_links: record, accountId: string, active: bool, displayName: string, emailAddress: string, key: string, name: string, timeZone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/organization/($organizationId)/user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add users to organization
#
# POST /rest/servicedeskapi/organization/{organizationId}/user
# operationId: addUsersToOrganization
export def "rest-servicedeskapi-organization-user addUsersToOrganization" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountIds: list # List of customers, specific by account IDs, to add to or remove from the organization.
  --body-organizationId: int # The organizationId in which users need to be added (format: int32)
  --usernames: list # This property is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details. Use `accountIds` instead.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/organization/($organizationId)/user")
  let body = {accountIds: $accountIds, organizationId: $body_organizationId, usernames: $usernames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get customer requests
#
# GET /rest/servicedeskapi/request
# operationId: getCustomerRequests
export def "rest-servicedeskapi-request list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --searchTerm: string # Filters customer requests where the request summary matches the `searchTerm`. [Wildcards](https://confluence.atlassian.com/display/JIRACORECLOUD/Search+syntax+for+text+fields) can be used in the `searchTerm` parameter.
  --requestOwnership: list # Filters customer requests using the following values:   *  `OWNED_REQUESTS` returns customer requests where the user is the creator.  *  `PARTICIPATED_REQUESTS` returns customer requests where the user is a participant.  *  `ORGANIZATION` returns customer requests for an organization of which the user is a member when used in conjunction with `organizationId`.  *  `ALL_ORGANIZATIONS` returns customer requests that belong to all organizations of which the user is a member.  *  `APPROVER` returns customer requests where the user is an approver. Can be used in conjunction with `approvalStatus` to filter pending or complete approvals.  *  `ALL_REQUESTS` returns all customer requests. **Deprecated and will be removed, as the returned requests may change if more values are added in the future. Instead, explicitly list the desired filtering strategies.**  Multiple values of the query parameter are supported. For example, `requestOwnership=OWNED_REQUESTS&requestOwnership=PARTICIPATED_REQUESTS` will only return customer requests where the user is the creator or a participant. If not specified, filtering defaults to `OWNED_REQUESTS`, `PARTICIPATED_REQUESTS`, and `ALL_ORGANIZATIONS`.
  --requestStatus: string # Filters customer requests where the request is closed, open, or either of the two where:   *  `CLOSED_REQUESTS` returns customer requests that are closed.  *  `OPEN_REQUESTS` returns customer requests that are open.  *  `ALL_REQUESTS` returns all customer requests.
  --approvalStatus: string # Filters results to customer requests based on their approval status:   *  `MY_PENDING_APPROVAL` returns customer requests pending the user's approval.  *  `MY_HISTORY_APPROVAL` returns customer requests where the user was an approver.  **Note**: Valid only when used with requestOwnership=APPROVER.
  --organizationId: int # Filters customer requests that belong to a specific organization (note that the user must be a member of that organization). **Note**: Valid only when used with requestOwnership=ORGANIZATION. (format: int32)
  --serviceDeskId: int # Filters customer requests by service desk. (format: int32)
  --requestTypeId: int # Filters customer requests by request type. Note that the `serviceDeskId` must be specified for the service desk in which the request type belongs. (format: int32)
  --expand: list # A multi-value parameter indicating which properties of the customer request to expand, where:   *  `serviceDesk` returns additional details for each service desk.  *  `requestType` returns additional details for each request type.  *  `participant` returns the participant details, if any, for each customer request.  *  `sla` returns the SLA information on each customer request.  *  `status` returns the status transitions, in chronological order, for each customer request.  *  `attachment` returns the attachments for the customer request.  *  `action` returns the actions that the user can or cannot perform on this customer request.  *  `comment` returns the comments, if any, for each customer request.  *  `comment.attachment` returns the attachment details, if any, for each comment.  *  `comment.renderedBody` (Experimental) returns the rendered body in HTML format (in addition to the raw body) for each comment.
  --start: int # The starting index of the returned objects. Base index: 0. See the [Pagination](#pagination) section for more details. (format: int32)
  --limit: int # The maximum number of items to return per page. Default: 50. See the [Pagination](#pagination) section for more details. (format: int32)
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<_expands: list, _links: record, actions: record, attachments: record, comments: record, createdDate: record, currentStatus: record, issueId: string, issueKey: string, participants: record, reporter: record, requestFieldValues: list, requestType: record, requestTypeId: string, serviceDesk: record, serviceDeskId: string, sla: record, status: record, summary: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchTerm" $searchTerm "scalar") (serialize-qp "requestOwnership" $requestOwnership "multi") (serialize-qp "requestStatus" $requestStatus "scalar") (serialize-qp "approvalStatus" $approvalStatus "scalar") (serialize-qp "organizationId" $organizationId "scalar") (serialize-qp "serviceDeskId" $serviceDeskId "scalar") (serialize-qp "requestTypeId" $requestTypeId "scalar") (serialize-qp "expand" $expand "multi") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/servicedeskapi/request" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create customer request
#
# POST /rest/servicedeskapi/request
# operationId: createCustomerRequest
export def "rest-servicedeskapi-request createCustomerRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --channel: string # (Experimental) Shows extra information for the request channel.
  --form: any # Provides answers to the form associated with a request type that is attached to the request on creation. Jira fields should be omitted from `requestFieldValues` if they are linked to form answers. Form answers in ADF format should have `isAdfRequest` set to true. Form answers are not currently validated.
  --isAdfRequest: string@bool-completer # (Experimental) Whether to accept rich text fields in Atlassian Document Format (ADF).
  --raiseOnBehalfOf: string # The `accountId` of the customer that the request is being raised on behalf of.
  --requestFieldValues: record # JSON map of Jira field IDs and their values representing the content of the request.
  --requestParticipants: list # List of customers to participate in the request, as a list of `accountId` values.
  --requestTypeId: string # ID of the request type for the request.
  --serviceDeskId: string # ID of the service desk in which to create the request.
]: any -> record<_expands: list<string>, _links: record<agent: string, jiraRest: string, self: string, web: string>, actions: record<addAttachment: record<allowed: bool>, addComment: record<allowed: bool>, addParticipant: record<allowed: bool>, removeParticipant: record<allowed: bool>>, attachments: record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: list<record>>, comments: record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: list<record>>, createdDate: record<epochMillis: int, friendly: string, iso8601: string, jira: string>, currentStatus: record<status: string, statusCategory: string, statusDate: record<epochMillis: int, friendly: string, iso8601: string, jira: string>>, issueId: string, issueKey: string, participants: record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: list<record>>, reporter: record<_links: record<avatarUrls: record, jiraRest: string, self: string>, accountId: string, active: bool, displayName: string, emailAddress: string, key: string, name: string, timeZone: string>, requestFieldValues: table<fieldId: string, label: string, renderedValue: record, value: any>, requestType: record<_expands: list<string>, _links: record<self: string>, canCreateRequest: bool, description: string, fields: record<canAddRequestParticipants: bool, canRaiseOnBehalfOf: bool, requestTypeFields: list>, groupIds: list<string>, helpText: string, icon: record<_links: record, id: string>, id: string, issueTypeId: string, name: string, portalId: string, practice: string, restrictionStatus: string, serviceDeskId: string>, requestTypeId: string, serviceDesk: record<_links: record<self: string>, id: string, projectId: string, projectKey: string, projectName: string, projectTypeKey: string>, serviceDeskId: string, sla: record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: list<record>>, status: record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: list<record>>, summary: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/servicedeskapi/request")
  let body = {channel: $channel, form: $form, isAdfRequest: $isAdfRequest, raiseOnBehalfOf: $raiseOnBehalfOf, requestFieldValues: $requestFieldValues, requestParticipants: $requestParticipants, requestTypeId: $requestTypeId, serviceDeskId: $serviceDeskId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get customer request by id or key
#
# GET /rest/servicedeskapi/request/{issueIdOrKey}
# operationId: getCustomerRequestByIdOrKey
export def "rest-servicedeskapi-request get" [
  issueIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: list # A multi-value parameter indicating which properties of the customer request to expand, where:   *  `serviceDesk` returns additional service desk details.  *  `requestType` returns additional customer request type details.  *  `participant` returns the participant details.  *  `sla` returns the SLA information.  *  `status` returns the status transitions, in chronological order.  *  `attachment` returns the attachments.  *  `action` returns the actions that the user can or cannot perform.  *  `comment` returns the comments.  *  `comment.attachment` returns the attachment details for each comment.  *  `comment.renderedBody` (Experimental) return the rendered body in HTML format (in addition to the raw body) for each comment.
]: nothing -> record<_expands: list<string>, _links: record<agent: string, jiraRest: string, self: string, web: string>, actions: record<addAttachment: record<allowed: bool>, addComment: record<allowed: bool>, addParticipant: record<allowed: bool>, removeParticipant: record<allowed: bool>>, attachments: record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: list<record>>, comments: record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: list<record>>, createdDate: record<epochMillis: int, friendly: string, iso8601: string, jira: string>, currentStatus: record<status: string, statusCategory: string, statusDate: record<epochMillis: int, friendly: string, iso8601: string, jira: string>>, issueId: string, issueKey: string, participants: record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: list<record>>, reporter: record<_links: record<avatarUrls: record, jiraRest: string, self: string>, accountId: string, active: bool, displayName: string, emailAddress: string, key: string, name: string, timeZone: string>, requestFieldValues: table<fieldId: string, label: string, renderedValue: record, value: any>, requestType: record<_expands: list<string>, _links: record<self: string>, canCreateRequest: bool, description: string, fields: record<canAddRequestParticipants: bool, canRaiseOnBehalfOf: bool, requestTypeFields: list>, groupIds: list<string>, helpText: string, icon: record<_links: record, id: string>, id: string, issueTypeId: string, name: string, portalId: string, practice: string, restrictionStatus: string, serviceDeskId: string>, requestTypeId: string, serviceDesk: record<_links: record<self: string>, id: string, projectId: string, projectKey: string, projectName: string, projectTypeKey: string>, serviceDeskId: string, sla: record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: list<record>>, status: record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: list<record>>, summary: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get approvals
#
# GET /rest/servicedeskapi/request/{issueIdOrKey}/approval
# operationId: getApprovals
export def "rest-servicedeskapi-request-approval list" [
  issueIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # The starting index of the returned objects. Base index: 0. See the [Pagination](#pagination) section for more details. (format: int32)
  --limit: int # The maximum number of approvals to return per page. Default: 50. See the [Pagination](#pagination) section for more details. (format: int32)
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<_links: record, approvers: list, canAnswerApproval: bool, completedDate: record, createdDate: record, finalDecision: string, id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/approval" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get approval by id
#
# GET /rest/servicedeskapi/request/{issueIdOrKey}/approval/{approvalId}
# operationId: getApprovalById
export def "rest-servicedeskapi-request-approval get" [
  issueIdOrKey: string
  approvalId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<self: string>, approvers: table<approver: record, approverDecision: string>, canAnswerApproval: bool, completedDate: record<epochMillis: int, friendly: string, iso8601: string, jira: string>, createdDate: record<epochMillis: int, friendly: string, iso8601: string, jira: string>, finalDecision: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/approval/($approvalId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Answer approval
#
# POST /rest/servicedeskapi/request/{issueIdOrKey}/approval/{approvalId}
# operationId: answerApproval
export def "rest-servicedeskapi-request-approval answerApproval" [
  issueIdOrKey: string
  approvalId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --decision: string@decision-completer # Response to the approval request.
]: any -> record<_links: record<self: string>, approvers: table<approver: record, approverDecision: string>, canAnswerApproval: bool, completedDate: record<epochMillis: int, friendly: string, iso8601: string, jira: string>, createdDate: record<epochMillis: int, friendly: string, iso8601: string, jira: string>, finalDecision: string, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/approval/($approvalId)")
  let body = {decision: $decision} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get attachments for request
#
# GET /rest/servicedeskapi/request/{issueIdOrKey}/attachment
# operationId: getAttachmentsForRequest
export def "rest-servicedeskapi-request-attachment list" [
  issueIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # The starting index of the returned attachment. Base index: 0. See the [Pagination](#pagination) section for more details. (format: int32, default: 0)
  --limit: int # The maximum number of comments to return per page. Default: 50. See the [Pagination](#pagination) section for more details. (format: int32, default: 50)
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<_links: record, author: record, created: record, filename: string, mimeType: string, size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/attachment" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create comment with attachment
#
# POST /rest/servicedeskapi/request/{issueIdOrKey}/attachment
# operationId: createCommentWithAttachment
export def "rest-servicedeskapi-request-attachment createCommentWithAttachment" [
  issueIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additionalComment: any # Additional content of the comment
  --public: string@bool-completer # Controls whether the comment and its attachments are visible to customers
  --temporaryAttachmentIds: list # List of IDs for the temporary attachments to be added to the customer request.
]: any -> record<attachments: record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: list<record>>, comment: record<_expands: list<string>, _links: record<self: string>, attachments: record<_expands: list, _links: record, isLastPage: bool, limit: int, size: int, start: int, values: list>, author: record<_links: record, accountId: string, active: bool, displayName: string, emailAddress: string, key: string, name: string, timeZone: string>, body: string, created: record<epochMillis: int, friendly: string, iso8601: string, jira: string>, id: string, public: bool, renderedBody: record<html: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/attachment")
  let body = {additionalComment: $additionalComment, public: $public, temporaryAttachmentIds: $temporaryAttachmentIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get attachment content
#
# GET /rest/servicedeskapi/request/{issueIdOrKey}/attachment/{attachmentId}
# operationId: getAttachmentContent
export def "rest-servicedeskapi-request-attachment get" [
  issueIdOrKey: string
  attachmentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/attachment/($attachmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get attachment thumbnail
#
# GET /rest/servicedeskapi/request/{issueIdOrKey}/attachment/{attachmentId}/thumbnail
# operationId: getAttachmentThumbnail
export def "rest-servicedeskapi-request-attachment-thumbnail get" [
  issueIdOrKey: string
  attachmentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/attachment/($attachmentId)/thumbnail")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get request comments
#
# GET /rest/servicedeskapi/request/{issueIdOrKey}/comment
# operationId: getRequestComments
export def "rest-servicedeskapi-request-comment list" [
  issueIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --public: string@bool-completer # Specifies whether to return public comments or not. Default: true.
  --internal: string@bool-completer # Specifies whether to return internal comments or not. Default: true.
  --expand: list # A multi-value parameter indicating which properties of the comment to expand:   *  `attachment` returns the attachment details, if any, for each comment. (If you want to get all attachments for a request, use [servicedeskapi/request/\{issueIdOrKey\}/attachment](#api-request-issueIdOrKey-attachment-get).)  *  `renderedBody` (Experimental) returns the rendered body in HTML format (in addition to the raw body) for each comment.
  --start: int # The starting index of the returned comments. Base index: 0. See the [Pagination](#pagination) section for more details. (format: int32)
  --limit: int # The maximum number of comments to return per page. Default: 50. See the [Pagination](#pagination) section for more details. (format: int32)
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<_expands: list, _links: record, attachments: record, author: record, body: string, created: record, id: string, public: bool, renderedBody: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "public" $public "scalar") (serialize-qp "internal" $internal "scalar") (serialize-qp "expand" $expand "multi") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/comment" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create request comment
#
# POST /rest/servicedeskapi/request/{issueIdOrKey}/comment
# operationId: createRequestComment
export def "rest-servicedeskapi-request-comment createRequestComment" [
  issueIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string # Content of the comment.
  --public: string@bool-completer # Indicates whether the comment is public (true) or private/internal (false).
]: any -> record<_expands: list<string>, _links: record<self: string>, attachments: record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: list<record>>, author: record<_links: record<avatarUrls: record, jiraRest: string, self: string>, accountId: string, active: bool, displayName: string, emailAddress: string, key: string, name: string, timeZone: string>, body: string, created: record<epochMillis: int, friendly: string, iso8601: string, jira: string>, id: string, public: bool, renderedBody: record<html: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/comment")
  let body = {body: $body_body, public: $public} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get request comment by id
#
# GET /rest/servicedeskapi/request/{issueIdOrKey}/comment/{commentId}
# operationId: getRequestCommentById
export def "rest-servicedeskapi-request-comment get" [
  issueIdOrKey: string
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: list # A multi-value parameter indicating which properties of the comment to expand:   *  `attachment` returns the attachment details, if any, for the comment. (If you want to get all attachments for a request, use [servicedeskapi/request/\{issueIdOrKey\}/attachment](#api-request-issueIdOrKey-attachment-get).)  *  `renderedBody` (Experimental) returns the rendered body in HTML format (in addition to the raw body) of the comment.
]: nothing -> record<_expands: list<string>, _links: record<self: string>, attachments: record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: list<record>>, author: record<_links: record<avatarUrls: record, jiraRest: string, self: string>, accountId: string, active: bool, displayName: string, emailAddress: string, key: string, name: string, timeZone: string>, body: string, created: record<epochMillis: int, friendly: string, iso8601: string, jira: string>, id: string, public: bool, renderedBody: record<html: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/comment/($commentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get comment attachments
#
# GET /rest/servicedeskapi/request/{issueIdOrKey}/comment/{commentId}/attachment
# operationId: getCommentAttachments
export def "rest-servicedeskapi-request-comment-attachment get" [
  issueIdOrKey: string
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # The starting index of the returned comments. Base index: 0. See the [Pagination](#pagination) section for more details. (format: int32)
  --limit: int # The maximum number of comments to return per page. Default: 50. See the [Pagination](#pagination) section for more details. (format: int32)
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<_links: record, author: record, created: record, filename: string, mimeType: string, size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/comment/($commentId)/attachment" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unsubscribe
#
# DELETE /rest/servicedeskapi/request/{issueIdOrKey}/notification
# operationId: unsubscribe
export def "rest-servicedeskapi-request-notification unsubscribe" [
  issueIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/notification")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get subscription status
#
# GET /rest/servicedeskapi/request/{issueIdOrKey}/notification
# operationId: getSubscriptionStatus
export def "rest-servicedeskapi-request-notification get" [
  issueIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<subscribed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/notification")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscribe
#
# PUT /rest/servicedeskapi/request/{issueIdOrKey}/notification
# operationId: subscribe
export def "rest-servicedeskapi-request-notification subscribe" [
  issueIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/notification")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove request participants
#
# DELETE /rest/servicedeskapi/request/{issueIdOrKey}/participant
# operationId: removeRequestParticipants
export def "rest-servicedeskapi-request-participant removeRequestParticipants" [
  issueIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountIds: list # List of users, specified by account IDs, to add to or remove as participants in the request.
  --usernames: list # This property is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details. Use `accountIds` instead.
]: any -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<_links: record, accountId: string, active: bool, displayName: string, emailAddress: string, key: string, name: string, timeZone: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/participant")
  let body = {accountIds: $accountIds, usernames: $usernames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get request participants
#
# GET /rest/servicedeskapi/request/{issueIdOrKey}/participant
# operationId: getRequestParticipants
export def "rest-servicedeskapi-request-participant get" [
  issueIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # The starting index of the returned objects. Base index: 0. See the [Pagination](#pagination) section for more details. (format: int32)
  --limit: int # The maximum number of request types to return per page. Default: 50. See the [Pagination](#pagination) section for more details. (format: int32)
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<_links: record, accountId: string, active: bool, displayName: string, emailAddress: string, key: string, name: string, timeZone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/participant" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add request participants
#
# POST /rest/servicedeskapi/request/{issueIdOrKey}/participant
# operationId: addRequestParticipants
export def "rest-servicedeskapi-request-participant addRequestParticipants" [
  issueIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountIds: list # List of users, specified by account IDs, to add to or remove as participants in the request.
  --usernames: list # This property is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details. Use `accountIds` instead.
]: any -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<_links: record, accountId: string, active: bool, displayName: string, emailAddress: string, key: string, name: string, timeZone: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/participant")
  let body = {accountIds: $accountIds, usernames: $usernames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get sla information
#
# GET /rest/servicedeskapi/request/{issueIdOrKey}/sla
# operationId: getSlaInformation
export def "rest-servicedeskapi-request-sla list" [
  issueIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # The starting index of the returned objects. Base index: 0. See the [Pagination](#pagination) section for more details. (format: int32)
  --limit: int # The maximum number of request types to return per page. Default: 50. See the [Pagination](#pagination) section for more details. (format: int32)
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<_links: record, completedCycles: list, id: string, name: string, ongoingCycle: record, slaDisplayFormat: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/sla" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get sla information by id
#
# GET /rest/servicedeskapi/request/{issueIdOrKey}/sla/{slaMetricId}
# operationId: getSlaInformationById
export def "rest-servicedeskapi-request-sla get" [
  issueIdOrKey: string
  slaMetricId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<self: string>, completedCycles: table<breachTime: record, breached: bool, elapsedTime: record, goalDuration: record, remainingTime: record, startTime: record, stopTime: record>, id: string, name: string, ongoingCycle: record<breachTime: record<epochMillis: int, friendly: string, iso8601: string, jira: string>, breached: bool, elapsedTime: record<friendly: string, millis: int>, goalDuration: record<friendly: string, millis: int>, paused: bool, remainingTime: record<friendly: string, millis: int>, startTime: record<epochMillis: int, friendly: string, iso8601: string, jira: string>, withinCalendarHours: bool>, slaDisplayFormat: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/sla/($slaMetricId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get customer request status
#
# GET /rest/servicedeskapi/request/{issueIdOrKey}/status
# operationId: getCustomerRequestStatus
export def "rest-servicedeskapi-request-status get" [
  issueIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # The starting index of the returned objects. Base index: 0. See the [Pagination](#pagination) section for more details. (format: int32)
  --limit: int # The maximum number of items to return per page. Default: 50. See the [Pagination](#pagination) section for more details. (format: int32)
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<status: string, statusCategory: string, statusDate: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get customer transitions
#
# GET /rest/servicedeskapi/request/{issueIdOrKey}/transition
# operationId: getCustomerTransitions
export def "rest-servicedeskapi-request-transition get" [
  issueIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # The starting index of the returned objects. Base index: 0. See the [Pagination](#pagination) section for more details. (format: int32)
  --limit: int # The maximum number of items to return per page. Default: 50. See the [Pagination](#pagination) section for more details. (format: int32)
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/transition" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Perform customer transition
#
# POST /rest/servicedeskapi/request/{issueIdOrKey}/transition
# operationId: performCustomerTransition
export def "rest-servicedeskapi-request-transition performCustomerTransition" [
  issueIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additionalComment: any # Comment explaining the reason for the transition.
  --id: string # ID of the transition to be performed.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($issueIdOrKey)/transition")
  let body = {additionalComment: $additionalComment, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete feedback
#
# DELETE /rest/servicedeskapi/request/{requestIdOrKey}/feedback
# operationId: deleteFeedback
export def "rest-servicedeskapi-request-feedback delete" [
  requestIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($requestIdOrKey)/feedback")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get feedback
#
# GET /rest/servicedeskapi/request/{requestIdOrKey}/feedback
# operationId: getFeedback
export def "rest-servicedeskapi-request-feedback get" [
  requestIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<comment: record<body: string>, rating: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($requestIdOrKey)/feedback")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Post feedback
#
# POST /rest/servicedeskapi/request/{requestIdOrKey}/feedback
# operationId: postFeedback
export def "rest-servicedeskapi-request-feedback post" [
  requestIdOrKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --comment: any # (Optional) The comment provided with this feedback.
  --rating: int # A numeric representation of the rating, this must be an integer value between 1 and 5. (format: int32)
  --type: string # Indicates the type of feedback, supported values: `csat`.
]: any -> record<comment: record<body: string>, rating: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/request/($requestIdOrKey)/feedback")
  let body = {comment: $comment, rating: $rating, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all request types
#
# GET /rest/servicedeskapi/requesttype
# operationId: getAllRequestTypes
export def "rest-servicedeskapi-requesttype get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --searchQuery: string # String to be used to filter the results.
  --serviceDeskId: list # Filter the request types by service desk Ids provided. Multiple values of the query parameter are supported. For example, `serviceDeskId=1&serviceDeskId=2` will return request types only for service desks 1 and 2.
  --start: int # The starting index of the returned objects. Base index: 0. See the [Pagination](#pagination) section for more details. (format: int32)
  --limit: int # The maximum number of items to return per page. Default: 50. See the [Pagination](#pagination) section for more details. (format: int32)
  --expand: list
  --includeHiddenRequestTypesInSearch: string@bool-completer # Whether to include hidden request types when searching with `searchQuery`. (default: false)
  --restrictionStatus: string # Request type restriction status (`open` or `restricted`) used to filter the results.
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<_expands: list, _links: record, canCreateRequest: bool, description: string, fields: record, groupIds: list, helpText: string, icon: record, id: string, issueTypeId: string, name: string, portalId: string, practice: string, restrictionStatus: string, serviceDeskId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchQuery" $searchQuery "scalar") (serialize-qp "serviceDeskId" $serviceDeskId "multi") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "expand" $expand "multi") (serialize-qp "includeHiddenRequestTypesInSearch" $includeHiddenRequestTypesInSearch "scalar") (serialize-qp "restrictionStatus" $restrictionStatus "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/servicedeskapi/requesttype" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get service desks
#
# GET /rest/servicedeskapi/servicedesk
# operationId: getServiceDesks
export def "rest-servicedeskapi-servicedesk list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # The starting index of the returned objects. Base index: 0. See the [Pagination](#pagination) section for more details. (format: int32)
  --limit: int # The maximum number of items to return per page. Default: 50. See the [Pagination](#pagination) section for more details. (format: int32)
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<_links: record, id: string, projectId: string, projectKey: string, projectName: string, projectTypeKey: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/servicedeskapi/servicedesk" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get service desk by id
#
# GET /rest/servicedeskapi/servicedesk/{serviceDeskId}
# operationId: getServiceDeskById
export def "rest-servicedeskapi-servicedesk get" [
  serviceDeskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_links: record<self: string>, id: string, projectId: string, projectKey: string, projectName: string, projectTypeKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Attach temporary file
#
# POST /rest/servicedeskapi/servicedesk/{serviceDeskId}/attachTemporaryFile
# operationId: attachTemporaryFile
export def "rest-servicedeskapi-servicedesk-attach-temporary-file attachTemporaryFile" [
  serviceDeskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/attachTemporaryFile")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Remove customers
#
# DELETE /rest/servicedeskapi/servicedesk/{serviceDeskId}/customer
# operationId: removeCustomers
export def "rest-servicedeskapi-servicedesk-customer removeCustomers" [
  serviceDeskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountIds: list # List of users, specified by account IDs, to add to or remove from a service desk.
  --usernames: list # This property is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details. Use `accountIds` instead.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/customer")
  let body = {accountIds: $accountIds, usernames: $usernames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get customers
#
# GET /rest/servicedeskapi/servicedesk/{serviceDeskId}/customer
# operationId: getCustomers
export def "rest-servicedeskapi-servicedesk-customer get" [
  serviceDeskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The string used to filter the customer list.
  --start: int # The starting index of the returned objects. Base index: 0. See the [Pagination](#pagination) section for more details. (format: int32)
  --limit: int # The maximum number of users to return per page. Default: 50. See the [Pagination](#pagination) section for more details. (format: int32)
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<_links: record, accountId: string, active: bool, displayName: string, emailAddress: string, key: string, name: string, timeZone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/customer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add customers
#
# POST /rest/servicedeskapi/servicedesk/{serviceDeskId}/customer
# operationId: addCustomers
export def "rest-servicedeskapi-servicedesk-customer addCustomers" [
  serviceDeskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountIds: list # List of users, specified by account IDs, to add to or remove from a service desk.
  --usernames: list # This property is no longer available and will be removed from the documentation soon. See the [deprecation notice](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-user-privacy-api-migration-guide/) for details. Use `accountIds` instead.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/customer")
  let body = {accountIds: $accountIds, usernames: $usernames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Invite customer
#
# POST /rest/servicedeskapi/servicedesk/{serviceDeskId}/customer/invite
# operationId: inviteCustomer
export def "rest-servicedeskapi-servicedesk-customer-invite inviteCustomer" [
  serviceDeskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --strictConflictStatusCode: string@bool-completer # Optional boolean flag to return 409 Conflict status code when a customer with the same email already exists.
  --displayName: string # Customer's name for display in the UI.
  --email: string # Customer's email address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "strictConflictStatusCode" $strictConflictStatusCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/customer/invite" $qp)
  let body = {displayName: $displayName, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get articles
#
# GET /rest/servicedeskapi/servicedesk/{serviceDeskId}/knowledgebase/article
# operationId: getArticles
export def "rest-servicedeskapi-servicedesk-knowledgebase-article get" [
  serviceDeskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The string used to filter the articles (required).
  --highlight: string@bool-completer # If set to true matching query term in the title and excerpt will be highlighted using the `@@@hl@@@term@@@endhl@@@` syntax. Default: false. (default: false)
  --start: int # (Deprecated) The starting index of the returned objects. Base index: 0. (format: int32)
  --limit: int # The maximum number of items to return per page. Default: 50. See the section for more details. (format: int32)
  --cursor: string # Pointer to a set of search results, returned as part of the next or prev URL from the previous search call.
  --prev: string@bool-completer # Should navigate to the previous page. Defaulted to false. Set to true as part of prev URL from the previous search call. (default: false)
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<content: record, excerpt: string, source: record, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "highlight" $highlight "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "prev" $prev "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/knowledgebase/article" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove organization
#
# DELETE /rest/servicedeskapi/servicedesk/{serviceDeskId}/organization
# operationId: removeOrganization
export def "rest-servicedeskapi-servicedesk-organization removeOrganization" [
  serviceDeskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: int # List of organizations, specified by 'ID' field values, to add to or remove from the service desk. (format: int32)
  --body-serviceDeskId: string # Service desk Id for which, organization needs to be updated
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/organization")
  let body = {organizationId: $organizationId, serviceDeskId: $body_serviceDeskId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get organizations
#
# GET /rest/servicedeskapi/servicedesk/{serviceDeskId}/organization
# operationId: getOrganizations
export def "rest-servicedeskapi-servicedesk-organization get" [
  serviceDeskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # The starting index of the returned objects. Base index: 0. See the [Pagination](#pagination) section for more details. (format: int32)
  --limit: int # The maximum number of items to return per page. Default: 50. See the [Pagination](#pagination) section for more details. (format: int32)
  --accountId: string # The account ID of the user, which uniquely identifies the user across all Atlassian products. For example, *5b10ac8d82e05b22cc7d4ef5*.
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<_links: record, created: record, id: string, name: string, scimManaged: bool, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "accountId" $accountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/organization" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add organization
#
# POST /rest/servicedeskapi/servicedesk/{serviceDeskId}/organization
# operationId: addOrganization
export def "rest-servicedeskapi-servicedesk-organization addOrganization" [
  serviceDeskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: int # List of organizations, specified by 'ID' field values, to add to or remove from the service desk. (format: int32)
  --body-serviceDeskId: string # Service desk Id for which, organization needs to be updated
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/organization")
  let body = {organizationId: $organizationId, serviceDeskId: $body_serviceDeskId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get queues
#
# GET /rest/servicedeskapi/servicedesk/{serviceDeskId}/queue
# operationId: getQueues
export def "rest-servicedeskapi-servicedesk-queue list" [
  serviceDeskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeCount: string@bool-completer # Specifies whether to include each queue's customer request (issue) count in the response. (default: false)
  --start: int # The starting index of the returned objects. Base index: 0. See the [Pagination](#pagination) section for more details. (format: int32)
  --limit: int # The maximum number of items to return per page. Default: 50. See the [Pagination](#pagination) section for more details. (format: int32)
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<_links: record, fields: list, id: string, issueCount: int, jql: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeCount" $includeCount "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/queue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get queue
#
# GET /rest/servicedeskapi/servicedesk/{serviceDeskId}/queue/{queueId}
# operationId: getQueue
export def "rest-servicedeskapi-servicedesk-queue get" [
  serviceDeskId: string
  queueId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeCount: string@bool-completer # Specifies whether to include each queue's customer request (issue) count in the response. (default: false)
]: nothing -> record<_links: record<self: string>, fields: list<string>, id: string, issueCount: int, jql: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeCount" $includeCount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/queue/($queueId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get issues in queue
#
# GET /rest/servicedeskapi/servicedesk/{serviceDeskId}/queue/{queueId}/issue
# operationId: getIssuesInQueue
export def "rest-servicedeskapi-servicedesk-queue-issue get" [
  serviceDeskId: string
  queueId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # The starting index of the returned objects. Base index: 0. See the [Pagination](#pagination) section for more details. (format: int32)
  --limit: int # The maximum number of items to return per page. Default: 50. See the [Pagination](#pagination) section for more details. (format: int32)
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<changelog: record, editmeta: record, expand: string, fields: record, fieldsToInclude: record, id: string, key: string, names: record, operations: record, properties: record, renderedFields: record, schema: record, self: string, transitions: list, versionedRepresentations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/queue/($queueId)/issue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get request types
#
# GET /rest/servicedeskapi/servicedesk/{serviceDeskId}/requesttype
# operationId: getRequestTypes
export def "rest-servicedeskapi-servicedesk-requesttype list" [
  serviceDeskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --groupId: int # Filters results to those in a customer request type group. (format: int32)
  --expand: list
  --searchQuery: string # The string to be used to filter the results.
  --start: int # The starting index of the returned objects. Base index: 0. See the [Pagination](#pagination) section for more details. (format: int32)
  --limit: int # The maximum number of items to return per page. Default: 50. See the [Pagination](#pagination) section for more details. (format: int32)
  --includeHiddenRequestTypesInSearch: string@bool-completer # Whether to include hidden request types when searching with `searchQuery`. (default: false)
  --restrictionStatus: string # Request type restriction status (`open` or `restricted`) used to filter the results.
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<_expands: list, _links: record, canCreateRequest: bool, description: string, fields: record, groupIds: list, helpText: string, icon: record, id: string, issueTypeId: string, name: string, portalId: string, practice: string, restrictionStatus: string, serviceDeskId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupId" $groupId "scalar") (serialize-qp "expand" $expand "multi") (serialize-qp "searchQuery" $searchQuery "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "includeHiddenRequestTypesInSearch" $includeHiddenRequestTypesInSearch "scalar") (serialize-qp "restrictionStatus" $restrictionStatus "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/requesttype" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create request type
#
# POST /rest/servicedeskapi/servicedesk/{serviceDeskId}/requesttype
# operationId: createRequestType
export def "rest-servicedeskapi-servicedesk-requesttype createRequestType" [
  serviceDeskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description of the request type on the service desk.
  --helpText: string # Help text for the request type on the service desk.
  --issueTypeId: string # ID of the request type to add to the service desk.
  --name: string # Name of the request type on the service desk.
]: any -> record<_expands: list<string>, _links: record<self: string>, canCreateRequest: bool, description: string, fields: record<canAddRequestParticipants: bool, canRaiseOnBehalfOf: bool, requestTypeFields: list<record>>, groupIds: list<string>, helpText: string, icon: record<_links: record<iconUrls: record>, id: string>, id: string, issueTypeId: string, name: string, portalId: string, practice: string, restrictionStatus: string, serviceDeskId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/requesttype")
  let body = {description: $description, helpText: $helpText, issueTypeId: $issueTypeId, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check request type permissions
#
# POST /rest/servicedeskapi/servicedesk/{serviceDeskId}/requesttype/permissions/check
# operationId: checkRequestTypePermissions
export def "rest-servicedeskapi-servicedesk-requesttype-permissions-check checkRequestTypePermissions" [
  serviceDeskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountId: string # The account ID of a user.
  --permissions: list # List of requested permissions.
  --requestTypeIds: list # List of request type IDs.
]: any -> record<canAdminister: list<int>, canCreateRequest: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/requesttype/permissions/check")
  let body = {accountId: $accountId, permissions: $permissions, requestTypeIds: $requestTypeIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete request type
#
# DELETE /rest/servicedeskapi/servicedesk/{serviceDeskId}/requesttype/{requestTypeId}
# operationId: deleteRequestType
export def "rest-servicedeskapi-servicedesk-requesttype delete" [
  serviceDeskId: string
  requestTypeId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/requesttype/($requestTypeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get request type by id
#
# GET /rest/servicedeskapi/servicedesk/{serviceDeskId}/requesttype/{requestTypeId}
# operationId: getRequestTypeById
export def "rest-servicedeskapi-servicedesk-requesttype get" [
  serviceDeskId: string
  requestTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: list
]: nothing -> record<_expands: list<string>, _links: record<self: string>, canCreateRequest: bool, description: string, fields: record<canAddRequestParticipants: bool, canRaiseOnBehalfOf: bool, requestTypeFields: list<record>>, groupIds: list<string>, helpText: string, icon: record<_links: record<iconUrls: record>, id: string>, id: string, issueTypeId: string, name: string, portalId: string, practice: string, restrictionStatus: string, serviceDeskId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/requesttype/($requestTypeId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get request type fields
#
# GET /rest/servicedeskapi/servicedesk/{serviceDeskId}/requesttype/{requestTypeId}/field
# operationId: getRequestTypeFields
export def "rest-servicedeskapi-servicedesk-requesttype-field get" [
  serviceDeskId: string
  requestTypeId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: list # Use [expand](#expansion) to include additional information in the response. This parameter accepts `hiddenFields` that returns hidden fields associated with the request type.
]: nothing -> record<canAddRequestParticipants: bool, canRaiseOnBehalfOf: bool, requestTypeFields: table<defaultValues: list, description: string, fieldId: string, jiraSchema: record, name: string, presetValues: list, required: bool, validValues: list, visible: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/requesttype/($requestTypeId)/field" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get properties keys
#
# GET /rest/servicedeskapi/servicedesk/{serviceDeskId}/requesttype/{requestTypeId}/property
# operationId: getPropertiesKeys
export def "rest-servicedeskapi-servicedesk-requesttype-property list" [
  requestTypeId: int
  serviceDeskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<keys: table<key: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/requesttype/($requestTypeId)/property")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete property
#
# DELETE /rest/servicedeskapi/servicedesk/{serviceDeskId}/requesttype/{requestTypeId}/property/{propertyKey}
# operationId: deleteProperty
export def "rest-servicedeskapi-servicedesk-requesttype-property delete" [
  serviceDeskId: string
  requestTypeId: int
  propertyKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/requesttype/($requestTypeId)/property/($propertyKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get property
#
# GET /rest/servicedeskapi/servicedesk/{serviceDeskId}/requesttype/{requestTypeId}/property/{propertyKey}
# operationId: getProperty
export def "rest-servicedeskapi-servicedesk-requesttype-property get" [
  serviceDeskId: string
  requestTypeId: int
  propertyKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/requesttype/($requestTypeId)/property/($propertyKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set property
#
# PUT /rest/servicedeskapi/servicedesk/{serviceDeskId}/requesttype/{requestTypeId}/property/{propertyKey}
# operationId: setProperty
export def "rest-servicedeskapi-servicedesk-requesttype-property setProperty" [
  serviceDeskId: string
  requestTypeId: int
  propertyKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/requesttype/($requestTypeId)/property/($propertyKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get request type groups
#
# GET /rest/servicedeskapi/servicedesk/{serviceDeskId}/requesttypegroup
# operationId: getRequestTypeGroups
export def "rest-servicedeskapi-servicedesk-requesttypegroup get" [
  serviceDeskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # The starting index of the returned objects. Base index: 0. See the [Pagination](#pagination) section for more details. (format: int32)
  --limit: int # The maximum number of items to return per page. Default: 50. See the [Pagination](#pagination) section for more details. (format: int32)
]: nothing -> record<_expands: list<string>, _links: record<base: string, context: string, next: string, prev: string, self: string>, isLastPage: bool, limit: int, size: int, start: int, values: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rest/servicedeskapi/servicedesk/($serviceDeskId)/requesttypegroup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
