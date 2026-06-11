# Auto-generated client for CockroachDB Cloud API v2024-09-16
# Source: https://cockroachlabs.cloud/assets/docs/api/latest/openapi.json
# Auth: --token flag or $env.COCKROACHDB_CLOUD_API_TOKEN

const BASE_URL = "https://cockroachlabs.cloud"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o COCKROACHDB_CLOUD_API_TOKEN | default "" }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://cockroachlabs.cloud"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def paginationsort-order-completer [] { ["ASC" "DESC"] }
def sort-order-completer [] { ["ASC" "DESC"] }
def paginationsort-by-completer [] { ["CREATED_AT" "DELETED_AT" "NAME"] }
def provider-completer [] { ["AWS" "AZURE" "GCP"] }
def delete-protection-completer [] { ["DISABLED" "ENABLED"] }
def plan-completer [] { ["ADVANCED" "BASIC" "STANDARD"] }
def upgrade-status-completer [] { ["FINALIZED" "MAJOR_UPGRADE_RUNNING" "PENDING_FINALIZATION" "ROLLBACK_RUNNING" "UPGRADE_AVAILABLE"] }
def action-completer [] { ["REVOKE"] }
def os-completer [] { ["LINUX" "MAC" "WINDOWS"] }
def type-completer [] { ["AWS_CLOUDWATCH" "AZURE_LOG_ANALYTICS" "GCP_CLOUD_LOGGING"] }
def site-completer [] { ["EU1" "US1" "US1_GOV" "US3" "US5"] }
def status-completer [] { ["AVAILABLE" "REJECTED"] }
def target-service-type-completer [] { ["MSK_SASL_IAM" "MSK_SASL_SCRAM" "MSK_TLS" "PRIVATE_SERVICE"] }
def type-completer-1 [] { ["AWS_ACCOUNT_ID"] }
def deferral-policy-completer [] { ["DEFERRAL_30_DAYS" "DEFERRAL_60_DAYS" "DEFERRAL_90_DAYS" "FIXED_DEFERRAL" "NOT_DEFERRED"] }
def type-completer-2 [] { ["CLUSTER" "DATABASE" "TABLE"] }
def status-completer-1 [] { ["DRAFT" "FINALIZED"] }
def status-completer-2 [] { ["CANCELED" "COMPLETED" "FAILING_OVER" "REPLICATING" "STARTING"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "scim-groups GetGroups" } } | get name | first)
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

# List groups
#
# GET /api/scim/v2/Groups
# operationId: CockroachCloud_GetGroups
export def "scim-groups GetGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: string
  --excludedAttributes: string
  --filter: string
  --count: int # The maximum number of resources to return. If omitted, defaults to 20. If set to 0, the response will contain no resources but will include metadata such as `totalResults`, complying with [RFC 7644, Section 3.4.2.4: Pagination](https://datatracker.ietf.org/doc/html/rfc7644#section-3.4.2.4). (format: int32)
  --startIndex: int # The 1-based index of the first resource to return in the response. If omitted or less than 1, defaults to 1. This behavior complies with [RFC 7644, Section 3.4.2.4: Pagination](https://datatracker.ietf.org/doc/html/rfc7644#section-3.4.2.4). (format: int32)
]: nothing -> record<Resources: table<displayName: string, externalId: string, id: string, members: list, meta: record, schemas: list>, itemsPerPage: int, schemas: list<string>, startIndex: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "startIndex" $startIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/scim/v2/Groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a group
#
# POST /api/scim/v2/Groups
# operationId: CockroachCloud_CreateGroup
# --members item shape: {display?: string, ref?: string, type?: string, value?: string}
export def "scim-groups CreateGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  displayName: string
  --externalId: string
  --members: list # item shape: {display?: string, ref?: string, type?: string, value?: string}
  schemas: list
]: any -> record<displayName: string, externalId: string, id: string, members: table<display: string, ref: string, type: string, value: string>, meta: record<created: string, lastModified: string, location: string, resourceType: string>, schemas: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/scim/v2/Groups")
  let body = {displayName: $displayName, externalId: $externalId, members: $members, schemas: $schemas} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search groups
#
# POST /api/scim/v2/Groups/.search
# operationId: CockroachCloud_SearchGroups
export def "scim-groups-search SearchGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: string
  --count: int # The maximum number of resources to return. If omitted, defaults to 20. If set to 0, the response will contain no resources but will include metadata such as `totalResults`, complying with [RFC 7644, Section 3.4.2.4: Pagination](https://datatracker.ietf.org/doc/html/rfc7644#section-3.4.2.4). (format: int32)
  --excludedAttributes: string
  --filter: string
  --startIndex: int # The 1-based index of the first resource to return in the response. If omitted or less than 1, defaults to 1. This behavior complies with [RFC 7644, Section 3.4.2.4: Pagination](https://datatracker.ietf.org/doc/html/rfc7644#section-3.4.2.4). (format: int32)
]: any -> record<Resources: table<displayName: string, externalId: string, id: string, members: list, meta: record, schemas: list>, itemsPerPage: int, schemas: list<string>, startIndex: int, totalResults: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/scim/v2/Groups/.search")
  let body = {attributes: $attributes, count: $count, excludedAttributes: $excludedAttributes, filter: $filter, startIndex: $startIndex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search groups (Deprecated)
#
# PUT /api/scim/v2/Groups/.search
# DEPRECATED
# operationId: CockroachCloud_GetGroups2
@deprecated
export def "scim-groups-search GetGroups2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: string
  --count: int # The maximum number of resources to return. If omitted, defaults to 20. If set to 0, the response will contain no resources but will include metadata such as `totalResults`, complying with [RFC 7644, Section 3.4.2.4: Pagination](https://datatracker.ietf.org/doc/html/rfc7644#section-3.4.2.4). (format: int32)
  --excludedAttributes: string
  --filter: string
  --startIndex: int # The 1-based index of the first resource to return in the response. If omitted or less than 1, defaults to 1. This behavior complies with [RFC 7644, Section 3.4.2.4: Pagination](https://datatracker.ietf.org/doc/html/rfc7644#section-3.4.2.4). (format: int32)
]: any -> record<Resources: table<displayName: string, externalId: string, id: string, members: list, meta: record, schemas: list>, itemsPerPage: int, schemas: list<string>, startIndex: int, totalResults: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/scim/v2/Groups/.search")
  let body = {attributes: $attributes, count: $count, excludedAttributes: $excludedAttributes, filter: $filter, startIndex: $startIndex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a group based on ID
#
# DELETE /api/scim/v2/Groups/{id}
# operationId: CockroachCloud_DeleteGroup
export def "scim-groups DeleteGroup" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/scim/v2/Groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a group by ID
#
# GET /api/scim/v2/Groups/{id}
# operationId: CockroachCloud_GetGroup
export def "scim-groups GetGroup" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: string
  --excludedAttributes: string
]: nothing -> record<displayName: string, externalId: string, id: string, members: table<display: string, ref: string, type: string, value: string>, meta: record<created: string, lastModified: string, location: string, resourceType: string>, schemas: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/scim/v2/Groups/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch a group by supplying partial updates
#
# PATCH /api/scim/v2/Groups/{id}
# operationId: CockroachCloud_PatchGroup
# --Operations item shape: {op: string, path?: string, value?: any}
export def "scim-groups PatchGroup" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Operations: list # item shape: {op: string, path?: string, value?: any}
  schemas: list # A list of one or more URIs identifying SCIM schemas that define the structure of the attributes in the request. The only supported schema at this time is "urn:ietf:params:scim:api:messages:2.0:PatchOp".
]: any -> record<displayName: string, externalId: string, id: string, members: table<display: string, ref: string, type: string, value: string>, meta: record<created: string, lastModified: string, location: string, resourceType: string>, schemas: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/scim/v2/Groups/($id)")
  let body = {Operations: $Operations, schemas: $schemas} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a group by supplying all values of the user object
#
# PUT /api/scim/v2/Groups/{id}
# operationId: CockroachCloud_UpdateGroup
# --members item shape: {display?: string, ref?: string, type?: string, value?: string}
export def "scim-groups UpdateGroup" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  displayName: string
  --externalId: string
  --members: list # item shape: {display?: string, ref?: string, type?: string, value?: string}
  schemas: list
]: any -> record<displayName: string, externalId: string, id: string, members: table<display: string, ref: string, type: string, value: string>, meta: record<created: string, lastModified: string, location: string, resourceType: string>, schemas: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/scim/v2/Groups/($id)")
  let body = {displayName: $displayName, externalId: $externalId, members: $members, schemas: $schemas} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search a group by ID
