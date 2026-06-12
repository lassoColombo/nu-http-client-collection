# Auto-generated client for ManagementResourceApi v1.2.6
# Source: https://raw.githubusercontent.com/featurehub-io/featurehub/master/backend/mr-api/mr-api.yaml
# Auth: --token flag or $env.MANAGEMENTRESOURCEAPI_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MANAGEMENTRESOURCEAPI_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def order-completer [] { ["ASC" "DESC"] }
def sortBy-completer [] { ["activationStatus" "name"] }
def personType-completer [] { ["person" "sdkServiceAccount" "serviceAccount"] }
def sortOrder-completer [] { ["ASC" "DESC"] }
def order-completer-1 [] { ["ASC" "DESC" "PRIORITY"] }
def apiKeyType-completer [] { ["client_eval_only" "server_eval_only"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "mr-api-dacha1-cache cacheRefresh" } } | get name | first)
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

# Allows superusers to refresh the global Dacha1 cache (if it exists).
#
# POST /mr-api/dacha1/cache
# operationId: cacheRefresh
export def "mr-api-dacha1-cache cacheRefresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allTheThings: oneof<nothing, bool> # refresh the whole cache (nullable)
  --applicationId: list # if provided these applications will be refreshed (nullable)
  --portfolioId: list # nullable
]: any -> record<applicationsRefreshed: int, portfoliosRefreshed: int, environmentsRefreshed: int, serviceAccountsRefreshed: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mr-api/dacha1/cache")
  let body = {allTheThings: $allTheThings, applicationId: $applicationId, portfolioId: $portfolioId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of portfolios.
#
# GET /mr-api/portfolio
# operationId: findPortfolios
export def "mr-api-portfolio findPortfolios" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeGroups: oneof<nothing, bool> # Include groups for this this portfolio in results
  --includeApplications: oneof<nothing, bool> # Include applications for this portfolio in results
  --order: string@order-completer # how to order the results (nullable)
  --filter: string # What to filter the results by
  --parentPortfolioId: string # The parent portfolio to search under. If none is provided, use the top level one
]: nothing -> table<createdBy: record<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, updatedBy: record<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, whenCreated: string, whenUpdated: string, id: string, name: string, description: string, version: int, organizationId: string, groups: list<record>, applications: list<record>, whenArchived: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeGroups" $includeGroups "scalar") (serialize-qp "includeApplications" $includeApplications "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "parentPortfolioId" $parentPortfolioId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mr-api/portfolio" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new portfolio
#
# POST /mr-api/portfolio
# operationId: createPortfolio
export def "mr-api-portfolio createPortfolio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeGroups: oneof<nothing, bool> # Include groups for this this portfolio in results
  --includeApplications: oneof<nothing, bool> # Include applications for this portfolio in results
  name: string
  --description: string # nullable
]: any -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, name: string, description: string, version: int, organizationId: string, groups: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list, simpleMembers: list, members: list, applicationRoles: list, environmentRoles: list, whenArchived: string>, applications: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, name: string, description: string, portfolioId: string, version: int, groups: list, features: list, environments: list, whenArchived: string>, whenArchived: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeGroups" $includeGroups "scalar") (serialize-qp "includeApplications" $includeApplications "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mr-api/portfolio" $qp)
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a portfolio
#
# PUT /mr-api/portfolio
# operationId: updatePortfolioOnOrganisation
# --groups item shape: {createdBy?: any, updatedBy?: any, whenCreated?: string, whenUpdated?: string, id: string, admin?: bool, portfolioId?: string, organizationId?: string, version?: int, name: string, superMembers?: list, simpleMembers?: list, members?: list, applicationRoles?: list, environmentRoles?: list, whenArchived?: string}
# --applications item shape: {createdBy?: any, updatedBy?: any, whenCreated?: string, whenUpdated?: string, id: string, name: string, description?: string, portfolioId?: string, version?: int, groups?: list, features?: list, environments?: list, whenArchived?: string}
export def "mr-api-portfolio updatePortfolioOnOrganisation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeGroups: oneof<nothing, bool> # Include groups for this this portfolio in results
  --includeApplications: oneof<nothing, bool> # Include applications for this portfolio in results
  --includeEnvironments: oneof<nothing, bool> # Include environments for the included applications this portfolio in results
  --createdBy: any # nullable
  --updatedBy: any # nullable
  --whenCreated: string # nullable, format: date-time
  --whenUpdated: string # nullable, format: date-time
  id: string # format: uuid
  name: string
  --description: string # nullable
  version: int # format: int64
  --organizationId: string # nullable, format: uuid
  --groups: list # default: [] — item shape: {createdBy?: any, updatedBy?: any, whenCreated?: string, whenUpdated?: string, id: string, admin?: bool, portfolioId?: string, organizationId?: string, version?: int, name: string, superMembers?: list, simpleMembers?: list, members?: list, applicationRoles?: list, environmentRoles?: list, whenArchived?: string}
  --applications: list # default: [] — item shape: {createdBy?: any, updatedBy?: any, whenCreated?: string, whenUpdated?: string, id: string, name: string, description?: string, portfolioId?: string, version?: int, groups?: list, features?: list, environments?: list, whenArchived?: string}
  --whenArchived: string # nullable, format: date-time
]: any -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, name: string, description: string, version: int, organizationId: string, groups: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list, simpleMembers: list, members: list, applicationRoles: list, environmentRoles: list, whenArchived: string>, applications: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, name: string, description: string, portfolioId: string, version: int, groups: list, features: list, environments: list, whenArchived: string>, whenArchived: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeGroups" $includeGroups "scalar") (serialize-qp "includeApplications" $includeApplications "scalar") (serialize-qp "includeEnvironments" $includeEnvironments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mr-api/portfolio" $qp)
  let body = {createdBy: $createdBy, updatedBy: $updatedBy, whenCreated: $whenCreated, whenUpdated: $whenUpdated, id: $id, name: $name, description: $description, version: $version, organizationId: $organizationId, groups: $groups, applications: $applications, whenArchived: $whenArchived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get portfolio
#
# GET /mr-api/portfolio/{id}
# operationId: getPortfolio
export def "mr-api-portfolio get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeGroups: oneof<nothing, bool> # Include groups for this this portfolio in results
  --includeApplications: oneof<nothing, bool> # Include applications for this portfolio in results
  --includeEnvironments: oneof<nothing, bool> # Include the environments inside the applications
]: nothing -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, name: string, description: string, version: int, organizationId: string, groups: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list, simpleMembers: list, members: list, applicationRoles: list, environmentRoles: list, whenArchived: string>, applications: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, name: string, description: string, portfolioId: string, version: int, groups: list, features: list, environments: list, whenArchived: string>, whenArchived: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeGroups" $includeGroups "scalar") (serialize-qp "includeApplications" $includeApplications "scalar") (serialize-qp "includeEnvironments" $includeEnvironments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/portfolio/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a portfolio
#
# PUT /mr-api/portfolio/{id}
# DEPRECATED
# operationId: updatePortfolio
# --groups item shape: {createdBy?: any, updatedBy?: any, whenCreated?: string, whenUpdated?: string, id: string, admin?: bool, portfolioId?: string, organizationId?: string, version?: int, name: string, superMembers?: list, simpleMembers?: list, members?: list, applicationRoles?: list, environmentRoles?: list, whenArchived?: string}
# --applications item shape: {createdBy?: any, updatedBy?: any, whenCreated?: string, whenUpdated?: string, id: string, name: string, description?: string, portfolioId?: string, version?: int, groups?: list, features?: list, environments?: list, whenArchived?: string}
@deprecated
export def "mr-api-portfolio updatePortfolio" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeGroups: oneof<nothing, bool> # Include groups for this this portfolio in results
  --includeApplications: oneof<nothing, bool> # Include applications for this portfolio in results
  --includeEnvironments: oneof<nothing, bool> # Include the environments inside the applications
  --createdBy: any # nullable
  --updatedBy: any # nullable
  --whenCreated: string # nullable, format: date-time
  --whenUpdated: string # nullable, format: date-time
  --body-id: string # format: uuid
  name: string
  --description: string # nullable
  version: int # format: int64
  --organizationId: string # nullable, format: uuid
  --groups: list # default: [] — item shape: {createdBy?: any, updatedBy?: any, whenCreated?: string, whenUpdated?: string, id: string, admin?: bool, portfolioId?: string, organizationId?: string, version?: int, name: string, superMembers?: list, simpleMembers?: list, members?: list, applicationRoles?: list, environmentRoles?: list, whenArchived?: string}
  --applications: list # default: [] — item shape: {createdBy?: any, updatedBy?: any, whenCreated?: string, whenUpdated?: string, id: string, name: string, description?: string, portfolioId?: string, version?: int, groups?: list, features?: list, environments?: list, whenArchived?: string}
  --whenArchived: string # nullable, format: date-time
]: any -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, name: string, description: string, version: int, organizationId: string, groups: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list, simpleMembers: list, members: list, applicationRoles: list, environmentRoles: list, whenArchived: string>, applications: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, name: string, description: string, portfolioId: string, version: int, groups: list, features: list, environments: list, whenArchived: string>, whenArchived: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeGroups" $includeGroups "scalar") (serialize-qp "includeApplications" $includeApplications "scalar") (serialize-qp "includeEnvironments" $includeEnvironments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/portfolio/($id)" $qp)
  let body = {createdBy: $createdBy, updatedBy: $updatedBy, whenCreated: $whenCreated, whenUpdated: $whenUpdated, id: $body_id, name: $name, description: $description, version: $version, organizationId: $organizationId, groups: $groups, applications: $applications, whenArchived: $whenArchived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a portfolio
#
# DELETE /mr-api/portfolio/{id}
# operationId: deletePortfolio
export def "mr-api-portfolio delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeGroups: oneof<nothing, bool> # Include groups for this this portfolio in results
  --includeApplications: oneof<nothing, bool> # Include applications for this portfolio in results
  --includeEnvironments: oneof<nothing, bool> # Include the environments inside the applications
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeGroups" $includeGroups "scalar") (serialize-qp "includeApplications" $includeApplications "scalar") (serialize-qp "includeEnvironments" $includeEnvironments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/portfolio/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of applications.
#
# GET /mr-api/portfolio/{id}/application
# operationId: findApplications
export def "mr-api-portfolio-application findApplications" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeEnvironments: oneof<nothing, bool> # Include the environments in the result
  --includeFeatures: oneof<nothing, bool> # Include the features in the result
  --order: string@order-completer # how to order the results (nullable)
  --filter: string # What to filter the results by
]: nothing -> table<createdBy: record<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, updatedBy: record<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, whenCreated: string, whenUpdated: string, id: string, name: string, description: string, portfolioId: string, version: int, groups: list<record>, features: list<record>, environments: list<record>, whenArchived: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeEnvironments" $includeEnvironments "scalar") (serialize-qp "includeFeatures" $includeFeatures "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/portfolio/($id)/application" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new application
#
# POST /mr-api/portfolio/{id}/application
# operationId: createApplication
export def "mr-api-portfolio-application createApplication" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeEnvironments: oneof<nothing, bool> # Include the environments in the result
  --includeFeatures: oneof<nothing, bool> # Include the features in the result
  name: string
  description: string
]: any -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, name: string, description: string, portfolioId: string, version: int, groups: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list, simpleMembers: list, members: list, applicationRoles: list, environmentRoles: list, whenArchived: string>, features: table<id: string, key: string, alias: string, link: string, name: string, valueType: any, version: int, whenArchived: string, secret: bool, description: string, metaData: string, featureFilter: list>, environments: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, applicationId: string, name: string, priorEnvironmentId: string, version: int, description: string, production: bool, groupRoles: list, features: list, environmentInfo: any, webhookEnvironmentInfo: any, serviceAccountPermission: list, whenArchived: string>, whenArchived: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeEnvironments" $includeEnvironments "scalar") (serialize-qp "includeFeatures" $includeFeatures "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/portfolio/($id)/application" $qp)
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an application
#
# PUT /mr-api/portfolio/{id}/application
# operationId: updateApplicationOnPortfolio
# --groups item shape: {createdBy?: any, updatedBy?: any, whenCreated?: string, whenUpdated?: string, id: string, admin?: bool, portfolioId?: string, organizationId?: string, version?: int, name: string, superMembers?: list, simpleMembers?: list, members?: list, applicationRoles?: list, environmentRoles?: list, whenArchived?: string}
# --features item shape: {id?: string, key?: string, alias?: string, link?: string, name: string, valueType?: any, version?: int, whenArchived?: string, secret?: bool, description?: string, metaData?: string, featureFilter?: list}
# --environments item shape: {createdBy?: any, updatedBy?: any, whenCreated?: string, whenUpdated?: string, id: string, applicationId?: string, name: string, priorEnvironmentId?: string, version?: int, description?: string, production?: bool, groupRoles?: list, features?: list, environmentInfo?: any, webhookEnvironmentInfo?: any, serviceAccountPermission?: list, whenArchived?: string}
export def "mr-api-portfolio-application updateApplicationOnPortfolio" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeEnvironments: oneof<nothing, bool> # Include the environments in the result
  --includeFeatures: oneof<nothing, bool> # Include the features in the result
  --createdBy: any # nullable
  --updatedBy: any # nullable
  --whenCreated: string # nullable, format: date-time
  --whenUpdated: string # nullable, format: date-time
  --body-id: string # format: uuid
  name: string
  --description: string # nullable
  --portfolioId: string # nullable, format: uuid
  --version: int # format: int64
  --groups: list # default: [] — item shape: {createdBy?: any, updatedBy?: any, whenCreated?: string, whenUpdated?: string, id: string, admin?: bool, portfolioId?: string, organizationId?: string, version?: int, name: string, superMembers?: list, simpleMembers?: list, members?: list, applicationRoles?: list, environmentRoles?: list, whenArchived?: string}
  --features: list # default: [] — item shape: {id?: string, key?: string, alias?: string, link?: string, name: string, valueType?: any, version?: int, whenArchived?: string, secret?: bool, description?: string, metaData?: string, featureFilter?: list}
  --environments: list # default: [] — item shape: {createdBy?: any, updatedBy?: any, whenCreated?: string, whenUpdated?: string, id: string, applicationId?: string, name: string, priorEnvironmentId?: string, version?: int, description?: string, production?: bool, groupRoles?: list, features?: list, environmentInfo?: any, webhookEnvironmentInfo?: any, serviceAccountPermission?: list, whenArchived?: string}
  --whenArchived: string # nullable, format: date-time
]: any -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, name: string, description: string, portfolioId: string, version: int, groups: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list, simpleMembers: list, members: list, applicationRoles: list, environmentRoles: list, whenArchived: string>, features: table<id: string, key: string, alias: string, link: string, name: string, valueType: any, version: int, whenArchived: string, secret: bool, description: string, metaData: string, featureFilter: list>, environments: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, applicationId: string, name: string, priorEnvironmentId: string, version: int, description: string, production: bool, groupRoles: list, features: list, environmentInfo: any, webhookEnvironmentInfo: any, serviceAccountPermission: list, whenArchived: string>, whenArchived: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeEnvironments" $includeEnvironments "scalar") (serialize-qp "includeFeatures" $includeFeatures "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/portfolio/($id)/application" $qp)
  let body = {createdBy: $createdBy, updatedBy: $updatedBy, whenCreated: $whenCreated, whenUpdated: $whenUpdated, id: $body_id, name: $name, description: $description, portfolioId: $portfolioId, version: $version, groups: $groups, features: $features, environments: $environments, whenArchived: $whenArchived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of groups.
#
# GET /mr-api/portfolio/{id}/group
# operationId: findGroups
export def "mr-api-portfolio-group findGroups" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includePeople: oneof<nothing, bool> # include people in each group
  --order: string@order-completer # how to order the results (nullable)
  --filter: string # What to filter the results by
]: nothing -> table<createdBy: record<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, updatedBy: record<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list<string>, simpleMembers: list<record>, members: list<record>, applicationRoles: list<record>, environmentRoles: list<record>, whenArchived: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includePeople" $includePeople "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/portfolio/($id)/group" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new group
#
# POST /mr-api/portfolio/{id}/group
# operationId: createGroup
# --applicationRoles item shape: {applicationId: string, groupId: string, roles: list}
export def "mr-api-portfolio-group createGroup" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includePeople: oneof<nothing, bool> # include people in each group
  --name: string
  --admin: oneof<nothing, bool> # is this an admin group? (nullable)
  --applicationRoles: list # nullable, default: [] — item shape: {applicationId: string, groupId: string, roles: list}
]: any -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<any>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<any>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list<string>, simpleMembers: table<id: string, name: string, email: string, type: string>, members: table<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, applicationRoles: table<applicationId: string, groupId: string, roles: list>, environmentRoles: table<environmentId: string, groupId: string, roles: list>, whenArchived: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includePeople" $includePeople "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/portfolio/($id)/group" $qp)
  let body = {name: $name, admin: $admin, applicationRoles: $applicationRoles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a group
#
# PUT /mr-api/portfolio/{id}/group
# operationId: updateGroupOnPortfolio
# --applicationRoles item shape: {applicationId: string, groupId: string, roles: list}
# --environmentRoles item shape: {environmentId: string, groupId: string, roles: list}
export def "mr-api-portfolio-group updateGroupOnPortfolio" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includePeople: oneof<nothing, bool> # include people in each group
  --includeMembers: oneof<nothing, bool> # include people in each group
  --includeMembersV2: oneof<nothing, bool> # include anemic people in each group with superuser
  --includeGroupRoles: oneof<nothing, bool> # include environment and application roles in each group
  --updateEnvironmentGroupRoles: oneof<nothing, bool> # update environment group roles, deleting any not passed
  --updateApplicationGroupRoles: oneof<nothing, bool> # update application group roles, deleting any not passed
  --applicationId: string # if updating the application group roles, and the application id is passed, then the changes are limited to that application (format: uuid)
  --body-id: string # format: uuid
  --name: string # nullable
  --version: int # format: int64
  --applicationRoles: list # nullable, default: [] — item shape: {applicationId: string, groupId: string, roles: list}
  --environmentRoles: list # default: [] — item shape: {environmentId: string, groupId: string, roles: list}
]: any -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<any>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<any>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list<string>, simpleMembers: table<id: string, name: string, email: string, type: string>, members: table<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, applicationRoles: table<applicationId: string, groupId: string, roles: list>, environmentRoles: table<environmentId: string, groupId: string, roles: list>, whenArchived: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includePeople" $includePeople "scalar") (serialize-qp "includeMembers" $includeMembers "scalar") (serialize-qp "includeMembersV2" $includeMembersV2 "scalar") (serialize-qp "includeGroupRoles" $includeGroupRoles "scalar") (serialize-qp "updateEnvironmentGroupRoles" $updateEnvironmentGroupRoles "scalar") (serialize-qp "updateApplicationGroupRoles" $updateApplicationGroupRoles "scalar") (serialize-qp "applicationId" $applicationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/portfolio/($id)/group" $qp)
  let body = {id: $body_id, name: $name, version: $version, applicationRoles: $applicationRoles, environmentRoles: $environmentRoles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of matching people.
#
# GET /mr-api/person
# operationId: findPeople
export def "mr-api-person findPeople" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeGroups: oneof<nothing, bool> # Include groups in result
  --countGroups: oneof<nothing, bool> # Return the number of groups
  --order: string@order-completer # how to order the results (nullable)
  --filter: string # What to filter the results by
  --startAt: int # Where in the results to start
  --pageSize: int # How many results to return
  --includeLastLoggedIn: oneof<nothing, bool> # Include last logged in timestamp
  --includeDeactivated: oneof<nothing, bool> # Include people who are no longer active
  --personTypes: list # Filter by person types
  --sortBy: string@sortBy-completer
]: nothing -> record<max: int, people: table<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, summarisedPeople: table<id: string, name: string, email: string, version: int, personType: string, whenLastAuthenticated: string, whenLastSeen: string, whenDeactivated: string, groupCount: int>, outstandingRegistrations: table<id: string, token: string, expired: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeGroups" $includeGroups "scalar") (serialize-qp "countGroups" $countGroups "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "startAt" $startAt "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "includeLastLoggedIn" $includeLastLoggedIn "scalar") (serialize-qp "includeDeactivated" $includeDeactivated "scalar") (serialize-qp "personTypes" $personTypes "multi") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mr-api/person" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new person
#
# POST /mr-api/person
# operationId: createPerson
export def "mr-api-person createPerson" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeGroups: oneof<nothing, bool> # Include groups in result
  --email: string # Can be null if a service account (nullable, format: email)
  personType: string@personType-completer # default: person
  --name: string # Can be null if a service account (nullable)
  --groupIds: list # nullable, default: []
]: any -> record<registrationUrl: string, personId: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeGroups" $includeGroups "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mr-api/person" $qp)
  let body = {email: $email, personType: $personType, name: $name, groupIds: $groupIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset security token of supported person type (usually service accounts only)
#
# POST /mr-api/person/{id}/token-reset
# operationId: resetSecurityToken
export def "mr-api-person-token-reset resetSecurityToken" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mr-api/person/($id)/token-reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a person
#
# PUT /mr-api/person/{id}/v2
# operationId: updatePersonV2
export def "mr-api-person updatePersonV2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # nullable
  --email: string # nullable, format: email
  version: int # This keeps track of which person version we are updating in case the user tries to update an old record (format: int64)
  --groups: list # nullable
  --unarchive: oneof<nothing, bool> # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mr-api/person/($id)/v2")
  let body = {name: $name, email: $email, version: $version, groups: $groups, unarchive: $unarchive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get person
#
# GET /mr-api/person/{id}
# operationId: getPerson
export def "mr-api-person get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeGroups: oneof<nothing, bool> # Include groups in result
  --includeAcls: oneof<nothing, bool> # include acls for each group
]: nothing -> record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list, simpleMembers: list, members: list, applicationRoles: list, environmentRoles: list, whenArchived: string>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeGroups" $includeGroups "scalar") (serialize-qp "includeAcls" $includeAcls "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/person/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a person
#
# PUT /mr-api/person/{id}
# operationId: updatePerson
# --groups item shape: {createdBy?: any, updatedBy?: any, whenCreated?: string, whenUpdated?: string, id: string, admin?: bool, portfolioId?: string, organizationId?: string, version?: int, name: string, superMembers?: list, simpleMembers?: list, members?: list, applicationRoles?: list, environmentRoles?: list, whenArchived?: string}
# --additional item shape: {key: string, value: string}
export def "mr-api-person updatePerson" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeGroups: oneof<nothing, bool> # Include groups in result
  --includeAcls: oneof<nothing, bool> # include acls for each group
  --body-id: any # nullable
  --name: string # nullable
  --email: string # nullable, format: email
  --personType: any # nullable
  --other: string # nullable
  --body-source: string # nullable
  --version: int # nullable, format: int64
  --passwordRequiresReset: oneof<nothing, bool> # nullable
  --groups: list # default: [] — item shape: {createdBy?: any, updatedBy?: any, whenCreated?: string, whenUpdated?: string, id: string, admin?: bool, portfolioId?: string, organizationId?: string, version?: int, name: string, superMembers?: list, simpleMembers?: list, members?: list, applicationRoles?: list, environmentRoles?: list, whenArchived?: string}
  --whenArchived: string # nullable, format: date-time
  --whenLastAuthenticated: string # This is the timestamp in UTC when they last logged into the system (nullable, format: date-time)
  --whenLastSeen: string # This is the timestamp in UTC when they last made a request to the system on their most recent login. If it is null it means they have no current token or have never logged in. (nullable, format: date-time)
  --additional: list # nullable, default: [] — item shape: {key: string, value: string}
]: any -> record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list, simpleMembers: list, members: list, applicationRoles: list, environmentRoles: list, whenArchived: string>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeGroups" $includeGroups "scalar") (serialize-qp "includeAcls" $includeAcls "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/person/($id)" $qp)
  let body = {id: $body_id, name: $name, email: $email, personType: $personType, other: $other, source: $body_source, version: $version, passwordRequiresReset: $passwordRequiresReset, groups: $groups, whenArchived: $whenArchived, whenLastAuthenticated: $whenLastAuthenticated, whenLastSeen: $whenLastSeen, additional: $additional} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a person
#
# DELETE /mr-api/person/{id}
# operationId: deletePerson
export def "mr-api-person delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeGroups: oneof<nothing, bool> # Include groups in result
  --includeAcls: oneof<nothing, bool> # include acls for each group
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeGroups" $includeGroups "scalar") (serialize-qp "includeAcls" $includeAcls "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/person/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new user
#
# POST /mr-api/authentication
# operationId: registerPerson
export def "mr-api-authentication registerPerson" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  email: string # format: email
  password: string # format: password
  confirmPassword: string # format: password
  registrationToken: string
]: any -> record<accessToken: string, refreshToken: string, redirectUrl: string, capabilityInfo: any, person: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mr-api/authentication")
  let body = {name: $name, email: $email, password: $password, confirmPassword: $confirmPassword, registrationToken: $registrationToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a login URL for this specified provider if it is supported by the server
#
# GET /mr-api/external-provider/{provider}
# operationId: getLoginUrlForProvider
export def "mr-api-external-provider get" [
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<redirectUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mr-api/external-provider/($provider)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Login to Feature Hub
#
# POST /mr-api/login
# operationId: login
export def "mr-api-login login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # format: email
  password: string
]: any -> record<accessToken: string, refreshToken: string, redirectUrl: string, capabilityInfo: any, person: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mr-api/login")
  let body = {email: $email, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get person by token
#
# GET /mr-api/logout
# operationId: logout
export def "mr-api-logout logout" [
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
  let full_url = (build-url $base "/mr-api/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace temporary password
#
# PUT /mr-api/authentication/{id}/replaceTempPassword
# operationId: replaceTempPassword
export def "mr-api-authentication-replace-temp-password replaceTempPassword" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string
  --reactivate: oneof<nothing, bool> # default: false
]: any -> record<accessToken: string, refreshToken: string, redirectUrl: string, capabilityInfo: any, person: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mr-api/authentication/($id)/replaceTempPassword")
  let body = {password: $password, reactivate: $reactivate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Allows an administrator to reset a user's expired token so they can login
#
# POST /mr-api/authentication/{email}/expiredTokenReset
# operationId: resetExpiredToken
export def "mr-api-authentication-expired-token-reset resetExpiredToken" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<registrationUrl: string, personId: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mr-api/authentication/($email)/expiredTokenReset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change password
#
# PUT /mr-api/authentication/{id}/changePassword
# operationId: changePassword
export def "mr-api-authentication-change-password changePassword" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  oldPassword: string # format: password
  newPassword: string # format: password
]: any -> record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list, simpleMembers: list, members: list, applicationRoles: list, environmentRoles: list, whenArchived: string>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mr-api/authentication/($id)/changePassword")
  let body = {oldPassword: $oldPassword, newPassword: $newPassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get person by token
#
# GET /mr-api/authentication/{token}
# operationId: personByToken
export def "mr-api-authentication personByToken" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list, simpleMembers: list, members: list, applicationRoles: list, environmentRoles: list, whenArchived: string>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mr-api/authentication/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset password
#
# PUT /mr-api/authentication/{id}/resetPassword
# operationId: resetPassword
export def "mr-api-authentication-reset-password resetPassword" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string
  --reactivate: oneof<nothing, bool> # default: false
]: any -> record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list, simpleMembers: list, members: list, applicationRoles: list, environmentRoles: list, whenArchived: string>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mr-api/authentication/($id)/resetPassword")
  let body = {password: $password, reactivate: $reactivate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get application
#
# GET /mr-api/application/{appId}
# operationId: getApplication
export def "mr-api-application get" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeEnvironments: oneof<nothing, bool> # Include the environments in the result
]: nothing -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, name: string, description: string, portfolioId: string, version: int, groups: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list, simpleMembers: list, members: list, applicationRoles: list, environmentRoles: list, whenArchived: string>, features: table<id: string, key: string, alias: string, link: string, name: string, valueType: any, version: int, whenArchived: string, secret: bool, description: string, metaData: string, featureFilter: list>, environments: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, applicationId: string, name: string, priorEnvironmentId: string, version: int, description: string, production: bool, groupRoles: list, features: list, environmentInfo: any, webhookEnvironmentInfo: any, serviceAccountPermission: list, whenArchived: string>, whenArchived: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeEnvironments" $includeEnvironments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/application/($appId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an application
#
# PUT /mr-api/application/{appId}
# DEPRECATED
# operationId: updateApplication
# --groups item shape: {createdBy?: any, updatedBy?: any, whenCreated?: string, whenUpdated?: string, id: string, admin?: bool, portfolioId?: string, organizationId?: string, version?: int, name: string, superMembers?: list, simpleMembers?: list, members?: list, applicationRoles?: list, environmentRoles?: list, whenArchived?: string}
# --features item shape: {id?: string, key?: string, alias?: string, link?: string, name: string, valueType?: any, version?: int, whenArchived?: string, secret?: bool, description?: string, metaData?: string, featureFilter?: list}
# --environments item shape: {createdBy?: any, updatedBy?: any, whenCreated?: string, whenUpdated?: string, id: string, applicationId?: string, name: string, priorEnvironmentId?: string, version?: int, description?: string, production?: bool, groupRoles?: list, features?: list, environmentInfo?: any, webhookEnvironmentInfo?: any, serviceAccountPermission?: list, whenArchived?: string}
@deprecated
export def "mr-api-application updateApplication" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeEnvironments: oneof<nothing, bool> # Include the environments in the result
  --createdBy: any # nullable
  --updatedBy: any # nullable
  --whenCreated: string # nullable, format: date-time
  --whenUpdated: string # nullable, format: date-time
  id: string # format: uuid
  name: string
  --description: string # nullable
  --portfolioId: string # nullable, format: uuid
  --version: int # format: int64
  --groups: list # default: [] — item shape: {createdBy?: any, updatedBy?: any, whenCreated?: string, whenUpdated?: string, id: string, admin?: bool, portfolioId?: string, organizationId?: string, version?: int, name: string, superMembers?: list, simpleMembers?: list, members?: list, applicationRoles?: list, environmentRoles?: list, whenArchived?: string}
  --features: list # default: [] — item shape: {id?: string, key?: string, alias?: string, link?: string, name: string, valueType?: any, version?: int, whenArchived?: string, secret?: bool, description?: string, metaData?: string, featureFilter?: list}
  --environments: list # default: [] — item shape: {createdBy?: any, updatedBy?: any, whenCreated?: string, whenUpdated?: string, id: string, applicationId?: string, name: string, priorEnvironmentId?: string, version?: int, description?: string, production?: bool, groupRoles?: list, features?: list, environmentInfo?: any, webhookEnvironmentInfo?: any, serviceAccountPermission?: list, whenArchived?: string}
  --whenArchived: string # nullable, format: date-time
]: any -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, name: string, description: string, portfolioId: string, version: int, groups: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list, simpleMembers: list, members: list, applicationRoles: list, environmentRoles: list, whenArchived: string>, features: table<id: string, key: string, alias: string, link: string, name: string, valueType: any, version: int, whenArchived: string, secret: bool, description: string, metaData: string, featureFilter: list>, environments: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, applicationId: string, name: string, priorEnvironmentId: string, version: int, description: string, production: bool, groupRoles: list, features: list, environmentInfo: any, webhookEnvironmentInfo: any, serviceAccountPermission: list, whenArchived: string>, whenArchived: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeEnvironments" $includeEnvironments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/application/($appId)" $qp)
  let body = {createdBy: $createdBy, updatedBy: $updatedBy, whenCreated: $whenCreated, whenUpdated: $whenUpdated, id: $id, name: $name, description: $description, portfolioId: $portfolioId, version: $version, groups: $groups, features: $features, environments: $environments, whenArchived: $whenArchived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an application
#
# DELETE /mr-api/application/{appId}
# operationId: deleteApplication
export def "mr-api-application delete" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeEnvironments: oneof<nothing, bool> # Include the environments in the result
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeEnvironments" $includeEnvironments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/application/($appId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Geta summary of the application status
#
# GET /mr-api/application/{appId}/summary
# operationId: summaryApplication
export def "mr-api-application-summary summaryApplication" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<groupsHavePermission: bool, serviceAccountsHavePermission: bool, featureCount: int, environmentCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mr-api/application/($appId)/summary")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get all features available in this application
#
# GET /mr-api/application/{id}/features
# operationId: getAllFeaturesForApplication
export def "mr-api-application-features list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeMetaData: oneof<nothing, bool> # Include the metadata in the returned feature objects. Can be large.
]: nothing -> table<id: string, key: string, alias: string, link: string, name: string, valueType: any, version: int, whenArchived: string, secret: bool, description: string, metaData: string, featureFilter: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeMetaData" $includeMetaData "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/application/($id)/features" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# add a new feature to this application, returns all features.
#
# POST /mr-api/application/{id}/features
# operationId: createFeaturesForApplication
export def "mr-api-application-features createFeaturesForApplication" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeMetaData: oneof<nothing, bool> # Include the metadata in the returned feature objects. Can be large.
  key: string # Unique within this application
  --alias: string # use this in code, as then people cannot guess your new features from their names (nullable)
  --link: string # nullable
  name: string # description if any
  valueType: any
  --secret: oneof<nothing, bool> # should the config remain invisible to users without secret permission (nullable)
  --description: string # nullable
  --metaData: string # Metadata that may need to be stored. Intended for ADK use. No data limit on FHOS. 10k on SaaS. (stored as CLOB) (nullable)
  --featureFilter: list # The ID's of Filters associated with this feature (nullable)
]: any -> table<id: string, key: string, alias: string, link: string, name: string, valueType: any, version: int, whenArchived: string, secret: bool, description: string, metaData: string, featureFilter: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeMetaData" $includeMetaData "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/application/($id)/features" $qp)
  let body = {key: $key, alias: $alias, link: $link, name: $name, valueType: $valueType, secret: $secret, description: $description, metaData: $metaData, featureFilter: $featureFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# updates all named features in this application, returns all features by default otherwise just the feature updated
#
# PUT /mr-api/application/{id}/features
# operationId: updateFeatureForApplicationOnFeature
export def "mr-api-application-features updateFeatureForApplicationOnFeature" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeMetaData: oneof<nothing, bool> # Include the metadata in the returned feature objects. Can be large.
  --returnAllFeatures: oneof<nothing, bool> # default: true
  --body-id: string # nullable, format: uuid
  --key: string # Unique within this application
  --alias: string # use this in code, as then people cannot guess your new features from their names (nullable)
  --link: string # nullable
  name: string # description if any
  --valueType: any
  --version: int # used for optimistic locking when renaming a feature (format: int64)
  --whenArchived: string # nullable, format: date-time
  --secret: oneof<nothing, bool> # should the config remain invisible to users without secret permission (nullable)
  --description: string # nullable
  --metaData: string # Metadata that may need to be stored. Intended for ADK use. No data limit on FHOS. 10k on SaaS. (stored as CLOB) (nullable)
  --featureFilter: list # The ID's of Filters associated with this feature (nullable)
]: any -> table<id: string, key: string, alias: string, link: string, name: string, valueType: any, version: int, whenArchived: string, secret: bool, description: string, metaData: string, featureFilter: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeMetaData" $includeMetaData "scalar") (serialize-qp "returnAllFeatures" $returnAllFeatures "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/application/($id)/features" $qp)
  let body = {id: $body_id, key: $key, alias: $alias, link: $link, name: $name, valueType: $valueType, version: $version, whenArchived: $whenArchived, secret: $secret, description: $description, metaData: $metaData, featureFilter: $featureFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# get an individual feature
#
# GET /mr-api/application/{id}/features/{key}
# operationId: getFeatureByKey
export def "mr-api-application-features get" [
  id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeMetaData: oneof<nothing, bool> # Include the metadata in the returned feature objects. Can be large.
  --includeFilters: oneof<nothing, bool> # Include the filters associated with the flag
]: nothing -> record<id: string, key: string, alias: string, link: string, name: string, valueType: any, version: int, whenArchived: string, secret: bool, description: string, metaData: string, featureFilter: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeMetaData" $includeMetaData "scalar") (serialize-qp "includeFilters" $includeFilters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/application/($id)/features/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updates all named features in this application, returns all features. Use this ONLY if you wish to change the key.
#
# PUT /mr-api/application/{id}/features/{key}
# operationId: updateFeatureForApplication
export def "mr-api-application-features updateFeatureForApplication" [
  id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeMetaData: oneof<nothing, bool> # Include the metadata in the returned feature objects. Can be large.
  --includeFilters: oneof<nothing, bool> # Include the filters associated with the flag
  --body-id: string # nullable, format: uuid
  --body-key: string # Unique within this application
  --alias: string # use this in code, as then people cannot guess your new features from their names (nullable)
  --link: string # nullable
  name: string # description if any
  --valueType: any
  --version: int # used for optimistic locking when renaming a feature (format: int64)
  --whenArchived: string # nullable, format: date-time
  --secret: oneof<nothing, bool> # should the config remain invisible to users without secret permission (nullable)
  --description: string # nullable
  --metaData: string # Metadata that may need to be stored. Intended for ADK use. No data limit on FHOS. 10k on SaaS. (stored as CLOB) (nullable)
  --featureFilter: list # The ID's of Filters associated with this feature (nullable)
]: any -> table<id: string, key: string, alias: string, link: string, name: string, valueType: any, version: int, whenArchived: string, secret: bool, description: string, metaData: string, featureFilter: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeMetaData" $includeMetaData "scalar") (serialize-qp "includeFilters" $includeFilters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/application/($id)/features/($key)" $qp)
  let body = {id: $body_id, key: $body_key, alias: $alias, link: $link, name: $name, valueType: $valueType, version: $version, whenArchived: $whenArchived, secret: $secret, description: $description, metaData: $metaData, featureFilter: $featureFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# updates all named features in this application, returns all features.
#
# DELETE /mr-api/application/{id}/features/{key}
# operationId: deleteFeatureForApplication
export def "mr-api-application-features delete" [
  id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeMetaData: oneof<nothing, bool> # Include the metadata in the returned feature objects. Can be large.
  --includeFilters: oneof<nothing, bool> # Include the filters associated with the flag
]: nothing -> table<id: string, key: string, alias: string, link: string, name: string, valueType: any, version: int, whenArchived: string, secret: bool, description: string, metaData: string, featureFilter: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeMetaData" $includeMetaData "scalar") (serialize-qp "includeFilters" $includeFilters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/application/($id)/features/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of all environments and features and their values that this user has access to
#
# GET /mr-api/application/{id}/feature-environments/{key}
# operationId: getAllFeatureValuesByApplicationForKey
export def "mr-api-application-feature-environments get" [
  id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<environment: record<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, applicationId: string, name: string, priorEnvironmentId: string, version: int, description: string, production: bool, groupRoles: list, features: list, environmentInfo: any, webhookEnvironmentInfo: any, serviceAccountPermission: list, whenArchived: string>, roles: list<any>, featureValue: record<id: string, key: string, locked: bool, value: any, valueString: string, valueNumber: float, valueBoolean: bool, valueJson: string, retired: bool, rolloutStrategyInstances: list, rolloutStrategies: list, sharedRolloutStrategies: list, featureGroupStrategies: list, environmentId: string, version: int, whoUpdated: record, whenUpdated: string, whatUpdated: string>, serviceAccounts: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mr-api/application/($id)/feature-environments/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a list of all environments and features and their values that this user has access to
#
# PUT /mr-api/application/{id}/feature-environments/{key}
# operationId: updateAllFeatureValuesByApplicationForKey
export def "mr-api-application-feature-environments updateAllFeatureValuesByApplicationForKey" [
  id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --removeValuesNotPassed: oneof<nothing, bool> # The id of the application to find
  --body: record
]: any -> table<environment: record<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, applicationId: string, name: string, priorEnvironmentId: string, version: int, description: string, production: bool, groupRoles: list, features: list, environmentInfo: any, webhookEnvironmentInfo: any, serviceAccountPermission: list, whenArchived: string>, roles: list<any>, featureValue: record<id: string, key: string, locked: bool, value: any, valueString: string, valueNumber: float, valueBoolean: bool, valueJson: string, retired: bool, rolloutStrategyInstances: list, rolloutStrategies: list, sharedRolloutStrategies: list, featureGroupStrategies: list, environmentId: string, version: int, whoUpdated: record, whenUpdated: string, whatUpdated: string>, serviceAccounts: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "removeValuesNotPassed" $removeValuesNotPassed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/application/($id)/feature-environments/($key)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of all environments and features and their values that this user has access to
#
# GET /mr-api/application/{id}/all-feature-environment
# operationId: findAllFeatureAndFeatureValuesForEnvironmentsByApplication
export def "mr-api-application-all-feature-environment findAllFeatureAndFeatureValuesForEnvironmentsByApplication" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environmentIds: list # The environment ids to filter by. This should be limited to what the user is currently looking at or needing
  --filter: string # A filter to apply to the features - partial match of key or description
  --max: int # The maximum number of features to get for this page
  --page: int # The page number of the results. 0 indexed.
  --featureTypes: list
  --sortOrder: string@sortOrder-completer # nullable
  --featureFilter: list # If specified, limit the feature list by those that have these filters associated
]: nothing -> record<applicationId: string, features: table<id: string, key: string, alias: string, link: string, name: string, valueType: any, version: int, whenArchived: string, secret: bool, description: string, metaData: string, featureFilter: list>, environments: table<environmentId: string, environmentName: string, priorEnvironmentId: string, features: list, roles: list>, maxFeatures: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environmentIds" $environmentIds "multi") (serialize-qp "filter" $filter "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "featureTypes" $featureTypes "multi") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "featureFilter" $featureFilter "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/application/($id)/all-feature-environment" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# this api is designed to update the ordering of environments. it will error on circular references or environments that don't exist.
#
# POST /mr-api/application/{id}/environment-ordering
# operationId: environmentOrdering
export def "mr-api-application-environment-ordering environmentOrdering" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<createdBy: record<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, updatedBy: record<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, whenCreated: string, whenUpdated: string, id: string, applicationId: string, name: string, priorEnvironmentId: string, version: int, description: string, production: bool, groupRoles: list<record>, features: list<record>, environmentInfo: any, webhookEnvironmentInfo: any, serviceAccountPermission: list<record>, whenArchived: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mr-api/application/($id)/environment-ordering")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of environments.
#
# GET /mr-api/application/{id}/environment
# operationId: findEnvironments
export def "mr-api-application-environment findEnvironments" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer-1 # how to order the results
  --filter: string # What to filter the results by
  --includeAcls: oneof<nothing, bool> # Include the acls attached to this environment
  --includeFeatures: oneof<nothing, bool> # Include the features attached to this environment
  --includeDetails: oneof<nothing, bool> # Include all environment details
]: nothing -> table<createdBy: record<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, updatedBy: record<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, whenCreated: string, whenUpdated: string, id: string, applicationId: string, name: string, priorEnvironmentId: string, version: int, description: string, production: bool, groupRoles: list<record>, features: list<record>, environmentInfo: any, webhookEnvironmentInfo: any, serviceAccountPermission: list<record>, whenArchived: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "includeAcls" $includeAcls "scalar") (serialize-qp "includeFeatures" $includeFeatures "scalar") (serialize-qp "includeDetails" $includeDetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/application/($id)/environment" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new environment
#
# POST /mr-api/application/{id}/environment
# operationId: createEnvironmentOnApplication
export def "mr-api-application-environment createEnvironmentOnApplication" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --priorEnvironmentId: string # nullable, format: uuid
  description: string
  --environmentInfo: any # nullable
  --production: oneof<nothing, bool> # is this a production environment? (default: false)
]: any -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, applicationId: string, name: string, priorEnvironmentId: string, version: int, description: string, production: bool, groupRoles: table<environmentId: string, groupId: string, roles: list>, features: table<id: string, key: string, alias: string, link: string, name: string, valueType: any, version: int, whenArchived: string, secret: bool, description: string, metaData: string, featureFilter: list>, environmentInfo: any, webhookEnvironmentInfo: any, serviceAccountPermission: table<id: string, permissions: list, serviceAccount: record, environmentId: string, sdkUrlClientEval: string, sdkUrlServerEval: string>, whenArchived: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mr-api/application/($id)/environment")
  let body = {name: $name, priorEnvironmentId: $priorEnvironmentId, description: $description, environmentInfo: $environmentInfo, production: $production} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an environment