#
# POST /api/scim/v2/Groups/{id}/.search
# operationId: CockroachCloud_SearchGroup
export def "scim-groups-search SearchGroup" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: string
  --excludedAttributes: string
]: any -> record<displayName: string, externalId: string, id: string, members: table<display: string, ref: string, type: string, value: string>, meta: record<created: string, lastModified: string, location: string, resourceType: string>, schemas: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/scim/v2/Groups/($id)/.search")
  let body = {attributes: $attributes, excludedAttributes: $excludedAttributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search a group by ID (Deprecated)
#
# PUT /api/scim/v2/Groups/{id}/.search
# DEPRECATED
# operationId: CockroachCloud_GetGroup2
@deprecated
export def "scim-groups-search GetGroup2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: string
  --excludedAttributes: string
]: any -> record<displayName: string, externalId: string, id: string, members: table<display: string, ref: string, type: string, value: string>, meta: record<created: string, lastModified: string, location: string, resourceType: string>, schemas: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/scim/v2/Groups/($id)/.search")
  let body = {attributes: $attributes, excludedAttributes: $excludedAttributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the SCIM resource types
#
# GET /api/scim/v2/ResourceTypes
# operationId: CockroachCloud_GetResourceTypes
export def "scim-resource-types GetResourceTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: string
  --excludedAttributes: string
]: nothing -> record<Resources: table<description: string, endpoint: string, id: string, meta: record, name: string, schema: string, schemas: list>, itemsPerPage: int, schemas: list<string>, startIndex: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/scim/v2/ResourceTypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a SCIM resource type by ID
#
# GET /api/scim/v2/ResourceTypes/{resourceId}
# operationId: CockroachCloud_GetResourceType
export def "scim-resource-types GetResourceType" [
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: string
  --excludedAttributes: string
]: nothing -> record<description: string, endpoint: string, id: string, meta: record<created: string, lastModified: string, location: string, resourceType: string>, name: string, schema: string, schemas: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/scim/v2/ResourceTypes/($resourceId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the SCIM schemas
#
# GET /api/scim/v2/Schemas
# operationId: CockroachCloud_GetSchemas
export def "scim-schemas GetSchemas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: string
  --excludedAttributes: string
]: nothing -> record<Resources: table<attributes: list, description: string, id: string, meta: record, name: string>, itemsPerPage: int, schemas: list<string>, startIndex: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/scim/v2/Schemas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a SCIM schema by ID
#
# GET /api/scim/v2/Schemas/{schemaId}
# operationId: CockroachCloud_GetSchema
export def "scim-schemas GetSchema" [
  schemaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: string
  --excludedAttributes: string
]: nothing -> record<attributes: table<canonicalValues: list, caseExact: bool, description: string, multiValued: bool, mutability: string, name: string, referenceTypes: list, required: bool, returned: string, subAttributes: list, type: string, uniqueness: string>, description: string, id: string, meta: record<created: string, lastModified: string, location: string, resourceType: string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/scim/v2/Schemas/($schemaId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return the SCIM Service Provider configuration
#
# GET /api/scim/v2/ServiceProviderConfig
# operationId: CockroachCloud_GetServiceProviderConfig
export def "scim-service-provider-config GetServiceProviderConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<authenticationSchemes: table<description: string, documentationUri: string, name: string, primary: bool, specUri: string, type: string>, bulk: record<maxOperations: int, maxPayloadSize: int, supported: bool>, changePassword: record<supported: bool>, etag: record<maxResults: int, supported: bool>, filter: record<maxResults: int, supported: bool>, meta: record<created: string, lastModified: string, location: string, resourceType: string>, schemas: list<string>, sort: record<supported: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/scim/v2/ServiceProviderConfig")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Users
#
# GET /api/scim/v2/Users
# operationId: CockroachCloud_GetUsers
export def "scim-users GetUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string
  --attributes: string
  --excludedAttributes: string
  --count: int # The maximum number of resources to return. If omitted, defaults to 20. If set to 0, the response will contain no resources but will include metadata such as `totalResults`, complying with [RFC 7644, Section 3.4.2.4: Pagination](https://datatracker.ietf.org/doc/html/rfc7644#section-3.4.2.4). (format: int32)
  --startIndex: int # The 1-based index of the first resource to return in the response. If omitted or less than 1, defaults to 1. This behavior complies with [RFC 7644, Section 3.4.2.4: Pagination](https://datatracker.ietf.org/doc/html/rfc7644#section-3.4.2.4). (format: int32)
]: nothing -> record<Resources: table<active: bool, displayName: string, emails: list, externalId: string, groups: list, id: string, meta: record, name: record, schemas: list, userName: string>, itemsPerPage: int, schemas: list<string>, startIndex: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "attributes" $attributes "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "startIndex" $startIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/scim/v2/Users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a user
#
# POST /api/scim/v2/Users
# operationId: CockroachCloud_CreateUser
# --emails item shape: {display?: string, primary?: bool, type?: string, value: string}
# --name shape: {familyName?: string, givenName?: string}
export def "scim-users CreateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer
  --displayName: string
  emails: list # item shape: {display?: string, primary?: bool, type?: string, value: string}
  --externalId: string
  --name: record # shape: {familyName?: string, givenName?: string}
  schemas: list
  --userName: string
]: any -> record<active: bool, displayName: string, emails: table<display: string, primary: bool, type: string, value: string>, externalId: string, groups: table<display: string, ref: string, type: string, value: string>, id: string, meta: record<created: string, lastModified: string, location: string, resourceType: string>, name: record<familyName: string, givenName: string>, schemas: list<string>, userName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/scim/v2/Users")
  let body = {active: $active, displayName: $displayName, emails: $emails, externalId: $externalId, name: $name, schemas: $schemas, userName: $userName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search Users
#
# POST /api/scim/v2/Users/.search
# operationId: CockroachCloud_SearchUsers
export def "scim-users-search SearchUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: string
  --count: int # The maximum number of resources to return. If omitted, defaults to 20. If set to 0, the response will contain no resources but will include metadata such as `totalResults`, complying with [RFC 7644, Section 3.4.2.4: Pagination](https://datatracker.ietf.org/doc/html/rfc7644#section-3.4.2.4). (format: int32)
  --excludedAttributes: string
  --filter: string
  --startIndex: int # The 1-based index of the first resource to return in the response. If omitted or less than 1, defaults to 1. This behavior complies with [RFC 7644, Section 3.4.2.4: Pagination](https://datatracker.ietf.org/doc/html/rfc7644#section-3.4.2.4). (format: int32)
]: any -> record<Resources: table<active: bool, displayName: string, emails: list, externalId: string, groups: list, id: string, meta: record, name: record, schemas: list, userName: string>, itemsPerPage: int, schemas: list<string>, startIndex: int, totalResults: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/scim/v2/Users/.search")
  let body = {attributes: $attributes, count: $count, excludedAttributes: $excludedAttributes, filter: $filter, startIndex: $startIndex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search User (Deprecated)
#
# PUT /api/scim/v2/Users/.search
# DEPRECATED
# operationId: CockroachCloud_GetUsers2
@deprecated
export def "scim-users-search GetUsers2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: string
  --count: int # The maximum number of resources to return. If omitted, defaults to 20. If set to 0, the response will contain no resources but will include metadata such as `totalResults`, complying with [RFC 7644, Section 3.4.2.4: Pagination](https://datatracker.ietf.org/doc/html/rfc7644#section-3.4.2.4). (format: int32)
  --excludedAttributes: string
  --filter: string
  --startIndex: int # The 1-based index of the first resource to return in the response. If omitted or less than 1, defaults to 1. This behavior complies with [RFC 7644, Section 3.4.2.4: Pagination](https://datatracker.ietf.org/doc/html/rfc7644#section-3.4.2.4). (format: int32)
]: any -> record<Resources: table<active: bool, displayName: string, emails: list, externalId: string, groups: list, id: string, meta: record, name: record, schemas: list, userName: string>, itemsPerPage: int, schemas: list<string>, startIndex: int, totalResults: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/scim/v2/Users/.search")
  let body = {attributes: $attributes, count: $count, excludedAttributes: $excludedAttributes, filter: $filter, startIndex: $startIndex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a user based on ID
#
# DELETE /api/scim/v2/Users/{id}
# operationId: CockroachCloud_DeleteUser
export def "scim-users DeleteUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/scim/v2/Users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user by ID
#
# GET /api/scim/v2/Users/{id}
# operationId: CockroachCloud_GetUser
export def "scim-users GetUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: string
  --excludedAttributes: string
]: nothing -> record<active: bool, displayName: string, emails: table<display: string, primary: bool, type: string, value: string>, externalId: string, groups: table<display: string, ref: string, type: string, value: string>, id: string, meta: record<created: string, lastModified: string, location: string, resourceType: string>, name: record<familyName: string, givenName: string>, schemas: list<string>, userName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/scim/v2/Users/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch a user by supplying partial updates
#
# PATCH /api/scim/v2/Users/{id}
# operationId: CockroachCloud_PatchUser
# --Operations item shape: {op: string, path?: string, value?: any}
export def "scim-users PatchUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Operations: list # item shape: {op: string, path?: string, value?: any}
  schemas: list # A list of one or more URIs identifying SCIM schemas that define the structure of the attributes in the request. The only supported schema at this time is "urn:ietf:params:scim:api:messages:2.0:PatchOp".
]: any -> record<active: bool, displayName: string, emails: table<display: string, primary: bool, type: string, value: string>, externalId: string, groups: table<display: string, ref: string, type: string, value: string>, id: string, meta: record<created: string, lastModified: string, location: string, resourceType: string>, name: record<familyName: string, givenName: string>, schemas: list<string>, userName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/scim/v2/Users/($id)")
  let body = {Operations: $Operations, schemas: $schemas} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a user by supplying all values of the user object