#
# PUT /mr-api/application/{id}/environment
# operationId: updateEnvironmentOnApplication
export def "mr-api-application-environment updateEnvironmentOnApplication" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeDetails: oneof<nothing, bool> # Include all environment details
  version: int # Version of the record, included for attempting to update out of date records (format: int64)
  --name: string # nullable
  --description: string # nullable
  --production: oneof<nothing, bool> # is this a production environment? (nullable)
  --environmentInfo: any # Allows some settings that affect the behaviour of this environment. Currently `cacheControl` if set will be passed and set on the responses to GET requests. (nullable)
  --webhookEnvironmentInfo: any # Environment webhook url and headers (nullable)
  --priorEnvironmentId: string # nullable, format: uuid
  --body-id: string # format: uuid
]: any -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, applicationId: string, name: string, priorEnvironmentId: string, version: int, description: string, production: bool, groupRoles: table<environmentId: string, groupId: string, roles: list>, features: table<id: string, key: string, alias: string, link: string, name: string, valueType: any, version: int, whenArchived: string, secret: bool, description: string, metaData: string, featureFilter: list>, environmentInfo: any, webhookEnvironmentInfo: any, serviceAccountPermission: table<id: string, permissions: list, serviceAccount: record, environmentId: string, sdkUrlClientEval: string, sdkUrlServerEval: string>, whenArchived: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeDetails" $includeDetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/application/($id)/environment" $qp)
  let body = {version: $version, name: $name, description: $description, production: $production, environmentInfo: $environmentInfo, webhookEnvironmentInfo: $webhookEnvironmentInfo, priorEnvironmentId: $priorEnvironmentId, id: $body_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the permissions of the current user for the specified application
#
# GET /mr-api/application/{id}/permissions
# operationId: applicationPermissions
export def "mr-api-application-permissions applicationPermissions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<applicationRoles: list<string>, environments: table<id: string, name: string, roles: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mr-api/application/($id)/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new environment - this is mounted at the wrong REST endpoint and is not assured to be maintained
#
# POST /mr-api/application/{id}/permissions
# DEPRECATED
# operationId: createEnvironment
@deprecated
export def "mr-api-application-permissions createEnvironment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --priorEnvironmentId: string # nullable, format: uuid
  description: string
  --environmentInfo: any # nullable
  --production: oneof<nothing, bool> # is this a production environment? (default: false)
]: any -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, applicationId: string, name: string, priorEnvironmentId: string, version: int, description: string, production: bool, groupRoles: table<environmentId: string, groupId: string, roles: list>, features: table<id: string, key: string, alias: string, link: string, name: string, valueType: any, version: int, whenArchived: string, secret: bool, description: string, metaData: string, featureFilter: list>, environmentInfo: any, webhookEnvironmentInfo: any, serviceAccountPermission: table<id: string, permissions: list, serviceAccount: record, environmentId: string, sdkUrlClientEval: string, sdkUrlServerEval: string>, whenArchived: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mr-api/application/($id)/permissions")
  let body = {name: $name, priorEnvironmentId: $priorEnvironmentId, description: $description, environmentInfo: $environmentInfo, production: $production} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an environment, prefer updateEnvironment on EnvironmentService