#
# PUT /api/scim/v2/Users/{id}
# operationId: CockroachCloud_UpdateUser
# --emails item shape: {display?: string, primary?: bool, type?: string, value: string}
# --name shape: {familyName?: string, givenName?: string}
export def "scim-users UpdateUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer
  --displayName: string
  --emails: list # item shape: {display?: string, primary?: bool, type?: string, value: string}
  --externalId: string
  --name: record # shape: {familyName?: string, givenName?: string}
  --schemas: list
  --userName: string
]: any -> record<active: bool, displayName: string, emails: table<display: string, primary: bool, type: string, value: string>, externalId: string, groups: table<display: string, ref: string, type: string, value: string>, id: string, meta: record<created: string, lastModified: string, location: string, resourceType: string>, name: record<familyName: string, givenName: string>, schemas: list<string>, userName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/scim/v2/Users/($id)")
  let body = {active: $active, displayName: $displayName, emails: $emails, externalId: $externalId, name: $name, schemas: $schemas, userName: $userName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search for a user by ID
#
# POST /api/scim/v2/Users/{id}/.search
# operationId: CockroachCloud_SearchUser
export def "scim-users-search SearchUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: string
  --excludedAttributes: string
]: any -> record<active: bool, displayName: string, emails: table<display: string, primary: bool, type: string, value: string>, externalId: string, groups: table<display: string, ref: string, type: string, value: string>, id: string, meta: record<created: string, lastModified: string, location: string, resourceType: string>, name: record<familyName: string, givenName: string>, schemas: list<string>, userName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/scim/v2/Users/($id)/.search")
  let body = {attributes: $attributes, excludedAttributes: $excludedAttributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search for a user by ID (Deprecated)
#
# PUT /api/scim/v2/Users/{id}/.search
# DEPRECATED
# operationId: CockroachCloud_GetUser2
@deprecated
export def "scim-users-search GetUser2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: string
  --excludedAttributes: string
]: any -> record<active: bool, displayName: string, emails: table<display: string, primary: bool, type: string, value: string>, externalId: string, groups: table<display: string, ref: string, type: string, value: string>, id: string, meta: record<created: string, lastModified: string, location: string, resourceType: string>, name: record<familyName: string, givenName: string>, schemas: list<string>, userName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/scim/v2/Users/($id)/.search")
  let body = {attributes: $attributes, excludedAttributes: $excludedAttributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List API Keys
#
# GET /api/v1/api-keys
# operationId: CockroachCloud_ListApiKeys
export def "api-keys ListApiKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --service-account-id: string # Optional filter to limit the response to include only api keys for a specific service account.
  --paginationpage: string
  --paginationlimit: int # format: int32
  --paginationas-of-time: string # format: date-time
  --paginationsort-order: string@paginationsort-order-completer #  - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
]: nothing -> record<api_keys: table<created_at: string, id: string, name: string, service_account_id: string>, pagination: record<next_page: string, previous_page: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "service_account_id" $service_account_id "scalar") (serialize-qp "pagination.page" $paginationpage "scalar") (serialize-qp "pagination.limit" $paginationlimit "scalar") (serialize-qp "pagination.as_of_time" $paginationas_of_time "scalar") (serialize-qp "pagination.sort_order" $paginationsort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/api-keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new API Key
#
# POST /api/v1/api-keys
# operationId: CockroachCloud_CreateApiKey
export def "api-keys CreateApiKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the api key. (e.g. example name)
  service_account_id: string # The ID of the service account to create the api key for. (format: uuid, e.g. 1234abcd-1234-1234-abcd-12345678abcd)
]: any -> record<api_key: record<created_at: string, id: string, name: string, service_account_id: string>, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/api-keys")
  let body = {name: $name, service_account_id: $service_account_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an API Key
#
# DELETE /api/v1/api-keys/{id}
# operationId: CockroachCloud_DeleteApiKey
export def "api-keys DeleteApiKey" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, id: string, name: string, service_account_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/api-keys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an API Key by ID
#
# GET /api/v1/api-keys/{id}
# operationId: CockroachCloud_GetApiKey
export def "api-keys GetApiKey" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, id: string, name: string, service_account_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/api-keys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an API Key
#
# PATCH /api/v1/api-keys/{id}
# operationId: CockroachCloud_UpdateApiKey
export def "api-keys UpdateApiKey" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # name of the api key. (e.g. new name)
]: any -> record<created_at: string, id: string, name: string, service_account_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/api-keys/($id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List audit logs
#
# GET /api/v1/auditlogevents
# operationId: CockroachCloud_ListAuditLogs
export def "auditlogevents ListAuditLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --starting-from: string # starting_from is the (exclusive) timestamp from which log entries will be returned in the response based on their created_at time, respecting the sort order specified in pagination. If unset, the default will be the current time if results are returned in descending order and the beginning of time if results are in ascending order. (format: date-time)
  --sort-order: string@sort-order-completer # sort_order is the direction of pagination, with starting_from as the start point. If unset, the default is ascending order.   - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
  --limit: int # limit is the number of entries requested in the response. Note that the response may still contain slightly more results, since the response will always contain every entry at a particular timestamp. (format: int32)
]: nothing -> record<entries: table<action: string, cluster_id: string, cluster_name: string, created_at: string, error: string, id: string, metadata: record, payload: string, service_account_name: string, session_id: string, source: string, system_actor_name: string, trace_id: string, user_email: string>, next_starting_from: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "starting_from" $starting_from "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/auditlogevents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List available major cluster versions
#
# GET /api/v1/cluster-versions
# operationId: CockroachCloud_ListMajorClusterVersions
export def "cluster-versions ListMajorClusterVersions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --paginationpage: string
  --paginationlimit: int # format: int32
  --paginationas-of-time: string # format: date-time
  --paginationsort-order: string@paginationsort-order-completer #  - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
]: nothing -> record<pagination: record<next_page: string, previous_page: string>, versions: table<allowed_upgrades: list, release_type: string, support_end: string, support_status: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagination.page" $paginationpage "scalar") (serialize-qp "pagination.limit" $paginationlimit "scalar") (serialize-qp "pagination.as_of_time" $paginationas_of_time "scalar") (serialize-qp "pagination.sort_order" $paginationsort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/cluster-versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List clusters in the organization
#
# GET /api/v1/clusters
# operationId: CockroachCloud_ListClusters
export def "clusters ListClusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-inactive: string@bool-completer # If `true`, show clusters that have been deleted or failed to initialize. Note that inactive clusters will only be included if the requesting user has organization-scoped cluster read permissions. (default: false)
  --paginationpage: string
  --paginationlimit: int # format: int32
  --paginationas-of-time: string # format: date-time
  --paginationsort-order: string@paginationsort-order-completer #  - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
  --paginationsort-by: string@paginationsort-by-completer #  - NAME: Sort by cluster name. This is the default unless otherwise specified.  - CREATED_AT: Sort by cluster created_at.  - DELETED_AT: Sort by cluster deleted_at. Active clusters will be sorted by created_at.
]: nothing -> record<clusters: table<account_id: string, azure_cluster_identity_client_id: string, cidr_range: string, cloud_provider: string, cockroach_version: string, config: record, created_at: string, creator_id: string, customer_cloud_account: record, delete_protection: string, deleted_at: string, egress_traffic_policy: string, id: string, labels: record, name: string, network_visibility: string, operation_status: string, parent_id: string, plan: string, regions: list, sql_dns: string, state: string, updated_at: string, upgrade_status: string>, pagination: record<next_page: string, previous_page: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_inactive" $show_inactive "scalar") (serialize-qp "pagination.page" $paginationpage "scalar") (serialize-qp "pagination.limit" $paginationlimit "scalar") (serialize-qp "pagination.as_of_time" $paginationas_of_time "scalar") (serialize-qp "pagination.sort_order" $paginationsort_order "scalar") (serialize-qp "pagination.sort_by" $paginationsort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/clusters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create and initialize a new cluster
#
# POST /api/v1/clusters
# operationId: CockroachCloud_CreateCluster
# --spec shape: {customer_cloud_account?: record, dedicated?: record, delete_protection?: "ENABLED"|"DISABLED", labels?: record, parent_id?: string, plan?: "BASIC"|"STANDARD"|"ADVANCED", serverless?: record}
export def "clusters CreateCluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name must be 6-20 characters in length and can include numbers, lowercase letters, and dashes (but no leading or trailing dashes).
  provider: string@provider-completer #  - GCP: The Google Cloud Platform cloud provider.  - AWS: The Amazon Web Services cloud provider.  - AZURE: The Azure cloud provider.
  spec: record # shape: {customer_cloud_account?: record, dedicated?: record, delete_protection?: "ENABLED"|"DISABLED", labels?: record, parent_id?: string, plan?: "BASIC"|"STANDARD"|"ADVANCED", serverless?: record}
]: any -> record<account_id: string, azure_cluster_identity_client_id: string, cidr_range: string, cloud_provider: string, cockroach_version: string, config: record<dedicated: record<disk_iops: int, machine_type: string, memory_gib: float, num_virtual_cpus: int, storage_gib: int>, serverless: record<routing_id: string, upgrade_type: string, usage_limits: record>>, created_at: string, creator_id: string, customer_cloud_account: record<aws: record<arn: string>, azure: record<subscription_id: string, tenant_id: string>, gcp: record<service_account_email: string>>, delete_protection: string, deleted_at: string, egress_traffic_policy: string, id: string, labels: record, name: string, network_visibility: string, operation_status: string, parent_id: string, plan: string, regions: table<internal_dns: string, name: string, node_count: int, primary: bool, private_endpoint_dns: string, s3_vpc_endpoint_id: string, sql_dns: string, ui_dns: string>, sql_dns: string, state: string, updated_at: string, upgrade_status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/clusters")
  let body = {name: $name, provider: $provider, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the regions available for new clusters and nodes
#
# GET /api/v1/clusters/available-regions
# operationId: CockroachCloud_ListAvailableRegions
export def "clusters-available-regions ListAvailableRegions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --provider: string@provider-completer # Optional CloudProvider for filtering.   - GCP: The Google Cloud Platform cloud provider.  - AWS: The Amazon Web Services cloud provider.  - AZURE: The Azure cloud provider.
  --serverless: string@bool-completer # Optional filter to only show regions available for serverless clusters. (default: false)
  --paginationpage: string
  --paginationlimit: int # format: int32
  --paginationas-of-time: string # format: date-time
  --paginationsort-order: string@paginationsort-order-completer #  - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
]: nothing -> record<pagination: record<next_page: string, previous_page: string>, regions: table<distance: float, location: string, name: string, provider: string, serverless: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "provider" $provider "scalar") (serialize-qp "serverless" $serverless "scalar") (serialize-qp "pagination.page" $paginationpage "scalar") (serialize-qp "pagination.limit" $paginationlimit "scalar") (serialize-qp "pagination.as_of_time" $paginationas_of_time "scalar") (serialize-qp "pagination.sort_order" $paginationsort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/clusters/available-regions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a cluster and all of its data
#
# DELETE /api/v1/clusters/{cluster_id}
# operationId: CockroachCloud_DeleteCluster
export def "clusters DeleteCluster" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_id: string, azure_cluster_identity_client_id: string, cidr_range: string, cloud_provider: string, cockroach_version: string, config: record<dedicated: record<disk_iops: int, machine_type: string, memory_gib: float, num_virtual_cpus: int, storage_gib: int>, serverless: record<routing_id: string, upgrade_type: string, usage_limits: record>>, created_at: string, creator_id: string, customer_cloud_account: record<aws: record<arn: string>, azure: record<subscription_id: string, tenant_id: string>, gcp: record<service_account_email: string>>, delete_protection: string, deleted_at: string, egress_traffic_policy: string, id: string, labels: record, name: string, network_visibility: string, operation_status: string, parent_id: string, plan: string, regions: table<internal_dns: string, name: string, node_count: int, primary: bool, private_endpoint_dns: string, s3_vpc_endpoint_id: string, sql_dns: string, ui_dns: string>, sql_dns: string, state: string, updated_at: string, upgrade_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get extended information about a cluster
#
# GET /api/v1/clusters/{cluster_id}
# operationId: CockroachCloud_GetCluster
export def "clusters GetCluster" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_id: string, azure_cluster_identity_client_id: string, cidr_range: string, cloud_provider: string, cockroach_version: string, config: record<dedicated: record<disk_iops: int, machine_type: string, memory_gib: float, num_virtual_cpus: int, storage_gib: int>, serverless: record<routing_id: string, upgrade_type: string, usage_limits: record>>, created_at: string, creator_id: string, customer_cloud_account: record<aws: record<arn: string>, azure: record<subscription_id: string, tenant_id: string>, gcp: record<service_account_email: string>>, delete_protection: string, deleted_at: string, egress_traffic_policy: string, id: string, labels: record, name: string, network_visibility: string, operation_status: string, parent_id: string, plan: string, regions: table<internal_dns: string, name: string, node_count: int, primary: bool, private_endpoint_dns: string, s3_vpc_endpoint_id: string, sql_dns: string, ui_dns: string>, sql_dns: string, state: string, updated_at: string, upgrade_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Scale, edit or upgrade a cluster
#
# PATCH /api/v1/clusters/{cluster_id}
# operationId: CockroachCloud_UpdateCluster
# --dedicated shape: {cmek_region_specs?: list, hardware?: record, region_nodes?: record}
# --serverless shape: {primary_region?: string, regions?: list, upgrade_type?: "MANUAL"|"AUTOMATIC", usage_limits?: record}
export def "clusters UpdateCluster" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cockroach-version: string # The desired CockroachDB major version for the cluster.  It can be used to orchestrate version changes.  Setting the version to a later version will initiate an upgrade to that version.  After an upgrade is initiated but before it's finalized, setting the version back to the previous version will initiate a rollback.
  --dedicated: record # shape: {cmek_region_specs?: list, hardware?: record, region_nodes?: record}
  --delete-protection: string@delete-protection-completer
  --labels: record # labels are key-value pairs used to organize and categorize resources. If the labels field is included in the request: Any existing labels on the cluster that are not included will be removed, and any new labels specified will be added. If the labels field is omitted from the request entirely, all existing labels will remain unchanged.
  --parent-id: string # Preview: The parent ID is a folder ID. An empty string or "root" represents the root level.
  --plan: string@plan-completer #  - BASIC: The Basic plan includes essential operational features, is available in select regions, and offers on-demand capacity, making it ideal for small teams with unpredictable workloads.  - STANDARD: The Standard plan includes standard enterprise security and monitoring features, is available in all supported regions, and offers provisioned pricing, making it the default choice for most CockroachDB production workloads.  - ADVANCED: The Advanced plan is ideal for workloads with stringent isolation, compliance, and security requirements such as CMEK, PCI and HIPAA-readiness, and support for dedicated hardware. Customers are advised to have their account team and/or Cockroach Labs Support <support@cockroachlabs.com> involved when provisioning Advanced clusters.
  --serverless: record # shape: {primary_region?: string, regions?: list, upgrade_type?: "MANUAL"|"AUTOMATIC", usage_limits?: record}
  --upgrade-status: string@upgrade-status-completer #  - FINALIZED: The cluster is running the latest available CockroachDB version, and all upgrades have been finalized.  - MAJOR_UPGRADE_RUNNING: An major version upgrade is currently in progress.  - UPGRADE_AVAILABLE: An upgrade is available. If preview builds are enabled for the parent organization, this could indicate that a preview upgrade is available.  - PENDING_FINALIZATION: An upgrade is complete, but pending finalization. Upgrades are automatically finalized after 72 hours. For more information, see https://www.cockroachlabs.com/docs/stable/upgrade-cockroach-version.html  - ROLLBACK_RUNNING: A rollback operation is currently in progress.
]: any -> record<account_id: string, azure_cluster_identity_client_id: string, cidr_range: string, cloud_provider: string, cockroach_version: string, config: record<dedicated: record<disk_iops: int, machine_type: string, memory_gib: float, num_virtual_cpus: int, storage_gib: int>, serverless: record<routing_id: string, upgrade_type: string, usage_limits: record>>, created_at: string, creator_id: string, customer_cloud_account: record<aws: record<arn: string>, azure: record<subscription_id: string, tenant_id: string>, gcp: record<service_account_email: string>>, delete_protection: string, deleted_at: string, egress_traffic_policy: string, id: string, labels: record, name: string, network_visibility: string, operation_status: string, parent_id: string, plan: string, regions: table<internal_dns: string, name: string, node_count: int, primary: bool, private_endpoint_dns: string, s3_vpc_endpoint_id: string, sql_dns: string, ui_dns: string>, sql_dns: string, state: string, updated_at: string, upgrade_status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)")
  let body = {cockroach_version: $cockroach_version, dedicated: $dedicated, delete_protection: $delete_protection, labels: $labels, parent_id: $parent_id, plan: $plan, serverless: $serverless, upgrade_status: $upgrade_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List cluster backups
#
# GET /api/v1/clusters/{cluster_id}/backups
# operationId: CockroachCloud_ListBackups
export def "clusters-backups ListBackups" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --paginationpage: string
  --paginationlimit: int # format: int32
  --paginationas-of-time: string # format: date-time
  --paginationsort-order: string@paginationsort-order-completer #  - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
  --start-time: string # The beginning of the time range (inclusive) used to search for backups. (format: date-time)
  --end-time: string # The end of the time range (exclusive) used to search for backups. (format: date-time)
]: nothing -> record<backups: table<as_of_time: string, id: string>, pagination: record<next_page: string, previous_page: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagination.page" $paginationpage "scalar") (serialize-qp "pagination.limit" $paginationlimit "scalar") (serialize-qp "pagination.as_of_time" $paginationas_of_time "scalar") (serialize-qp "pagination.sort_order" $paginationsort_order "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/backups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the backup configuration for a cluster
#
# GET /api/v1/clusters/{cluster_id}/backups-config
# operationId: CockroachCloud_GetBackupConfiguration
export def "clusters-backups-config GetBackupConfiguration" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool, frequency_minutes: int, retention_days: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/backups-config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the backup configuration for a cluster
#
# PATCH /api/v1/clusters/{cluster_id}/backups-config
# operationId: CockroachCloud_UpdateBackupConfiguration
export def "clusters-backups-config UpdateBackupConfiguration" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Indicates whether backups are enabled.
  --frequency-minutes: int # How frequently in minutes that backups are taken, which will determine the [RPO](https://www.cockroachlabs.com/docs/stable/disaster-recovery-overview) of the cluster.  Valid values are [5, 10, 15, 30, 60, 240, 1440]. (format: int32)
  --retention-days: int # The number of days to retain backups for. Can only be set once, further changes require opening a support ticket. Valid values are [2, 7, 30, 90, 365]. (format: int32)
]: any -> record<enabled: bool, frequency_minutes: int, retention_days: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/backups-config")
  let body = {enabled: $enabled, frequency_minutes: $frequency_minutes, retention_days: $retention_days} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all blackout windows for a cluster
#
# GET /api/v1/clusters/{cluster_id}/blackout-windows
# operationId: CockroachCloud_ListBlackoutWindows
export def "clusters-blackout-windows ListBlackoutWindows" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --paginationpage: string
  --paginationlimit: int # format: int32
  --paginationas-of-time: string # format: date-time
  --paginationsort-order: string@paginationsort-order-completer #  - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
]: nothing -> record<blackout_windows: table<cluster_id: string, end_time: string, id: string, start_time: string>, pagination: record<next_page: string, previous_page: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagination.page" $paginationpage "scalar") (serialize-qp "pagination.limit" $paginationlimit "scalar") (serialize-qp "pagination.as_of_time" $paginationas_of_time "scalar") (serialize-qp "pagination.sort_order" $paginationsort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/blackout-windows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a blackout window for a cluster
#
# POST /api/v1/clusters/{cluster_id}/blackout-windows
# operationId: CockroachCloud_CreateBlackoutWindow
export def "clusters-blackout-windows CreateBlackoutWindow" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  end_time: string # The end time of the blackout window (UTC). Can be up to 14 days after the start time. Must not be more than three months after the current time. (format: date-time)
  start_time: string # The start time of the blackout window (UTC). Must be scheduled at least 7 days in advance. (format: date-time)
]: any -> record<cluster_id: string, end_time: string, id: string, start_time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/blackout-windows")
  let body = {end_time: $end_time, start_time: $start_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a blackout window for a cluster
#
# DELETE /api/v1/clusters/{cluster_id}/blackout-windows/{blackout_window_id}
# operationId: CockroachCloud_DeleteBlackoutWindow
export def "clusters-blackout-windows DeleteBlackoutWindow" [
  cluster_id: string
  blackout_window_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cluster_id: string, end_time: string, id: string, start_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/blackout-windows/($blackout_window_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a blackout window by its ID for a cluster
#
# GET /api/v1/clusters/{cluster_id}/blackout-windows/{blackout_window_id}
# operationId: CockroachCloud_GetBlackoutWindow
export def "clusters-blackout-windows GetBlackoutWindow" [
  cluster_id: string
  blackout_window_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cluster_id: string, end_time: string, id: string, start_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/blackout-windows/($blackout_window_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a blackout window for a cluster
#
# PATCH /api/v1/clusters/{cluster_id}/blackout-windows/{blackout_window_id}
# operationId: CockroachCloud_UpdateBlackoutWindow
export def "clusters-blackout-windows UpdateBlackoutWindow" [
  cluster_id: string
  blackout_window_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --end-time: string # Optional new UTC end time for the blackout window. Can be up to 14 days after the start time. Must not be more than three months after the current time. (format: date-time)
  --start-time: string # Optional new UTC start time for the blackout window. Must be scheduled at least 7 days in advance. (format: date-time)
]: any -> record<cluster_id: string, end_time: string, id: string, start_time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/blackout-windows/($blackout_window_id)")
  let body = {end_time: $end_time, start_time: $start_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Client CA Cert for a cluster
#
# DELETE /api/v1/clusters/{cluster_id}/client-ca-cert
# operationId: CockroachCloud_DeleteClientCACert
export def "clusters-client-ca-cert DeleteClientCACert" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, x509_pem_cert: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/client-ca-cert")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Client CA Cert information for a cluster
#
# GET /api/v1/clusters/{cluster_id}/client-ca-cert
# operationId: CockroachCloud_GetClientCACert
export def "clusters-client-ca-cert GetClientCACert" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, x509_pem_cert: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/client-ca-cert")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Client CA Cert for a cluster
#
# PATCH /api/v1/clusters/{cluster_id}/client-ca-cert
# operationId: CockroachCloud_UpdateClientCACert
export def "clusters-client-ca-cert UpdateClientCACert" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x509-pem-cert: string
]: any -> record<status: string, x509_pem_cert: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/client-ca-cert")
  let body = {x509_pem_cert: $x509_pem_cert} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set Client CA Cert for a cluster
#
# POST /api/v1/clusters/{cluster_id}/client-ca-cert
# operationId: CockroachCloud_SetClientCACert
export def "clusters-client-ca-cert SetClientCACert" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  x509_pem_cert: string
]: any -> record<status: string, x509_pem_cert: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/client-ca-cert")
  let body = {x509_pem_cert: $x509_pem_cert} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get CMEK-related information for a cluster
#
# GET /api/v1/clusters/{cluster_id}/cmek
# operationId: CockroachCloud_GetCMEKClusterInfo
export def "clusters-cmek GetCMEKClusterInfo" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<region_infos: table<key_infos: list, region: string, status: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/cmek")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the CMEK-related status for a cluster
#
# PATCH /api/v1/clusters/{cluster_id}/cmek
# operationId: CockroachCloud_UpdateCMEKStatus
export def "clusters-cmek UpdateCMEKStatus" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  action: string@action-completer # CMEKCustomerAction enumerates the actions a customer can take on a cluster that has been enabled for CMEK.
]: any -> record<region_infos: table<key_infos: list, region: string, status: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/cmek")
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable CMEK for a cluster
#
# POST /api/v1/clusters/{cluster_id}/cmek
# operationId: CockroachCloud_EnableCMEKSpec
# --region_specs item shape: {key_spec?: record, region?: string}
export def "clusters-cmek EnableCMEKSpec" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  region_specs: list # item shape: {key_spec?: record, region?: string}
]: any -> record<region_infos: table<key_infos: list, region: string, status: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/cmek")
  let body = {region_specs: $region_specs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable or update the CMEK spec for a cluster
#
# PUT /api/v1/clusters/{cluster_id}/cmek
# operationId: CockroachCloud_UpdateCMEKSpec
# --region_specs item shape: {key_spec?: record, region?: string}
export def "clusters-cmek UpdateCMEKSpec" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  region_specs: list # item shape: {key_spec?: record, region?: string}
]: any -> record<region_infos: table<key_infos: list, region: string, status: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/cmek")
  let body = {region_specs: $region_specs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a formatted generic connection string for a cluster
#
# GET /api/v1/clusters/{cluster_id}/connection-string
# operationId: CockroachCloud_GetConnectionString
export def "clusters-connection-string GetConnectionString" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --database: string # default: defaultdb
  --sql-user: string
  --os: string@os-completer # os indicates the target operating system, used with formatting the default SSL certificate path. Required only for dedicated clusters.
]: nothing -> record<connection_string: string, params: record<Database: string, Host: string, Port: string, Username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "database" $database "scalar") (serialize-qp "sql_user" $sql_user "scalar") (serialize-qp "os" $os "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/connection-string" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List databases for a cluster
#
# GET /api/v1/clusters/{cluster_id}/databases
# operationId: CockroachCloud_ListDatabases
export def "clusters-databases ListDatabases" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --paginationpage: string
  --paginationlimit: int # format: int32
  --paginationas-of-time: string # format: date-time
  --paginationsort-order: string@paginationsort-order-completer #  - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
]: nothing -> record<databases: table<name: string, table_count: string>, pagination: record<next_page: string, previous_page: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagination.page" $paginationpage "scalar") (serialize-qp "pagination.limit" $paginationlimit "scalar") (serialize-qp "pagination.as_of_time" $paginationas_of_time "scalar") (serialize-qp "pagination.sort_order" $paginationsort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/databases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a database
#
# PATCH /api/v1/clusters/{cluster_id}/databases
# operationId: CockroachCloud_EditDatabase2
export def "clusters-databases EditDatabase2" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  new_name: string
]: any -> record<name: string, table_count: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/databases")
  let body = {name: $name, new_name: $new_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new database
#
# POST /api/v1/clusters/{cluster_id}/databases
# operationId: CockroachCloud_CreateDatabase
export def "clusters-databases CreateDatabase" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> record<name: string, table_count: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/databases")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a database
#
# DELETE /api/v1/clusters/{cluster_id}/databases/{name}
# operationId: CockroachCloud_DeleteDatabase
export def "clusters-databases DeleteDatabase" [
  cluster_id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, table_count: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/databases/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a database
#
# PATCH /api/v1/clusters/{cluster_id}/databases/{name}
# operationId: CockroachCloud_EditDatabase
export def "clusters-databases EditDatabase" [
  cluster_id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  new_name: string
]: any -> record<name: string, table_count: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/databases/($name)")
  let body = {new_name: $new_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get disruption specifications for a cluster
#
# GET /api/v1/clusters/{cluster_id}/disrupt
# operationId: CockroachCloud_GetClusterDisruptionInfo
export def "clusters-disrupt GetClusterDisruptionInfo" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<regional_disruptor_specifications: table<azs: list, is_whole_region: bool, pods: list, region_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/disrupt")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update disruption specifications for a cluster
#
# PUT /api/v1/clusters/{cluster_id}/disrupt
# operationId: CockroachCloud_UpdateClusterDisruption
# --regional_disruptor_specifications item shape: {azs?: list, is_whole_region: bool, pods?: list, region_code: string}
export def "clusters-disrupt UpdateClusterDisruption" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --regional-disruptor-specifications: list # regional_disruptor_specifications specify how regions are to be disrupted. Any Cluster region that is not specified here will not be disrupted. A cluster region that was previously disrupted but is not listed here will be removed from disruption. To stop all disruptions, set this to an empty list or omit it from the request. — item shape: {azs?: list, is_whole_region: bool, pods?: list, region_code: string}
]: any -> record<regional_disruptor_specifications: table<azs: list, is_whole_region: bool, pods: list, region_code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/disrupt")
  let body = {regional_disruptor_specifications: $regional_disruptor_specifications} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the Log Export configuration for a cluster
#
# DELETE /api/v1/clusters/{cluster_id}/logexport
# operationId: CockroachCloud_DeleteLogExport
export def "clusters-logexport DeleteLogExport" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cluster_id: string, created_at: string, spec: record<auth_principal: string, aws_external_id: string, azure_shared_key: string, groups: list<record>, log_name: string, omitted_channels: list<string>, redact: bool, region: string, type: string>, status: string, updated_at: string, user_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/logexport")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the Log Export configuration for a cluster
#
# GET /api/v1/clusters/{cluster_id}/logexport
# operationId: CockroachCloud_GetLogExportInfo
export def "clusters-logexport GetLogExportInfo" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cluster_id: string, created_at: string, spec: record<auth_principal: string, aws_external_id: string, azure_shared_key: string, groups: list<record>, log_name: string, omitted_channels: list<string>, redact: bool, region: string, type: string>, status: string, updated_at: string, user_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/logexport")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update the Log Export configuration for a cluster
#
# POST /api/v1/clusters/{cluster_id}/logexport
# operationId: CockroachCloud_EnableLogExport
# --groups item shape: {channels: list, enable_sending_queue?: bool, log_name: string, min_level?: "UNSPECIFIED"|"WARNING"|"ERROR"|"FATAL", redact?: bool}
export def "clusters-logexport EnableLogExport" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  auth_principal: string
  --aws-external-id: string # aws_external_id to include when assuming the IAM role specified by role_arn. Optional. A specific value may be required by the role's trust policy. Only supported for Advanced clusters on AWS. If provided for a Standard cluster, the request is rejected.
  --azure-shared-key: string # The primary or the secondary connected sources client authentication key. This is used to export logs to Azure Log Analytics.
  --groups: list # groups is a collection of log group configurations that allows the customer to define collections of CRDB log channels that are aggregated separately at the target sink. — item shape: {channels: list, enable_sending_queue?: bool, log_name: string, min_level?: "UNSPECIFIED"|"WARNING"|"ERROR"|"FATAL", redact?: bool}
  log_name: string # log_name is an identifier for the logs in the customer's log sink.
  --omitted-channels: list # omitted_channels is a list of channels that the user does not want to export logs for.
  --redact: string@bool-completer # redact allows the customer to set a default redaction policy for logs before they are exported to the target sink. If a group config omits a redact flag and this one is set to `true`, then that group will receive redacted logs.
  --region: string # region allows the customer to override the destination region for all logs for a cluster.
  type: string@type-completer # LogExportType encodes the cloud selection that we're exporting to along with the cloud logging platform.  Currently, each cloud has a single logging platform.
]: any -> record<cluster_id: string, created_at: string, spec: record<auth_principal: string, aws_external_id: string, azure_shared_key: string, groups: list<record>, log_name: string, omitted_channels: list<string>, redact: bool, region: string, type: string>, status: string, updated_at: string, user_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/logexport")
  let body = {auth_principal: $auth_principal, aws_external_id: $aws_external_id, azure_shared_key: $azure_shared_key, groups: $groups, log_name: $log_name, omitted_channels: $omitted_channels, redact: $redact, region: $region, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the maintenance window for a cluster
#
# DELETE /api/v1/clusters/{cluster_id}/maintenance-window
# operationId: CockroachCloud_DeleteMaintenanceWindow
export def "clusters-maintenance-window DeleteMaintenanceWindow" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<offset_duration: string, window_duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/maintenance-window")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the maintenance window for a cluster
#
# GET /api/v1/clusters/{cluster_id}/maintenance-window
# operationId: CockroachCloud_GetMaintenanceWindow
export def "clusters-maintenance-window GetMaintenanceWindow" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<offset_duration: string, window_duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/maintenance-window")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the maintenance window for a cluster
#
# PUT /api/v1/clusters/{cluster_id}/maintenance-window
# operationId: CockroachCloud_SetMaintenanceWindow
export def "clusters-maintenance-window SetMaintenanceWindow" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  offset_duration: string # OffsetDuration is the duration from the start of a week (Monday 00:00 UTC) that this maintenance window will start after.  Must be less than 1 week.
  window_duration: string # WindowDuration is the duration of the maintenance window.  Must be at least 6 hours and less than 1 week.
]: any -> record<offset_duration: string, window_duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/maintenance-window")
  let body = {offset_duration: $offset_duration, window_duration: $window_duration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the CloudWatch Metric Export configuration for a cluster
#
# DELETE /api/v1/clusters/{cluster_id}/metricexport/cloudwatch
# operationId: CockroachCloud_DeleteCloudWatchMetricExport
export def "clusters-metricexport-cloudwatch DeleteCloudWatchMetricExport" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cluster_id: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/metricexport/cloudwatch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the CloudWatch Metric Export configuration for a cluster
#
# GET /api/v1/clusters/{cluster_id}/metricexport/cloudwatch
# operationId: CockroachCloud_GetCloudWatchMetricExportInfo
export def "clusters-metricexport-cloudwatch GetCloudWatchMetricExportInfo" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cluster_id: string, external_id: string, log_group_name: string, role_arn: string, status: string, target_region: string, user_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/metricexport/cloudwatch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update the CloudWatch Metric Export configuration for a cluster
#
# POST /api/v1/clusters/{cluster_id}/metricexport/cloudwatch
# operationId: CockroachCloud_EnableCloudWatchMetricExport
export def "clusters-metricexport-cloudwatch EnableCloudWatchMetricExport" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --external-id: string # external_id to include when assuming the IAM role specified by role_arn. Optional. A specific value may be required by the role's trust policy. Only supported for Advanced clusters. If provided for a Standard cluster, the request is rejected.
  --log-group-name: string # log_group_name is the customized log group name.
  role_arn: string # role_arn is the IAM role used to upload metric segments to the target AWS account.
  --target-region: string # target_region specifies the specific AWS region that the metrics will be exported to.
]: any -> record<cluster_id: string, external_id: string, log_group_name: string, role_arn: string, status: string, target_region: string, user_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/metricexport/cloudwatch")
  let body = {external_id: $external_id, log_group_name: $log_group_name, role_arn: $role_arn, target_region: $target_region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the Datadog Metric Export configuration for a cluster
#
# DELETE /api/v1/clusters/{cluster_id}/metricexport/datadog
# operationId: CockroachCloud_DeleteDatadogMetricExport
export def "clusters-metricexport-datadog DeleteDatadogMetricExport" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cluster_id: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/metricexport/datadog")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the Datadog Metric Export configuration for a cluster
#
# GET /api/v1/clusters/{cluster_id}/metricexport/datadog
# operationId: CockroachCloud_GetDatadogMetricExportInfo
export def "clusters-metricexport-datadog GetDatadogMetricExportInfo" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<api_key: string, cluster_id: string, site: string, status: string, user_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/metricexport/datadog")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update the Datadog Metric Export configuration for a cluster
#
# POST /api/v1/clusters/{cluster_id}/metricexport/datadog
# operationId: CockroachCloud_EnableDatadogMetricExport
export def "clusters-metricexport-datadog EnableDatadogMetricExport" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  api_key: string # api_key is a Datadog API key.
  site: string@site-completer
]: any -> record<api_key: string, cluster_id: string, site: string, status: string, user_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/metricexport/datadog")
  let body = {api_key: $api_key, site: $site} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disable Prometheus Metric Export for a cluster
#
# DELETE /api/v1/clusters/{cluster_id}/metricexport/prometheus
# operationId: CockroachCloud_DeletePrometheusMetricExport
export def "clusters-metricexport-prometheus DeletePrometheusMetricExport" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cluster_id: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/metricexport/prometheus")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the Prometheus Metric Export configuration for a cluster
#
# GET /api/v1/clusters/{cluster_id}/metricexport/prometheus
# operationId: CockroachCloud_GetPrometheusMetricExportInfo
export def "clusters-metricexport-prometheus GetPrometheusMetricExportInfo" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cluster_id: string, status: string, targets: record, user_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/metricexport/prometheus")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Prometheus Metric Export for a cluster
#
# POST /api/v1/clusters/{cluster_id}/metricexport/prometheus
# operationId: CockroachCloud_EnablePrometheusMetricExport
export def "clusters-metricexport-prometheus EnablePrometheusMetricExport" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cluster_id: string, status: string, targets: record, user_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/metricexport/prometheus")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the IP allowlist and propagation status for a cluster
#
# GET /api/v1/clusters/{cluster_id}/networking/allowlist
# operationId: CockroachCloud_ListAllowlistEntries
export def "clusters-networking-allowlist ListAllowlistEntries" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --paginationpage: string
  --paginationlimit: int # format: int32
  --paginationas-of-time: string # format: date-time
  --paginationsort-order: string@paginationsort-order-completer #  - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
]: nothing -> record<allowlist: table<cidr_ip: string, cidr_mask: int, name: string, sql: bool, ui: bool>, pagination: record<next_page: string, previous_page: string>, propagating: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagination.page" $paginationpage "scalar") (serialize-qp "pagination.limit" $paginationlimit "scalar") (serialize-qp "pagination.as_of_time" $paginationas_of_time "scalar") (serialize-qp "pagination.sort_order" $paginationsort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/allowlist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new CIDR address to the IP allowlist
#
# POST /api/v1/clusters/{cluster_id}/networking/allowlist
# operationId: CockroachCloud_AddAllowlistEntry
export def "clusters-networking-allowlist AddAllowlistEntry" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  cidr_ip: string
  cidr_mask: int # format: int32
  --name: string
  --sql: string@bool-completer
  --ui: string@bool-completer
]: any -> record<cidr_ip: string, cidr_mask: int, name: string, sql: bool, ui: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/allowlist")
  let body = {cidr_ip: $cidr_ip, cidr_mask: $cidr_mask, name: $name, sql: $sql, ui: $ui} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an IP allowlist entry