#
# PUT /mr-api/environment/{eid}/v2
# DEPRECATED
# operationId: updateEnvironmentV2
@deprecated
export def "mr-api-environment updateEnvironmentV2" [
  eid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeAcls: oneof<nothing, bool> # Include the acls attached to this environment
  --includeFeatures: oneof<nothing, bool> # Include the features attached to this environment
  --includeDetails: oneof<nothing, bool> # Include all environment details
  version: int # Version of the record, included for attempting to update out of date records (format: int64)
  --name: string # nullable
  --description: string # nullable
  --production: oneof<nothing, bool> # is this a production environment? (nullable)
  --environmentInfo: any # Allows some settings that affect the behaviour of this environment. Currently `cacheControl` if set will be passed and set on the responses to GET requests. (nullable)
  --webhookEnvironmentInfo: any # Environment webhook url and headers (nullable)
  --priorEnvironmentId: string # nullable, format: uuid
]: any -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, applicationId: string, name: string, priorEnvironmentId: string, version: int, description: string, production: bool, groupRoles: table<environmentId: string, groupId: string, roles: list>, features: table<id: string, key: string, alias: string, link: string, name: string, valueType: any, version: int, whenArchived: string, secret: bool, description: string, metaData: string, featureFilter: list>, environmentInfo: any, webhookEnvironmentInfo: any, serviceAccountPermission: table<id: string, permissions: list, serviceAccount: record, environmentId: string, sdkUrlClientEval: string, sdkUrlServerEval: string>, whenArchived: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeAcls" $includeAcls "scalar") (serialize-qp "includeFeatures" $includeFeatures "scalar") (serialize-qp "includeDetails" $includeDetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/environment/($eid)/v2" $qp)
  let body = {version: $version, name: $name, description: $description, production: $production, environmentInfo: $environmentInfo, webhookEnvironmentInfo: $webhookEnvironmentInfo, priorEnvironmentId: $priorEnvironmentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get environment
#
# GET /mr-api/environment/{eid}
# operationId: getEnvironment
export def "mr-api-environment get" [
  eid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeAcls: oneof<nothing, bool> # Include the acls attached to this environment
  --includeFeatures: oneof<nothing, bool> # Include the features attached to this environment
  --includeDetails: oneof<nothing, bool> # Include all environment details
  --decryptWebhookDetails: oneof<nothing, bool> # Decrypt all webhook env details
  --includeSdkUrl: oneof<nothing, bool> # include the sdk url
  --includeServiceAccounts: oneof<nothing, bool> # Include the service accounts attached to this environment
]: nothing -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, applicationId: string, name: string, priorEnvironmentId: string, version: int, description: string, production: bool, groupRoles: table<environmentId: string, groupId: string, roles: list>, features: table<id: string, key: string, alias: string, link: string, name: string, valueType: any, version: int, whenArchived: string, secret: bool, description: string, metaData: string, featureFilter: list>, environmentInfo: any, webhookEnvironmentInfo: any, serviceAccountPermission: table<id: string, permissions: list, serviceAccount: record, environmentId: string, sdkUrlClientEval: string, sdkUrlServerEval: string>, whenArchived: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeAcls" $includeAcls "scalar") (serialize-qp "includeFeatures" $includeFeatures "scalar") (serialize-qp "includeDetails" $includeDetails "scalar") (serialize-qp "decryptWebhookDetails" $decryptWebhookDetails "scalar") (serialize-qp "includeSdkUrl" $includeSdkUrl "scalar") (serialize-qp "includeServiceAccounts" $includeServiceAccounts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/environment/($eid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an environment. Please use updateEnvironment
#
# PUT /mr-api/environment/{eid}
# DEPRECATED
# operationId: updateEnvironment
# --groupRoles item shape: {environmentId: string, groupId: string, roles: list}
# --features item shape: {id?: string, key?: string, alias?: string, link?: string, name: string, valueType?: any, version?: int, whenArchived?: string, secret?: bool, description?: string, metaData?: string, featureFilter?: list}
# --serviceAccountPermission item shape: {id?: string, permissions: list, serviceAccount?: any, environmentId: string, sdkUrlClientEval?: string, sdkUrlServerEval?: string}
@deprecated
export def "mr-api-environment updateEnvironment" [
  eid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeAcls: oneof<nothing, bool> # Include the acls attached to this environment
  --includeFeatures: oneof<nothing, bool> # Include the features attached to this environment
  --includeDetails: oneof<nothing, bool> # Include all environment details
  --decryptWebhookDetails: oneof<nothing, bool> # Decrypt all webhook env details
  --createdBy: any # nullable
  --updatedBy: any # nullable
  --whenCreated: string # nullable, format: date-time
  --whenUpdated: string # nullable, format: date-time
  id: string # format: uuid
  --applicationId: string # format: uuid
  name: string
  --priorEnvironmentId: string # nullable, format: uuid
  --version: int # format: int64
  --description: string # nullable
  --production: oneof<nothing, bool> # is this a production environment? (nullable)
  --groupRoles: list # nullable, default: [] — item shape: {environmentId: string, groupId: string, roles: list}
  --features: list # nullable, default: [] — item shape: {id?: string, key?: string, alias?: string, link?: string, name: string, valueType?: any, version?: int, whenArchived?: string, secret?: bool, description?: string, metaData?: string, featureFilter?: list}
  --environmentInfo: any # nullable, default: {}
  --webhookEnvironmentInfo: any # nullable
  --serviceAccountPermission: list # nullable — item shape: {id?: string, permissions: list, serviceAccount?: any, environmentId: string, sdkUrlClientEval?: string, sdkUrlServerEval?: string}
  --whenArchived: string # nullable, format: date-time
]: any -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, applicationId: string, name: string, priorEnvironmentId: string, version: int, description: string, production: bool, groupRoles: table<environmentId: string, groupId: string, roles: list>, features: table<id: string, key: string, alias: string, link: string, name: string, valueType: any, version: int, whenArchived: string, secret: bool, description: string, metaData: string, featureFilter: list>, environmentInfo: any, webhookEnvironmentInfo: any, serviceAccountPermission: table<id: string, permissions: list, serviceAccount: record, environmentId: string, sdkUrlClientEval: string, sdkUrlServerEval: string>, whenArchived: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeAcls" $includeAcls "scalar") (serialize-qp "includeFeatures" $includeFeatures "scalar") (serialize-qp "includeDetails" $includeDetails "scalar") (serialize-qp "decryptWebhookDetails" $decryptWebhookDetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/environment/($eid)" $qp)
  let body = {createdBy: $createdBy, updatedBy: $updatedBy, whenCreated: $whenCreated, whenUpdated: $whenUpdated, id: $id, applicationId: $applicationId, name: $name, priorEnvironmentId: $priorEnvironmentId, version: $version, description: $description, production: $production, groupRoles: $groupRoles, features: $features, environmentInfo: $environmentInfo, webhookEnvironmentInfo: $webhookEnvironmentInfo, serviceAccountPermission: $serviceAccountPermission, whenArchived: $whenArchived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an environment
#
# DELETE /mr-api/environment/{eid}
# operationId: deleteEnvironment
export def "mr-api-environment delete" [
  eid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeAcls: oneof<nothing, bool> # Include the acls attached to this environment
  --includeFeatures: oneof<nothing, bool> # Include the features attached to this environment
  --includeDetails: oneof<nothing, bool> # Include all environment details
  --decryptWebhookDetails: oneof<nothing, bool> # Decrypt all webhook env details
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeAcls" $includeAcls "scalar") (serialize-qp "includeFeatures" $includeFeatures "scalar") (serialize-qp "includeDetails" $includeDetails "scalar") (serialize-qp "decryptWebhookDetails" $decryptWebhookDetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/environment/($eid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all features for this environment
#
# GET /mr-api/features/{eid}
# operationId: getFeaturesForEnvironment
export def "mr-api-features get" [
  eid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeFeatures: oneof<nothing, bool> # include the features in the result
  --filter: string # Filter the feature names by this filter.
]: nothing -> record<featureValues: table<id: string, key: string, locked: bool, value: any, valueString: string, valueNumber: float, valueBoolean: bool, valueJson: string, retired: bool, rolloutStrategyInstances: list, rolloutStrategies: list, sharedRolloutStrategies: list, featureGroupStrategies: list, environmentId: string, version: int, whoUpdated: record, whenUpdated: string, whatUpdated: string>, environments: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, applicationId: string, name: string, priorEnvironmentId: string, version: int, description: string, production: bool, groupRoles: list, features: list, environmentInfo: any, webhookEnvironmentInfo: any, serviceAccountPermission: list, whenArchived: string>, applications: table<createdBy: record, updatedBy: record, whenCreated: string, whenUpdated: string, id: string, name: string, description: string, portfolioId: string, version: int, groups: list, features: list, environments: list, whenArchived: string>, features: table<id: string, key: string, alias: string, link: string, name: string, valueType: any, version: int, whenArchived: string, secret: bool, description: string, metaData: string, featureFilter: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeFeatures" $includeFeatures "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/features/($eid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update all features for this environment that are passed. Ignores any other feature values that are not passed.
#
# PUT /mr-api/features/{eid}
# operationId: updateAllFeaturesForEnvironment
export def "mr-api-features updateAllFeaturesForEnvironment" [
  eid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<id: string, key: string, locked: bool, value: any, valueString: string, valueNumber: float, valueBoolean: bool, valueJson: string, retired: bool, rolloutStrategyInstances: list<record>, rolloutStrategies: list<record>, sharedRolloutStrategies: list<record>, featureGroupStrategies: list<record>, environmentId: string, version: int, whoUpdated: record<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, whenUpdated: string, whatUpdated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mr-api/features/($eid)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a specific feature in this environment.
#
# GET /mr-api/features/{eid}/feature/{key}
# operationId: getFeatureForEnvironment
export def "mr-api-features-feature get" [
  eid: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, key: string, locked: bool, value: any, valueString: string, valueNumber: float, valueBoolean: bool, valueJson: string, retired: bool, rolloutStrategyInstances: table<name: string, strategyId: string, value: any, disabled: bool>, rolloutStrategies: table<id: string>, sharedRolloutStrategies: table<id: string>, featureGroupStrategies: table<name: string, value: any, featureGroupId: string>, environmentId: string, version: int, whoUpdated: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenUpdated: string, whatUpdated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mr-api/features/($eid)/feature/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific feature in this environment.
#
# PUT /mr-api/features/{eid}/feature/{key}
# operationId: updateFeatureForEnvironment
# --rolloutStrategyInstances item shape: {name?: string, strategyId?: string, value?: any, disabled?: bool}
# --rolloutStrategies item shape: {id?: string}
# --sharedRolloutStrategies item shape: {id?: string}
# --featureGroupStrategies item shape: {name?: string, value?: any, featureGroupId?: string}
@deprecated --flag valueString
@deprecated --flag valueNumber
@deprecated --flag valueBoolean
@deprecated --flag valueJson
export def "mr-api-features-feature updateFeatureForEnvironment" [
  eid: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable, format: uuid
  --body-key: string
  --locked: oneof<nothing, bool>
  --value: any # Preferred now, please don't use valueX fields
  --valueString: string # default value if no strategy matches. interpreted by type in parent (DEPRECATED, nullable)
  --valueNumber: float # DEPRECATED, nullable
  --valueBoolean: oneof<nothing, bool> # DEPRECATED, nullable
  --valueJson: string # DEPRECATED, nullable
  --retired: oneof<nothing, bool> # if false or null, this feature will visible on edge. if true, it will not be passed to the client (default: false)
  --rolloutStrategyInstances: list # nullable, default: [] — item shape: {name?: string, strategyId?: string, value?: any, disabled?: bool}
  --rolloutStrategies: list # These are custom rollout strategies that only apply to this feature value. (nullable, default: []) — item shape: {id?: string}
  --sharedRolloutStrategies: list # This is list is either provided empty (when publishing) or anemic so the MR will client will understand which shared strategies are attached without having to back-call. If provided then it will mirror rolloutStrategyInstances and only enabled ones will be passed back. The value from the rolloutStrategyInstance will be embedded. This field will _always_ be ignored when being sent back to the server, only rolloutStrategyInstances is used. (nullable, default: []) — item shape: {id?: string}
  --featureGroupStrategies: list # There are strategies provided by feature groups (if any) (nullable, default: []) — item shape: {name?: string, value?: any, featureGroupId?: string}
  --environmentId: string # nullable, format: uuid
  --version: int # used for optimistic locking. we set it to 0 for the initial version (format: int64, default: 0)
  --whoUpdated: any # nullable
  --whenUpdated: string # nullable, format: date-time
  --whatUpdated: string # nullable
]: any -> record<id: string, key: string, locked: bool, value: any, valueString: string, valueNumber: float, valueBoolean: bool, valueJson: string, retired: bool, rolloutStrategyInstances: table<name: string, strategyId: string, value: any, disabled: bool>, rolloutStrategies: table<id: string>, sharedRolloutStrategies: table<id: string>, featureGroupStrategies: table<name: string, value: any, featureGroupId: string>, environmentId: string, version: int, whoUpdated: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenUpdated: string, whatUpdated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mr-api/features/($eid)/feature/($key)")
  let body = {id: $id, key: $body_key, locked: $locked, value: $value, valueString: $valueString, valueNumber: $valueNumber, valueBoolean: $valueBoolean, valueJson: $valueJson, retired: $retired, rolloutStrategyInstances: $rolloutStrategyInstances, rolloutStrategies: $rolloutStrategies, sharedRolloutStrategies: $sharedRolloutStrategies, featureGroupStrategies: $featureGroupStrategies, environmentId: $environmentId, version: $version, whoUpdated: $whoUpdated, whenUpdated: $whenUpdated, whatUpdated: $whatUpdated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a specific feature in this environment.
#
# POST /mr-api/features/{eid}/feature/{key}
# operationId: createFeatureForEnvironment
# --rolloutStrategyInstances item shape: {name?: string, strategyId?: string, value?: any, disabled?: bool}
# --rolloutStrategies item shape: {id?: string}
# --sharedRolloutStrategies item shape: {id?: string}
# --featureGroupStrategies item shape: {name?: string, value?: any, featureGroupId?: string}
@deprecated --flag valueString
@deprecated --flag valueNumber
@deprecated --flag valueBoolean
@deprecated --flag valueJson
export def "mr-api-features-feature createFeatureForEnvironment" [
  eid: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable, format: uuid
  --body-key: string
  --locked: oneof<nothing, bool>
  --value: any # Preferred now, please don't use valueX fields
  --valueString: string # default value if no strategy matches. interpreted by type in parent (DEPRECATED, nullable)
  --valueNumber: float # DEPRECATED, nullable
  --valueBoolean: oneof<nothing, bool> # DEPRECATED, nullable
  --valueJson: string # DEPRECATED, nullable
  --retired: oneof<nothing, bool> # if false or null, this feature will visible on edge. if true, it will not be passed to the client (default: false)
  --rolloutStrategyInstances: list # nullable, default: [] — item shape: {name?: string, strategyId?: string, value?: any, disabled?: bool}
  --rolloutStrategies: list # These are custom rollout strategies that only apply to this feature value. (nullable, default: []) — item shape: {id?: string}
  --sharedRolloutStrategies: list # This is list is either provided empty (when publishing) or anemic so the MR will client will understand which shared strategies are attached without having to back-call. If provided then it will mirror rolloutStrategyInstances and only enabled ones will be passed back. The value from the rolloutStrategyInstance will be embedded. This field will _always_ be ignored when being sent back to the server, only rolloutStrategyInstances is used. (nullable, default: []) — item shape: {id?: string}
  --featureGroupStrategies: list # There are strategies provided by feature groups (if any) (nullable, default: []) — item shape: {name?: string, value?: any, featureGroupId?: string}
  --environmentId: string # nullable, format: uuid
  --version: int # used for optimistic locking. we set it to 0 for the initial version (format: int64, default: 0)
  --whoUpdated: any # nullable
  --whenUpdated: string # nullable, format: date-time
  --whatUpdated: string # nullable
]: any -> record<id: string, key: string, locked: bool, value: any, valueString: string, valueNumber: float, valueBoolean: bool, valueJson: string, retired: bool, rolloutStrategyInstances: table<name: string, strategyId: string, value: any, disabled: bool>, rolloutStrategies: table<id: string>, sharedRolloutStrategies: table<id: string>, featureGroupStrategies: table<name: string, value: any, featureGroupId: string>, environmentId: string, version: int, whoUpdated: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenUpdated: string, whatUpdated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mr-api/features/($eid)/feature/($key)")
  let body = {id: $id, key: $body_key, locked: $locked, value: $value, valueString: $valueString, valueNumber: $valueNumber, valueBoolean: $valueBoolean, valueJson: $valueJson, retired: $retired, rolloutStrategyInstances: $rolloutStrategyInstances, rolloutStrategies: $rolloutStrategies, sharedRolloutStrategies: $sharedRolloutStrategies, featureGroupStrategies: $featureGroupStrategies, environmentId: $environmentId, version: $version, whoUpdated: $whoUpdated, whenUpdated: $whenUpdated, whatUpdated: $whatUpdated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# No longer supported. Please update to a null value.
#
# DELETE /mr-api/features/{eid}/feature/{key}
# operationId: deleteFeatureForEnvironment
export def "mr-api-features-feature delete" [
  eid: string
  key: string
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
  let full_url = (build-url $base $"/mr-api/features/($eid)/feature/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get group
#
# GET /mr-api/group/{gid}
# operationId: getGroup
export def "mr-api-group get" [
  gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeMembers: oneof<nothing, bool> # include people in each group (v1) - uses Members
  --includeMembersV2: oneof<nothing, bool> # include people in each group (v2) - uses GroupMember instead of Members
  --includeGroupRoles: oneof<nothing, bool> # include environment and application roles in each group
  --byApplicationId: string # format: uuid
]: nothing -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<any>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<any>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list<string>, simpleMembers: table<id: string, name: string, email: string, type: string>, members: table<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, applicationRoles: table<applicationId: string, groupId: string, roles: list>, environmentRoles: table<environmentId: string, groupId: string, roles: list>, whenArchived: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeMembers" $includeMembers "scalar") (serialize-qp "includeMembersV2" $includeMembersV2 "scalar") (serialize-qp "includeGroupRoles" $includeGroupRoles "scalar") (serialize-qp "byApplicationId" $byApplicationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/group/($gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a group
#
# DELETE /mr-api/group/{gid}
# operationId: deleteGroup
export def "mr-api-group delete" [
  gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeMembers: oneof<nothing, bool> # include people in each group (v1) - uses Members
  --includeMembersV2: oneof<nothing, bool> # include people in each group (v2) - uses GroupMember instead of Members
  --includeGroupRoles: oneof<nothing, bool> # include environment and application roles in each group
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeMembers" $includeMembers "scalar") (serialize-qp "includeMembersV2" $includeMembersV2 "scalar") (serialize-qp "includeGroupRoles" $includeGroupRoles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/group/($gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a persons to a group
#
# POST /mr-api/group/{gid}/person
# operationId: addPersonsToGroup
export def "mr-api-group-person addPersonsToGroup" [
  gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeMembersV2: oneof<nothing, bool> # include anemic people in each group with superuser info
  --personId: list
  --email: list
]: nothing -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<any>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<any>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list<string>, simpleMembers: table<id: string, name: string, email: string, type: string>, members: table<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, applicationRoles: table<applicationId: string, groupId: string, roles: list>, environmentRoles: table<environmentId: string, groupId: string, roles: list>, whenArchived: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeMembersV2" $includeMembersV2 "scalar") (serialize-qp "personId" $personId "multi") (serialize-qp "email" $email "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/group/($gid)/person" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a person to a group
#
# POST /mr-api/group/{gid}/person/{pId}
# operationId: addPersonToGroup
export def "mr-api-group-person addPersonToGroup" [
  gid: string
  pId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeMembers: oneof<nothing, bool> # include people in each group
  --includeMembersV2: oneof<nothing, bool> # include anemic people in each group with superuser info
]: nothing -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<any>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<any>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list<string>, simpleMembers: table<id: string, name: string, email: string, type: string>, members: table<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, applicationRoles: table<applicationId: string, groupId: string, roles: list>, environmentRoles: table<environmentId: string, groupId: string, roles: list>, whenArchived: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeMembers" $includeMembers "scalar") (serialize-qp "includeMembersV2" $includeMembersV2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/group/($gid)/person/($pId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a person from a group
#
# DELETE /mr-api/group/{gid}/person/{pId}
# operationId: deletePersonFromGroup
export def "mr-api-group-person delete" [
  gid: string
  pId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeMembers: oneof<nothing, bool> # include people in each group
  --includeMembersV2: oneof<nothing, bool> # include anemic people in each group with superuser info
]: nothing -> record<createdBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<any>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, updatedBy: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<any>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>, whenCreated: string, whenUpdated: string, id: string, admin: bool, portfolioId: string, organizationId: string, version: int, name: string, superMembers: list<string>, simpleMembers: table<id: string, name: string, email: string, type: string>, members: table<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, applicationRoles: table<applicationId: string, groupId: string, roles: list>, environmentRoles: table<environmentId: string, groupId: string, roles: list>, whenArchived: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeMembers" $includeMembers "scalar") (serialize-qp "includeMembersV2" $includeMembersV2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/group/($gid)/person/($pId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of all service accounts this user can see
#
# GET /mr-api/portfolio/{id}/service-account
# operationId: searchServiceAccountsInPortfolio
export def "mr-api-portfolio-service-account searchServiceAccountsInPortfolio" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includePermissions: oneof<nothing, bool> # include permissions in return
  --filter: string # include environments for each account
  --applicationId: string # Application ID to filter on (format: uuid)
  --includeSdkUrls: oneof<nothing, bool> # Include the SDKs for environments the user has access to
]: nothing -> table<id: string, name: string, portfolioId: string, description: string, version: int, apiKeyClientSide: string, apiKeyServerSide: string, featureFilters: list<string>, permsInvalid: bool, permissions: list<record>, whenArchived: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includePermissions" $includePermissions "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "applicationId" $applicationId "scalar") (serialize-qp "includeSdkUrls" $includeSdkUrls "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/portfolio/($id)/service-account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new service account
#
# POST /mr-api/portfolio/{id}/service-account
# operationId: createServiceAccountInPortfolio
# --permissions item shape: {id?: string, permissions: list, serviceAccount?: any, environmentId: string, sdkUrlClientEval?: string, sdkUrlServerEval?: string}
export def "mr-api-portfolio-service-account createServiceAccountInPortfolio" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includePermissions: oneof<nothing, bool> # include permissions in return
  name: string
  --description: string # nullable
  --featureFilter: list # The ID's of Filters associated with this service account (nullable)
  --permissions: list # default: [] — item shape: {id?: string, permissions: list, serviceAccount?: any, environmentId: string, sdkUrlClientEval?: string, sdkUrlServerEval?: string}
]: any -> record<id: string, name: string, portfolioId: string, description: string, version: int, apiKeyClientSide: string, apiKeyServerSide: string, featureFilters: list<string>, permsInvalid: bool, permissions: table<id: string, permissions: list, serviceAccount: record, environmentId: string, sdkUrlClientEval: string, sdkUrlServerEval: string>, whenArchived: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includePermissions" $includePermissions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/portfolio/($id)/service-account" $qp)
  let body = {name: $name, description: $description, featureFilter: $featureFilter, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update this service account, overwiting any attached environment permissions this user has access to
#
# PUT /mr-api/portfolio/{id}/service-account
# operationId: updateServiceAccountOnPortfolio
# --permissions item shape: {id?: string, permissions: list, serviceAccount?: any, environmentId: string, sdkUrlClientEval?: string, sdkUrlServerEval?: string}
export def "mr-api-portfolio-service-account updateServiceAccountOnPortfolio" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includePermissions: oneof<nothing, bool> # include permissions in return
  --appId: string # limit removals to this application id (format: uuid)
  --body-id: string # format: uuid
  name: string
  --portfolioId: string # nullable, format: uuid
  --description: string # nullable
  --version: int # nullable, format: int64
  --apiKeyClientSide: string # this is a read only field, it denotes an api key where the eval is done client side (nullable)
  --apiKeyServerSide: string # this is a read only field, it denotes an api key where the eval is done server side (nullable)
  --featureFilters: list # nullable
  --permsInvalid: oneof<nothing, bool> # If this is true, then the permissions does not hold the actual permissions of the service account and should be ignored on update. It is set by the server and can be set on the client when calling update methods for service accounts. This is because the permissions field is always an array, it is not nullable. NULL or FALSE means the permissions field is valid and is the default behaviour. TRUE is new and is recognized by the server to not try and update permissions. (nullable)
  --permissions: list # default: [] — item shape: {id?: string, permissions: list, serviceAccount?: any, environmentId: string, sdkUrlClientEval?: string, sdkUrlServerEval?: string}
  --whenArchived: string # nullable, format: date-time
]: any -> record<id: string, name: string, portfolioId: string, description: string, version: int, apiKeyClientSide: string, apiKeyServerSide: string, featureFilters: list<string>, permsInvalid: bool, permissions: table<id: string, permissions: list, serviceAccount: record, environmentId: string, sdkUrlClientEval: string, sdkUrlServerEval: string>, whenArchived: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includePermissions" $includePermissions "scalar") (serialize-qp "appId" $appId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/portfolio/($id)/service-account" $qp)
  let body = {id: $body_id, name: $name, portfolioId: $portfolioId, description: $description, version: $version, apiKeyClientSide: $apiKeyClientSide, apiKeyServerSide: $apiKeyServerSide, featureFilters: $featureFilters, permsInvalid: $permsInvalid, permissions: $permissions, whenArchived: $whenArchived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get service account by id or 'self' if authenticated as this service account
#
# GET /mr-api/service-account/{id}
# operationId: getServiceAccount
export def "mr-api-service-account get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includePermissions: oneof<nothing, bool> # include permissions in return
  --includeFilters: oneof<nothing, bool> # include filters in return
  --byApplicationId: string # format: uuid
]: nothing -> record<id: string, name: string, portfolioId: string, description: string, version: int, apiKeyClientSide: string, apiKeyServerSide: string, featureFilters: list<string>, permsInvalid: bool, permissions: table<id: string, permissions: list, serviceAccount: record, environmentId: string, sdkUrlClientEval: string, sdkUrlServerEval: string>, whenArchived: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includePermissions" $includePermissions "scalar") (serialize-qp "includeFilters" $includeFilters "scalar") (serialize-qp "byApplicationId" $byApplicationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/service-account/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update this service account, overwiting any attached environment permissions this user has access to
#
# PUT /mr-api/service-account/{id}
# DEPRECATED
# operationId: updateServiceAccount
# --permissions item shape: {id?: string, permissions: list, serviceAccount?: any, environmentId: string, sdkUrlClientEval?: string, sdkUrlServerEval?: string}
@deprecated
export def "mr-api-service-account updateServiceAccount" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includePermissions: oneof<nothing, bool> # include permissions in return
  --body-id: string # format: uuid
  name: string
  --portfolioId: string # nullable, format: uuid
  --description: string # nullable
  --version: int # nullable, format: int64
  --apiKeyClientSide: string # this is a read only field, it denotes an api key where the eval is done client side (nullable)
  --apiKeyServerSide: string # this is a read only field, it denotes an api key where the eval is done server side (nullable)
  --featureFilters: list # nullable
  --permsInvalid: oneof<nothing, bool> # If this is true, then the permissions does not hold the actual permissions of the service account and should be ignored on update. It is set by the server and can be set on the client when calling update methods for service accounts. This is because the permissions field is always an array, it is not nullable. NULL or FALSE means the permissions field is valid and is the default behaviour. TRUE is new and is recognized by the server to not try and update permissions. (nullable)
  --permissions: list # default: [] — item shape: {id?: string, permissions: list, serviceAccount?: any, environmentId: string, sdkUrlClientEval?: string, sdkUrlServerEval?: string}
  --whenArchived: string # nullable, format: date-time
]: any -> record<id: string, name: string, portfolioId: string, description: string, version: int, apiKeyClientSide: string, apiKeyServerSide: string, featureFilters: list<string>, permsInvalid: bool, permissions: table<id: string, permissions: list, serviceAccount: record, environmentId: string, sdkUrlClientEval: string, sdkUrlServerEval: string>, whenArchived: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includePermissions" $includePermissions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/service-account/($id)" $qp)
  let body = {id: $body_id, name: $name, portfolioId: $portfolioId, description: $description, version: $version, apiKeyClientSide: $apiKeyClientSide, apiKeyServerSide: $apiKeyServerSide, featureFilters: $featureFilters, permsInvalid: $permsInvalid, permissions: $permissions, whenArchived: $whenArchived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete this service account, cascade removes all permissions
#
# DELETE /mr-api/service-account/{id}
# operationId: deleteServiceAccount
export def "mr-api-service-account delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mr-api/service-account/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Causes a new API Key to be generated. Ensure you confirm this with the user.
#
# POST /mr-api/service-account/{id}/reset-api-key
# operationId: resetApiKey
export def "mr-api-service-account-reset-api-key resetApiKey" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKeyType: string@apiKeyType-completer # Type of the API key
]: nothing -> record<id: string, name: string, portfolioId: string, description: string, version: int, apiKeyClientSide: string, apiKeyServerSide: string, featureFilters: list<string>, permsInvalid: bool, permissions: table<id: string, permissions: list, serviceAccount: record, environmentId: string, sdkUrlClientEval: string, sdkUrlServerEval: string>, whenArchived: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiKeyType" $apiKeyType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mr-api/service-account/($id)/reset-api-key" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ping Feature Hub
#
# GET /mr-api/initialize
# operationId: isInstalled
export def "mr-api-initialize isInstalled" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<organization: record<createdBy: record<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, updatedBy: record<id: record, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list>, whenCreated: string, whenUpdated: string, id: string, version: int, name: string, admin: bool, authorizationUrl: string, orgGroup: record, portfolios: list<record>, whenArchived: string>, providers: list<string>, providerInfo: record, capabilityInfo: any, redirectUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mr-api/initialize")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Setup site admin
#
# POST /mr-api/initialize
# operationId: setupSiteAdmin
export def "mr-api-initialize setupSiteAdmin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  portfolio: string
  organizationName: string
  --emailAddress: string # User's email or blank if using oauth/saml (nullable, format: email)
  --password: string # User's password or blank if using oauth/saml (nullable)
  --name: string # user's name. Will be take from external provider if using oauth/saml (nullable)
  --authProvider: string # If the site is using external providers, this is the key of the provider chosen. If there is only one, it can be blank. (nullable)
]: any -> record<accessToken: string, refreshToken: string, redirectUrl: string, capabilityInfo: any, person: record<id: record<id: string>, name: string, email: string, personType: record, other: string, source: string, version: int, passwordRequiresReset: bool, groups: list<record>, whenArchived: string, whenLastAuthenticated: string, whenLastSeen: string, additional: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mr-api/initialize")
  let body = {portfolio: $portfolio, organizationName: $organizationName, emailAddress: $emailAddress, password: $password, name: $name, authProvider: $authProvider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