#
# DELETE /api/v1/clusters/{cluster_id}/networking/allowlist/{cidr_ip}/{cidr_mask}
# operationId: CockroachCloud_DeleteAllowlistEntry
export def "clusters-networking-allowlist DeleteAllowlistEntry" [
  cluster_id: string
  cidr_ip: string
  cidr_mask: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cidr_ip: string, cidr_mask: int, name: string, sql: bool, ui: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/allowlist/($cidr_ip)/($cidr_mask)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an IP allowlist entry
#
# PATCH /api/v1/clusters/{cluster_id}/networking/allowlist/{cidr_ip}/{cidr_mask}
# operationId: CockroachCloud_UpdateAllowlistEntry
export def "clusters-networking-allowlist UpdateAllowlistEntry" [
  cluster_id: string
  cidr_ip: string
  cidr_mask: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --sql: string@bool-completer
  --ui: string@bool-completer
]: any -> record<cidr_ip: string, cidr_mask: int, name: string, sql: bool, ui: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/allowlist/($cidr_ip)/($cidr_mask)")
  let body = {name: $name, sql: $sql, ui: $ui} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a new CIDR address to the IP allowlist
#
# PUT /api/v1/clusters/{cluster_id}/networking/allowlist/{cidr_ip}/{cidr_mask}
# operationId: CockroachCloud_AddAllowlistEntry2
export def "clusters-networking-allowlist AddAllowlistEntry2" [
  cluster_id: string
  cidr_ip: string
  cidr_mask: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --sql: string@bool-completer
  --ui: string@bool-completer
]: any -> record<cidr_ip: string, cidr_mask: int, name: string, sql: bool, ui: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/allowlist/($cidr_ip)/($cidr_mask)")
  let body = {name: $name, sql: $sql, ui: $ui} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all AwsEndpointConnections for a cluster
#
# GET /api/v1/clusters/{cluster_id}/networking/aws-endpoint-connections
# operationId: CockroachCloud_ListAwsEndpointConnections
export def "clusters-networking-aws-endpoint-connections ListAwsEndpointConnections" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<connections: table<cloud_provider: string, endpoint_id: string, external_owner_id: string, region_name: string, service_id: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/aws-endpoint-connections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the AWS Endpoint Connection state
#
# PATCH /api/v1/clusters/{cluster_id}/networking/aws-endpoint-connections/{endpoint_id}
# operationId: CockroachCloud_SetAwsEndpointConnectionState
export def "clusters-networking-aws-endpoint-connections SetAwsEndpointConnectionState" [
  cluster_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  status: string@status-completer #  - AVAILABLE: accept/verify the connection on the service side.  - REJECTED: reject the connection on the service side.
]: any -> record<cloud_provider: string, endpoint_id: string, external_owner_id: string, region_name: string, service_id: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/aws-endpoint-connections/($endpoint_id)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List egress private endpoints
#
# GET /api/v1/clusters/{cluster_id}/networking/egress-private-endpoints
# operationId: CockroachCloud_ListEgressPrivateEndpoints
export def "clusters-networking-egress-private-endpoints ListEgressPrivateEndpoints" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --paginationpage: string
  --paginationlimit: int # format: int32
  --paginationas-of-time: string # format: date-time
  --paginationsort-order: string@paginationsort-order-completer #  - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
]: nothing -> record<egress_private_endpoints: table<domain_names: list, domain_names_state: string, endpoint_address: string, endpoint_connection_id: string, id: string, region: string, state: string, target_service_identifier: string, target_service_type: string>, pagination: record<next_page: string, previous_page: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagination.page" $paginationpage "scalar") (serialize-qp "pagination.limit" $paginationlimit "scalar") (serialize-qp "pagination.as_of_time" $paginationas_of_time "scalar") (serialize-qp "pagination.sort_order" $paginationsort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/egress-private-endpoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an egress private endpoint
#
# POST /api/v1/clusters/{cluster_id}/networking/egress-private-endpoints
# operationId: CockroachCloud_CreateEgressPrivateEndpoint
export def "clusters-networking-egress-private-endpoints CreateEgressPrivateEndpoint" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  region: string # region represents the region that the endpoint will be created in.
  target_service_identifier: string # target_service_identifier represents the identifier of the target service. User-visible in CRL and CSP consoles as the "thing" the user is telling us to connect to, i.e. Service Name for AWS, Service Attachment for GCP, or ARN for AWS MSK.
  target_service_type: string@target-service-type-completer
]: any -> record<domain_names: list<string>, domain_names_state: string, endpoint_address: string, endpoint_connection_id: string, id: string, region: string, state: string, target_service_identifier: string, target_service_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/egress-private-endpoints")
  let body = {region: $region, target_service_identifier: $target_service_identifier, target_service_type: $target_service_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an egress private endpoint
#
# DELETE /api/v1/clusters/{cluster_id}/networking/egress-private-endpoints/{id}
# operationId: CockroachCloud_DeleteEgressPrivateEndpoint
export def "clusters-networking-egress-private-endpoints DeleteEgressPrivateEndpoint" [
  cluster_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/egress-private-endpoints/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get egress private endpoint
#
# GET /api/v1/clusters/{cluster_id}/networking/egress-private-endpoints/{id}
# operationId: CockroachCloud_GetEgressPrivateEndpoint
export def "clusters-networking-egress-private-endpoints GetEgressPrivateEndpoint" [
  cluster_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<domain_names: list<string>, domain_names_state: string, endpoint_address: string, endpoint_connection_id: string, id: string, region: string, state: string, target_service_identifier: string, target_service_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/egress-private-endpoints/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update egress private endpoint.
#
# PATCH /api/v1/clusters/{cluster_id}/networking/egress-private-endpoints/{id}
# operationId: CockroachCloud_UpdateEgressPrivateEndpoint
export def "clusters-networking-egress-private-endpoints UpdateEgressPrivateEndpoint" [
  cluster_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain_names: list # domain_names are the domain names to associate with the egress private endpoint.
]: any -> record<domain_names: list<string>, domain_names_state: string, endpoint_address: string, endpoint_connection_id: string, id: string, region: string, state: string, target_service_identifier: string, target_service_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/egress-private-endpoints/($id)")
  let body = {domain_names: $domain_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update egress private endpoint domain names. This endpoint is deprecated in favor of PATCH /api/v1/clusters/{cluster_id}/networking/egress-private-endpoints/{id} and will be removed in a future version.
#
# PATCH /api/v1/clusters/{cluster_id}/networking/egress-private-endpoints/{id}/domain-names
# DEPRECATED
# operationId: CockroachCloud_UpdateEgressPrivateEndpointDomainNames
@deprecated
export def "clusters-networking-egress-private-endpoints-domain-names UpdateEgressPrivateEndpointDomainNames" [
  cluster_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain_names: list # domain_names are the domain names to associate with the egress private endpoint.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/egress-private-endpoints/($id)/domain-names")
  let body = {domain_names: $domain_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all egress rules associated with a cluster
#
# GET /api/v1/clusters/{cluster_id}/networking/egress-rules
# operationId: CockroachCloud_ListEgressRules
export def "clusters-networking-egress-rules ListEgressRules" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --paginationpage: string
  --paginationlimit: int # format: int32
  --paginationas-of-time: string # format: date-time
  --paginationsort-order: string@paginationsort-order-completer #  - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
]: nothing -> record<pagination: record<next_page: string, previous_page: string>, rules: table<cluster_id: string, created_at: string, crl_managed: bool, description: string, destination: string, id: string, name: string, paths: list, ports: list, state: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagination.page" $paginationpage "scalar") (serialize-qp "pagination.limit" $paginationlimit "scalar") (serialize-qp "pagination.as_of_time" $paginationas_of_time "scalar") (serialize-qp "pagination.sort_order" $paginationsort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/egress-rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an egress rule
#
# POST /api/v1/clusters/{cluster_id}/networking/egress-rules
# operationId: CockroachCloud_AddEgressRule
export def "clusters-networking-egress-rules AddEgressRule" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string # description is text that serves to document the rules purpose.
  destination: string # destination is the endpoint (or subnetwork if CIDR) to which traffic is allowed.
  --idempotency-key: string # idempotency_key uniquely identifies this request. If not set, it will be set by the server.
  name: string # name is the name of the egress rule.
  --paths: list # Deprecated: This field is ignored and will be removed in the next version. paths are the allowed URL paths. If empty, all paths are allowed. Only valid if Type="FQDN".
  --ports: list # ports are the allowed ports for TCP protocol. If Empty, all ports are allowed.
  type: string # type classifies the Destination field. Valid types include: "FQDN", "CIDR".
]: any -> record<Rule: record<cluster_id: string, created_at: string, crl_managed: bool, description: string, destination: string, id: string, name: string, paths: list<string>, ports: list<int>, state: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/egress-rules")
  let body = {description: $description, destination: $destination, idempotency_key: $idempotency_key, name: $name, paths: $paths, ports: $ports, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Outbound traffic management
#
# POST /api/v1/clusters/{cluster_id}/networking/egress-rules/egress-traffic-policy
# operationId: CockroachCloud_SetEgressTrafficPolicy
export def "clusters-networking-egress-rules-egress-traffic-policy SetEgressTrafficPolicy" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allow-all: string@bool-completer # allow_all, if true results in unrestricted egress traffic. If false, egress traffic is set to default-deny and is managed via the Egress Rule Management API.
  --idempotency-key: string # idempotency_key uniquely identifies this request. If not set, it will be set by the server.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/egress-rules/egress-traffic-policy")
  let body = {allow_all: $allow_all, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an existing egress rule
#
# DELETE /api/v1/clusters/{cluster_id}/networking/egress-rules/{rule_id}
# operationId: CockroachCloud_DeleteEgressRule
export def "clusters-networking-egress-rules DeleteEgressRule" [
  cluster_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # idempotency_key uniquely identifies this request. If not set, it will be set by the server.
]: nothing -> record<Rule: record<cluster_id: string, created_at: string, crl_managed: bool, description: string, destination: string, id: string, name: string, paths: list<string>, ports: list<int>, state: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "idempotency_key" $idempotency_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/egress-rules/($rule_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an existing egress rule
#
# GET /api/v1/clusters/{cluster_id}/networking/egress-rules/{rule_id}
# operationId: CockroachCloud_GetEgressRule
export def "clusters-networking-egress-rules GetEgressRule" [
  cluster_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<rule: record<cluster_id: string, created_at: string, crl_managed: bool, description: string, destination: string, id: string, name: string, paths: list<string>, ports: list<int>, state: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/egress-rules/($rule_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit an existing egress rule
#
# PATCH /api/v1/clusters/{cluster_id}/networking/egress-rules/{rule_id}
# operationId: CockroachCloud_EditEgressRule
export def "clusters-networking-egress-rules EditEgressRule" [
  cluster_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # description is text that serves to document the rules purpose.
  --destination: string # destination is a CIDR range or fully-qualified domain name to which outgoing traffic should be allowed. This field is required.
  --idempotency-key: string # idempotency_key uniquely identifies this request. If not set, it will be set by the server.
  --paths: list # Deprecated: This field is ignored and will be removed in the next version. paths are the allowed URL paths. If empty, all paths are allowed. Only valid if Type="FQDN".
  --ports: list # ports are the allowed ports for TCP protocol. If empty, all ports are allowed.
  --type: string # type is the destination type of this rule. Example values are FQDN or CIDR. This field is required.
]: any -> record<Rule: record<cluster_id: string, created_at: string, crl_managed: bool, description: string, destination: string, id: string, name: string, paths: list<string>, ports: list<int>, state: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/egress-rules/($rule_id)")
  let body = {description: $description, destination: $destination, idempotency_key: $idempotency_key, paths: $paths, ports: $ports, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all connections to a cluster's private endpoint service.
#
# GET /api/v1/clusters/{cluster_id}/networking/private-endpoint-connections
# operationId: CockroachCloud_ListPrivateEndpointConnections
export def "clusters-networking-private-endpoint-connections ListPrivateEndpointConnections" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<connections: table<cloud_provider: string, endpoint_id: string, endpoint_service_id: string, external_owner_id: string, region_name: string, service_name: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/private-endpoint-connections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a connection to a cluster's private endpoint service.
#
# POST /api/v1/clusters/{cluster_id}/networking/private-endpoint-connections
# operationId: CockroachCloud_AddPrivateEndpointConnection
export def "clusters-networking-private-endpoint-connections AddPrivateEndpointConnection" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  endpoint_id: string # endpoint_id is the id of the private endpoint associated with a cluster's private endpoint service. The private endpoint is customer-created and its id is generated by the cloud provider at endpoint creation time.
]: any -> record<cloud_provider: string, endpoint_id: string, endpoint_service_id: string, external_owner_id: string, region_name: string, service_name: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/private-endpoint-connections")
  let body = {endpoint_id: $endpoint_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a connection from a cluster's private endpoint service.
#
# DELETE /api/v1/clusters/{cluster_id}/networking/private-endpoint-connections/{endpoint_id}
# operationId: CockroachCloud_DeletePrivateEndpointConnection
export def "clusters-networking-private-endpoint-connections DeletePrivateEndpointConnection" [
  cluster_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/private-endpoint-connections/($endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all PrivateEndpointServices for a cluster
#
# GET /api/v1/clusters/{cluster_id}/networking/private-endpoint-services
# operationId: CockroachCloud_ListPrivateEndpointServices
export def "clusters-networking-private-endpoint-services ListPrivateEndpointServices" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<services: table<availability_zone_ids: list, aws: record, cloud_provider: string, endpoint_service_id: string, name: string, region_name: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/private-endpoint-services")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create all PrivateEndpointServices for a cluster
#
# POST /api/v1/clusters/{cluster_id}/networking/private-endpoint-services
# operationId: CockroachCloud_CreatePrivateEndpointServices
export def "clusters-networking-private-endpoint-services CreatePrivateEndpointServices" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<services: table<availability_zone_ids: list, aws: record, cloud_provider: string, endpoint_service_id: string, name: string, region_name: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/private-endpoint-services")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all private endpoint trusted owners for a cluster
#
# GET /api/v1/clusters/{cluster_id}/networking/private-endpoint-trusted-owners
# operationId: CockroachCloud_ListPrivateEndpointTrustedOwners
export def "clusters-networking-private-endpoint-trusted-owners ListPrivateEndpointTrustedOwners" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<trusted_owners: table<cluster_id: string, created_at: string, external_owner_id: string, id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/private-endpoint-trusted-owners")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a private endpoint trusted owner to a cluster
#
# POST /api/v1/clusters/{cluster_id}/networking/private-endpoint-trusted-owners
# operationId: CockroachCloud_AddPrivateEndpointTrustedOwner
export def "clusters-networking-private-endpoint-trusted-owners AddPrivateEndpointTrustedOwner" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  external_owner_id: string # external_owner_id is the identifier of the owner within the cloud provider for private endpoint connections. A wildcard character ("*") can be used to denote all owners.
  type: string@type-completer-1 #  - AWS_ACCOUNT_ID: AWS_ACCOUNT_ID represents the 12-digit AWS account number.
]: any -> record<trusted_owner: record<cluster_id: string, created_at: string, external_owner_id: string, id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/private-endpoint-trusted-owners")
  let body = {external_owner_id: $external_owner_id, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a private endpoint trusted owner from a cluster
#
# DELETE /api/v1/clusters/{cluster_id}/networking/private-endpoint-trusted-owners/{owner_id}
# operationId: CockroachCloud_RemovePrivateEndpointTrustedOwner
export def "clusters-networking-private-endpoint-trusted-owners RemovePrivateEndpointTrustedOwner" [
  cluster_id: string
  owner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<trusted_owner: record<cluster_id: string, created_at: string, external_owner_id: string, id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/private-endpoint-trusted-owners/($owner_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a private endpoint trusted owner entry for a cluster
#
# GET /api/v1/clusters/{cluster_id}/networking/private-endpoint-trusted-owners/{owner_id}
# operationId: CockroachCloud_GetPrivateEndpointTrustedOwner
export def "clusters-networking-private-endpoint-trusted-owners GetPrivateEndpointTrustedOwner" [
  cluster_id: string
  owner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<trusted_owner: record<cluster_id: string, created_at: string, external_owner_id: string, id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/networking/private-endpoint-trusted-owners/($owner_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List nodes for a cluster
#
# GET /api/v1/clusters/{cluster_id}/nodes
# operationId: CockroachCloud_ListClusterNodes
export def "clusters-nodes ListClusterNodes" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region-name: string # Optional filter to limit response to a single region.
  --paginationpage: string
  --paginationlimit: int # format: int32
  --paginationas-of-time: string # format: date-time
  --paginationsort-order: string@paginationsort-order-completer #  - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
]: nothing -> record<nodes: table<name: string, region_name: string, status: string>, pagination: record<next_page: string, previous_page: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region_name" $region_name "scalar") (serialize-qp "pagination.page" $paginationpage "scalar") (serialize-qp "pagination.limit" $paginationlimit "scalar") (serialize-qp "pagination.as_of_time" $paginationas_of_time "scalar") (serialize-qp "pagination.sort_order" $paginationsort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/nodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List restore jobs
#
# GET /api/v1/clusters/{cluster_id}/restores
# operationId: CockroachCloud_ListRestores
export def "clusters-restores ListRestores" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --paginationpage: string
  --paginationlimit: int # format: int32
  --paginationas-of-time: string # format: date-time
  --paginationsort-order: string@paginationsort-order-completer #  - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
  --start-time: string # The beginning of the time range (inclusive) used to search for restores. (format: date-time)
  --end-time: string # The end of the time range (exclusive) used to search for restores. (format: date-time)
]: nothing -> record<pagination: record<next_page: string, previous_page: string>, restores: table<backup_end_time: string, backup_id: string, client_error_code: int, client_error_message: string, completed_at: string, completion_percent: float, crdb_job_id: string, created_at: string, destination_cluster_name: string, id: string, objects: list, restore_opts: record, source_cluster_name: string, status: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagination.page" $paginationpage "scalar") (serialize-qp "pagination.limit" $paginationlimit "scalar") (serialize-qp "pagination.as_of_time" $paginationas_of_time "scalar") (serialize-qp "pagination.sort_order" $paginationsort_order "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/restores" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View a restore job
#
# GET /api/v1/clusters/{cluster_id}/restores/{restore_id}
# operationId: CockroachCloud_GetRestore
export def "clusters-restores GetRestore" [
  cluster_id: string
  restore_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<backup_end_time: string, backup_id: string, client_error_code: int, client_error_message: string, completed_at: string, completion_percent: float, crdb_job_id: string, created_at: string, destination_cluster_name: string, id: string, objects: table<database: string, schema: string, table: string>, restore_opts: record<into_db: string, new_db_name: string, schema_only: bool, skip_localities_check: bool, skip_missing_foreign_keys: bool, skip_missing_sequences: bool, skip_missing_views: bool>, source_cluster_name: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/restores/($restore_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List SQL users for a cluster
#
# GET /api/v1/clusters/{cluster_id}/sql-users
# operationId: CockroachCloud_ListSQLUsers
export def "clusters-sql-users ListSQLUsers" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --paginationpage: string
  --paginationlimit: int # format: int32
  --paginationas-of-time: string # format: date-time
  --paginationsort-order: string@paginationsort-order-completer #  - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
]: nothing -> record<pagination: record<next_page: string, previous_page: string>, users: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagination.page" $paginationpage "scalar") (serialize-qp "pagination.limit" $paginationlimit "scalar") (serialize-qp "pagination.as_of_time" $paginationas_of_time "scalar") (serialize-qp "pagination.sort_order" $paginationsort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/sql-users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new SQL user
#
# POST /api/v1/clusters/{cluster_id}/sql-users
# operationId: CockroachCloud_CreateSQLUser
export def "clusters-sql-users CreateSQLUser" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  password: string
]: any -> record<name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/sql-users")
  let body = {name: $name, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a SQL user
#
# DELETE /api/v1/clusters/{cluster_id}/sql-users/{name}
# operationId: CockroachCloud_DeleteSQLUser
export def "clusters-sql-users DeleteSQLUser" [
  cluster_id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/sql-users/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a SQL user's password
#
# PUT /api/v1/clusters/{cluster_id}/sql-users/{name}/password
# operationId: CockroachCloud_UpdateSQLUserPassword
export def "clusters-sql-users-password UpdateSQLUserPassword" [
  cluster_id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  password: string
]: any -> record<name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/sql-users/($name)/password")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the version upgrade deferral policy for a cluster.
#
# GET /api/v1/clusters/{cluster_id}/version-deferral
# operationId: CockroachCloud_GetClusterVersionDeferral
export def "clusters-version-deferral GetClusterVersionDeferral" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deferral_policy: string, deferred_until: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/version-deferral")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the version upgrade deferral policy for a cluster
#
# PUT /api/v1/clusters/{cluster_id}/version-deferral
# operationId: CockroachCloud_SetClusterVersionDeferral
export def "clusters-version-deferral SetClusterVersionDeferral" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  deferral_policy: string@deferral-policy-completer #  - NOT_DEFERRED: automatic patch version upgrades are applied immediately after release.  - DEFERRAL_60_DAYS: automatic patch version upgrades are applied in a maintenance window at least 60 days after the patch version release date.  - FIXED_DEFERRAL: Deprecated: FIXED_DEFERRAL is equivalent to DEFERRAL_60_DAYS. It will be removed in a future version.  - DEFERRAL_30_DAYS: automatic patch version upgrades are applied in a maintenance window at least 30 days after the patch version release date.  - DEFERRAL_90_DAYS: automatic patch version upgrades are applied in a maintenance window at least 90 days after the patch version release date.
  --deferred-until: string # Deprecated: This field is ignored and will be removed in a future version. (format: date-time)
]: any -> record<deferral_policy: string, deferred_until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($cluster_id)/version-deferral")
  let body = {deferral_policy: $deferral_policy, deferred_until: $deferred_until} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a restore
#
# POST /api/v1/clusters/{destination_cluster_id}/restores
# operationId: CockroachCloud_CreateRestore
# --objects item shape: {database: string, schema?: string, table?: string}
# --restore_opts shape: {into_db?: string, new_db_name?: string, schema_only?: bool, skip_localities_check?: bool, skip_missing_foreign_keys?: bool, skip_missing_sequences?: bool, skip_missing_views?: bool}
export def "clusters-restores CreateRestore" [
  destination_cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --backup-id: string # The ID of the backup from which data will be restored. If backup_id is not set, the restore will use the latest available backup from source_cluster_id.
  --objects: list # The list of objects to restore. Required when type is DATABASE or TABLE. — item shape: {database: string, schema?: string, table?: string}
  --restore-opts: record # shape: {into_db?: string, new_db_name?: string, schema_only?: bool, skip_localities_check?: bool, skip_missing_foreign_keys?: bool, skip_missing_sequences?: bool, skip_missing_views?: bool}
  --source-cluster-id: string # The ID of the cluster containing the backup to be restored.
  type: string@type-completer-2
]: any -> record<backup_end_time: string, backup_id: string, client_error_code: int, client_error_message: string, completed_at: string, completion_percent: float, crdb_job_id: string, created_at: string, destination_cluster_name: string, id: string, objects: table<database: string, schema: string, table: string>, restore_opts: record<into_db: string, new_db_name: string, schema_only: bool, skip_localities_check: bool, skip_missing_foreign_keys: bool, skip_missing_sequences: bool, skip_missing_views: bool>, source_cluster_name: string, status: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($destination_cluster_id)/restores")
  let body = {backup_id: $backup_id, objects: $objects, restore_opts: $restore_opts, source_cluster_id: $source_cluster_id, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List folders owned by an organization
#
# GET /api/v1/folders
# operationId: CockroachCloud_ListFolders
export def "folders ListFolders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: string # Optional filter to limit the response to include only results that match the given absolute path to that folder. Preceding and ending "/" are optional. For example /folder1/folder2, /folder1/folder2/, folder1/folder2, and folder1/folder2/ are all equivalent. If no matching folder is found, an empty list is returned. Because folder paths are passed via the query parameters, they must be URL-encoded.
  --paginationpage: string
  --paginationlimit: int # format: int32
  --paginationas-of-time: string # format: date-time
  --paginationsort-order: string@paginationsort-order-completer #  - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
]: nothing -> record<folders: table<labels: record, name: string, organization_id: string, parent_id: string, path: list, resource_id: string, resource_type: string>, pagination: record<next_page: string, previous_page: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "pagination.page" $paginationpage "scalar") (serialize-qp "pagination.limit" $paginationlimit "scalar") (serialize-qp "pagination.as_of_time" $paginationas_of_time "scalar") (serialize-qp "pagination.sort_order" $paginationsort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/folders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a folder
#
# POST /api/v1/folders
# operationId: CockroachCloud_CreateFolder
export def "folders CreateFolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labels: record # labels are key-value pairs used to organize and categorize resources.
  name: string
  --parent-id: string # The parent ID is a folder ID. An empty string or "root" will create a folder at the root level.
]: any -> record<labels: record, name: string, organization_id: string, parent_id: string, path: table<id: string, name: string>, resource_id: string, resource_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/folders")
  let body = {labels: $labels, name: $name, parent_id: $parent_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a folder
#
# DELETE /api/v1/folders/{folder_id}
# operationId: CockroachCloud_DeleteFolder
export def "folders DeleteFolder" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/folders/($folder_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get folder info for a folder
#
# GET /api/v1/folders/{folder_id}
# operationId: CockroachCloud_GetFolder
export def "folders GetFolder" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<labels: record, name: string, organization_id: string, parent_id: string, path: table<id: string, name: string>, resource_id: string, resource_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/folders/($folder_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a folder
#
# PATCH /api/v1/folders/{folder_id}
# operationId: CockroachCloud_UpdateFolder
export def "folders UpdateFolder" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labels: record # labels are key-value pairs used to organize and categorize resources. If the labels field is included in the request: Any existing labels on the folder that are not included will be removed, and any new labels specified will be added. If the labels field is omitted from the request entirely, all existing labels will remain unchanged.
  --name: string
  --parent-id: string
]: any -> record<labels: record, name: string, organization_id: string, parent_id: string, path: table<id: string, name: string>, resource_id: string, resource_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/folders/($folder_id)")
  let body = {labels: $labels, name: $name, parent_id: $parent_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List contents of a folder
#
# GET /api/v1/folders/{folder_id}/contents
# operationId: CockroachCloud_ListFolderContents
export def "folders-contents ListFolderContents" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --paginationpage: string
  --paginationlimit: int # format: int32
  --paginationas-of-time: string # format: date-time
  --paginationsort-order: string@paginationsort-order-completer #  - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
]: nothing -> record<pagination: record<next_page: string, previous_page: string>, resources: table<labels: record, name: string, organization_id: string, parent_id: string, path: list, resource_id: string, resource_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagination.page" $paginationpage "scalar") (serialize-qp "pagination.limit" $paginationlimit "scalar") (serialize-qp "pagination.as_of_time" $paginationas_of_time "scalar") (serialize-qp "pagination.sort_order" $paginationsort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/folders/($folder_id)/contents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List invoices for a given organization
#
# GET /api/v1/invoices
# operationId: CockroachCloud_ListInvoices
export def "invoices ListInvoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-1 # Filters the response to only include invoices with the specified status. This will be sent as a query parameter on the GET request. If not specified, both Finalized and Draft invoices will be included.
  --start-time: string # start_time filters the response to invoices whose billing period started at or after this time (inclusive). Must be in RFC3339 format (e.g., 2024-01-01T00:00:00Z). Defaults to organization creation time if omitted. (format: date-time)
  --end-time: string # end_time filters the response to invoices whose billing period ended at or before this time (exclusive). Must be in RFC3339 format (e.g., 2024-12-31T23:59:59Z). Defaults to current time if omitted. (format: date-time)
]: nothing -> record<invoices: table<adjustments: list, balances: list, folder_resources: list, invoice_id: string, invoice_items: list, period_end: string, period_start: string, status: string, totals: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific invoice for an organization
#
# GET /api/v1/invoices/{invoice_id}
# operationId: CockroachCloud_GetInvoice
export def "invoices GetInvoice" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<adjustments: table<amount: record, name: string>, balances: table<amount: float, currency: string>, folder_resources: table<labels: record, name: string, organization_id: string, parent_id: string, path: list, resource_id: string, resource_type: string>, invoice_id: string, invoice_items: table<cluster: record, line_items: list, totals: list>, period_end: string, period_start: string, status: string, totals: table<amount: float, currency: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/invoices/($invoice_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all JWT Issuers
#
# GET /api/v1/jwt-issuers
# operationId: CockroachCloud_ListJWTIssuers
export def "jwt-issuers ListJWTIssuers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --paginationpage: string
  --paginationlimit: int # format: int32
  --paginationas-of-time: string # format: date-time
  --paginationsort-order: string@paginationsort-order-completer #  - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
]: nothing -> record<jwt_issuers: table<audience: string, claim: string, id: string, identity_map: list, issuer_url: string, jwks: string>, pagination: record<next_page: string, previous_page: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagination.page" $paginationpage "scalar") (serialize-qp "pagination.limit" $paginationlimit "scalar") (serialize-qp "pagination.as_of_time" $paginationas_of_time "scalar") (serialize-qp "pagination.sort_order" $paginationsort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/jwt-issuers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a JWT Issuer
#
# POST /api/v1/jwt-issuers
# operationId: CockroachCloud_AddJWTIssuer
# --identity_map item shape: {cc_identity: string, token_identity: string}
export def "jwt-issuers AddJWTIssuer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  audience: string # e.g. 1234567890abcd
  --claim: string # e.g. email
  --identity-map: list # A list of mappings to map the external token identity into CockroachDB Cloud. — item shape: {cc_identity: string, token_identity: string}
  issuer_url: string # e.g. https://jwt-issuer.example.com
  --jwks: string # e.g. {"keys":[{"e":"AQAB","use":"sig","kty":"RSA","alg":"RS256","n":"tid8bJCI5FxtvMiVHq8pRZBGIPaG9mEa1akpIC9munzxA3mWoc-KoR1TGkocu76WFthaZnPS31WJbRVChU6g4EMIg7E8Ltpxifk1PQu0qqbLcpnoI62ojsB7l_Z_lkls0NUzTuKGMMtNoJsDrL1BT0UzcnWerh2PwzDAMpfPgafWdT2IYGTx1gNLcNOWpPhDgMSQqUmIPwCmxdan4i4OMd7lJYQ1WQlN8VnQgbRgHrm1zImY6MPqho9jW3Ub5FwGbunwCDrP9a2dD_5Iwm7_lR82iB4BGlu28WxFn0fm5DgZAeAFSGKE1xblC97WrjnPh2XYTx6pxsea_Hn71VcNSQ","kid":"9341dedeee2d1869b657fa930300082fe26b3d92"}]}
]: any -> record<audience: string, claim: string, id: string, identity_map: table<cc_identity: string, token_identity: string>, issuer_url: string, jwks: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/jwt-issuers")
  let body = {audience: $audience, claim: $claim, identity_map: $identity_map, issuer_url: $issuer_url, jwks: $jwks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a JWT Issuer
#
# DELETE /api/v1/jwt-issuers/{id}
# operationId: CockroachCloud_DeleteJWTIssuer
export def "jwt-issuers DeleteJWTIssuer" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<audience: string, claim: string, id: string, identity_map: table<cc_identity: string, token_identity: string>, issuer_url: string, jwks: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/jwt-issuers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a JWT Issuer
#
# GET /api/v1/jwt-issuers/{id}
# operationId: CockroachCloud_GetJWTIssuer
export def "jwt-issuers GetJWTIssuer" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<audience: string, claim: string, id: string, identity_map: table<cc_identity: string, token_identity: string>, issuer_url: string, jwks: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/jwt-issuers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a JWT Issuer
#
# PATCH /api/v1/jwt-issuers/{id}
# operationId: CockroachCloud_UpdateJWTIssuer
# --identity_map item shape: {cc_identity: string, token_identity: string}
export def "jwt-issuers UpdateJWTIssuer" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --audience: string # e.g. 1234567890abcd
  --claim: string # e.g. email
  --identity-map: list # item shape: {cc_identity: string, token_identity: string}
  --issuer-url: string # e.g. https://jwt-issuer.example.com
  --jwks: string # e.g. {"keys":[{"e":"AQAB","use":"sig","kty":"RSA","alg":"RS256","n":"tid8bJCI5FxtvMiVHq8pRZBGIPaG9mEa1akpIC9munzxA3mWoc-KoR1TGkocu76WFthaZnPS31WJbRVChU6g4EMIg7E8Ltpxifk1PQu0qqbLcpnoI62ojsB7l_Z_lkls0NUzTuKGMMtNoJsDrL1BT0UzcnWerh2PwzDAMpfPgafWdT2IYGTx1gNLcNOWpPhDgMSQqUmIPwCmxdan4i4OMd7lJYQ1WQlN8VnQgbRgHrm1zImY6MPqho9jW3Ub5FwGbunwCDrP9a2dD_5Iwm7_lR82iB4BGlu28WxFn0fm5DgZAeAFSGKE1xblC97WrjnPh2XYTx6pxsea_Hn71VcNSQ","kid":"9341dedeee2d1869b657fa930300082fe26b3d92"}]}
]: any -> record<audience: string, claim: string, id: string, identity_map: table<cc_identity: string, token_identity: string>, issuer_url: string, jwks: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/jwt-issuers/($id)")
  let body = {audience: $audience, claim: $claim, identity_map: $identity_map, issuer_url: $issuer_url, jwks: $jwks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get information about the caller's organization
#
# GET /api/v1/organization
# operationId: CockroachCloud_GetOrganizationInfo
export def "organization GetOrganizationInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cockroach_cloud_service_principals: record<aws: record<user_arn: string>, azure: record<app_registration_client_id: string, app_registration_name: string>, gcp: record<service_account_email: string>>, created_at: string, id: string, label: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/organization")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List physical replication streams
#
# GET /api/v1/physical-replication-streams
# operationId: CockroachCloud_ListPhysicalReplicationStreams
export def "physical-replication-streams ListPhysicalReplicationStreams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --primary-cluster-id: string # primary_cluster_id, if set, will cause only replication streams with this cluster as the primary to be returned.
  --standby-cluster-id: string # standby_cluster_id, if set, will cause only replication streams with this cluster as the standby to be returned.
  --cluster-id: string # cluster_id, if set, will cause replication streams with this cluster as the primary or the standby to be returned.
  --show-completed: string@bool-completer # show_completed specifies whether or not replication streams in the completed state are shown.
  --paginationpage: string
  --paginationlimit: int # format: int32
  --paginationas-of-time: string # format: date-time
  --paginationsort-order: string@paginationsort-order-completer #  - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
]: nothing -> record<pagination: record<next_page: string, previous_page: string>, physical_replication_streams: table<activated_at: string, canceled_at: string, created_at: string, failover_at: string, id: string, primary_cluster_id: string, replicated_time: string, replication_lag_seconds: int, retained_time: string, standby_cluster_id: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "primary_cluster_id" $primary_cluster_id "scalar") (serialize-qp "standby_cluster_id" $standby_cluster_id "scalar") (serialize-qp "cluster_id" $cluster_id "scalar") (serialize-qp "show_completed" $show_completed "scalar") (serialize-qp "pagination.page" $paginationpage "scalar") (serialize-qp "pagination.limit" $paginationlimit "scalar") (serialize-qp "pagination.as_of_time" $paginationas_of_time "scalar") (serialize-qp "pagination.sort_order" $paginationsort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/physical-replication-streams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a physical replication stream
#
# POST /api/v1/physical-replication-streams
# operationId: CockroachCloud_CreatePhysicalReplicationStream
export def "physical-replication-streams CreatePhysicalReplicationStream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  primary_cluster_id: string # primary_cluster_id is the ID of the cluster that is being replicated.
  standby_cluster_id: string # standby_cluster_id is the ID of the cluster that data is being replicated to.
]: any -> record<activated_at: string, canceled_at: string, created_at: string, failover_at: string, id: string, primary_cluster_id: string, replicated_time: string, replication_lag_seconds: int, retained_time: string, standby_cluster_id: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/physical-replication-streams")
  let body = {primary_cluster_id: $primary_cluster_id, standby_cluster_id: $standby_cluster_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a physical replication stream
#
# GET /api/v1/physical-replication-streams/{id}
# operationId: CockroachCloud_GetPhysicalReplicationStream
export def "physical-replication-streams GetPhysicalReplicationStream" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<activated_at: string, canceled_at: string, created_at: string, failover_at: string, id: string, primary_cluster_id: string, replicated_time: string, replication_lag_seconds: int, retained_time: string, standby_cluster_id: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/physical-replication-streams/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a physical replication stream
#
# PATCH /api/v1/physical-replication-streams/{id}
# operationId: CockroachCloud_UpdatePhysicalReplicationStream
export def "physical-replication-streams UpdatePhysicalReplicationStream" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --failover-at: string # failover_at is the crdb system time at which failover occurs. If the user sets the status to 'FAILING_OVER' but omits failover_at, the failover time will default to the latest consistent replicated time. Otherwise, the user can pick a time up to one hour in the future to schedule a failover, or a time in the past to restore the cluster to a recent state. If the time is in the past, the API will make a best-effort attempt to validate that the time is not earlier than the retained time. In this case, if the retained time is updated in between validation and failover execution and the failover time becomes invalid, the stream will failover to the retained time. failover_at is not required when updating the status to 'CANCELED'. (format: date-time)
  --status: string@status-completer-2 # status describes the desired status of the replication stream.   - STARTING: signifies that a stream is starting  - REPLICATING: during an update request, status 'REPLICATING' is allowed to transition to 'FAILING_OVER' or 'CANCELED'. Other status transitions are not supported.  - FAILING_OVER: used to trigger a failover, or to signify that a failover is occurring.  - COMPLETED: signifies that a failover is complete.  - CANCELED: signifies that a stream is canceled.
]: any -> record<activated_at: string, canceled_at: string, created_at: string, failover_at: string, id: string, primary_cluster_id: string, replicated_time: string, replication_lag_seconds: int, retained_time: string, standby_cluster_id: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/physical-replication-streams/($id)")
  let body = {failover_at: $failover_at, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all RoleGrants
#
# GET /api/v1/roles
# operationId: CockroachCloud_ListRoleGrants
export def "roles ListRoleGrants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --paginationpage: string
  --paginationlimit: int # format: int32
  --paginationas-of-time: string # format: date-time
  --paginationsort-order: string@paginationsort-order-completer #  - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
]: nothing -> record<grants: table<roles: list, user_id: string>, pagination: record<next_page: string, previous_page: string>, user_group_grants: table<group_roles: list, user_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagination.page" $paginationpage "scalar") (serialize-qp "pagination.limit" $paginationlimit "scalar") (serialize-qp "pagination.as_of_time" $paginationas_of_time "scalar") (serialize-qp "pagination.sort_order" $paginationsort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Role Grants for a user
#
# GET /api/v1/roles/{user_id}
# operationId: CockroachCloud_GetAllRolesForUser
export def "roles GetAllRolesForUser" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<group_roles: table<group_names: list, role: record>, roles: table<name: string, resource: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/roles/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace the roles for a user or service account with exactly those provided
#
# PUT /api/v1/roles/{user_id}
# operationId: CockroachCloud_SetRolesForUser
# --roles item shape: {name: "BILLING_COORDINATOR"|"ORG_ADMIN"|"ORG_MEMBER"|"CLUSTER_ADMIN"|"CLUSTER_OPERATOR_WRITER"|"CLUSTER_DEVELOPER"|"CLUSTER_CREATOR"|"FOLDER_ADMIN"|"FOLDER_MOVER"|"METRICS_VIEWER"|"CLUSTER_MONITOR"|"BILLING_VIEWER", resource: record}
export def "roles SetRolesForUser" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  roles: list # item shape: {name: "BILLING_COORDINATOR"|"ORG_ADMIN"|"ORG_MEMBER"|"CLUSTER_ADMIN"|"CLUSTER_OPERATOR_WRITER"|"CLUSTER_DEVELOPER"|"CLUSTER_CREATOR"|"FOLDER_ADMIN"|"FOLDER_MOVER"|"METRICS_VIEWER"|"CLUSTER_MONITOR"|"BILLING_VIEWER", resource: record}
]: any -> record<group_roles: table<group_names: list, role: record>, roles: table<name: string, resource: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/roles/($user_id)")
  let body = {roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a role from a user or service account
#
# DELETE /api/v1/roles/{user_id}/{resource_type}/{resource_id}/{role_name}
# operationId: CockroachCloud_RemoveUserFromRole
export def "roles RemoveUserFromRole" [
  user_id: string
  resource_type: string
  resource_id: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<group_roles: table<group_names: list, role: record>, roles: table<name: string, resource: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/roles/($user_id)/($resource_type)/($resource_id)/($role_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a role to a user or service account
#
# POST /api/v1/roles/{user_id}/{resource_type}/{resource_id}/{role_name}
# operationId: CockroachCloud_AddUserToRole
export def "roles AddUserToRole" [
  user_id: string
  resource_type: string
  resource_id: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<group_roles: table<group_names: list, role: record>, roles: table<name: string, resource: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/roles/($user_id)/($resource_type)/($resource_id)/($role_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List service accounts for an organization
#
# GET /api/v1/service-accounts
# operationId: CockroachCloud_ListServiceAccounts
export def "service-accounts ListServiceAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --paginationpage: string
  --paginationlimit: int # format: int32
  --paginationas-of-time: string # format: date-time
  --paginationsort-order: string@paginationsort-order-completer #  - ASC: Sort in ascending order. This is the default unless otherwise specified.  - DESC: Sort in descending order.
]: nothing -> record<pagination: record<next_page: string, previous_page: string>, service_accounts: table<created_at: string, creator_name: string, description: string, group_roles: list, id: string, name: string, roles: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagination.page" $paginationpage "scalar") (serialize-qp "pagination.limit" $paginationlimit "scalar") (serialize-qp "pagination.as_of_time" $paginationas_of_time "scalar") (serialize-qp "pagination.sort_order" $paginationsort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/service-accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a service account
#
# POST /api/v1/service-accounts
# operationId: CockroachCloud_CreateServiceAccount
# --roles item shape: {name: "BILLING_COORDINATOR"|"ORG_ADMIN"|"ORG_MEMBER"|"CLUSTER_ADMIN"|"CLUSTER_OPERATOR_WRITER"|"CLUSTER_DEVELOPER"|"CLUSTER_CREATOR"|"FOLDER_ADMIN"|"FOLDER_MOVER"|"METRICS_VIEWER"|"CLUSTER_MONITOR"|"BILLING_VIEWER", resource: record}
export def "service-accounts CreateServiceAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string # description of the service account.
  name: string # name of the service account.
  roles: list # roles that are assigned to the service account. — item shape: {name: "BILLING_COORDINATOR"|"ORG_ADMIN"|"ORG_MEMBER"|"CLUSTER_ADMIN"|"CLUSTER_OPERATOR_WRITER"|"CLUSTER_DEVELOPER"|"CLUSTER_CREATOR"|"FOLDER_ADMIN"|"FOLDER_MOVER"|"METRICS_VIEWER"|"CLUSTER_MONITOR"|"BILLING_VIEWER", resource: record}
]: any -> record<created_at: string, creator_name: string, description: string, group_roles: table<group_names: list, role: record>, id: string, name: string, roles: table<name: string, resource: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/service-accounts")
  let body = {description: $description, name: $name, roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a service account
#
# DELETE /api/v1/service-accounts/{id}
# operationId: CockroachCloud_DeleteServiceAccount
export def "service-accounts DeleteServiceAccount" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, creator_name: string, description: string, group_roles: table<group_names: list, role: record>, id: string, name: string, roles: table<name: string, resource: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service-accounts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a service account by ID
#
# GET /api/v1/service-accounts/{id}
# operationId: CockroachCloud_GetServiceAccount
export def "service-accounts GetServiceAccount" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, creator_name: string, description: string, group_roles: table<group_names: list, role: record>, id: string, name: string, roles: table<name: string, resource: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service-accounts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a service account
#
# PATCH /api/v1/service-accounts/{id}
# operationId: CockroachCloud_UpdateServiceAccount
export def "service-accounts UpdateServiceAccount" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # description of the service account.
  --name: string # name of the service account.
]: any -> record<created_at: string, creator_name: string, description: string, group_roles: table<group_names: list, role: record>, id: string, name: string, roles: table<name: string, resource: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service-accounts/($id)")
  let body = {description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search person users by email address
#
# GET /api/v1/users/persons-by-email
# operationId: CockroachCloud_GetPersonUsersByEmail
export def "users-persons-by-email GetPersonUsersByEmail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # an email address is required.
]: nothing -> record<user: record<email: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/persons-by-email" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
