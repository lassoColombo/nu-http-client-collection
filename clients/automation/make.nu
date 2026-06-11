# Auto-generated client for Web API v2 - Public  v1.0.0
# Source: https://eu1.make.com/api/v2/openapi.json
# Auth: --token flag or $env.WEB_API_V2_PUBLIC_TOKEN

const BASE_URL = "https://eu1.make.com/api/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WEB_API_V2_PUBLIC_TOKEN | default "" }
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
def base-url-completer [] { ["https://eu1.make.com/api/v2" "https://eu2.make.com/api/v2" "https://us1.make.com/api/v2" "https://us2.make.com/api/v2" "https://eu1.make.celonis.com/api/v2" "https://us1.make.celonis.com/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def pgsortBy-completer [] { ["name"] }
def pgsortDir-completer [] { ["asc" "desc"] }
def pgsortBy-completer-1 [] { ["createdAt"] }
def pgsortBy-completer-2 [] { ["id" "name" "userAdminsRoleId"] }
def tfaStatus-completer [] { ["0" "1" "2"] }
def pgsortBy-completer-3 [] { ["email" "id" "name" "userAdminsRoleId"] }
def type-completer [] { ["email" "id"] }
def category-completer [] { ["developers" "support" "system"] }
def pgsortBy-completer-4 [] { ["actor" "createdAt" "eventName" "organization" "targetId" "team" "triggeredAt"] }
def pgsortBy-completer-5 [] { ["errorRate" "errorRateChange" "errors" "errorsChange" "executions" "executionsChange" "name" "operations" "operationsChange" "status" "teamName"] }
def type-completer-1 [] { ["EXTRA" "PLAN"] }
def status-completer [] { ["authorized" "declined" "incomplete" "invalid" "partially_authorized" "pending"] }
def pgsortBy-completer-6 [] { ["description" "id" "label" "name" "required" "type"] }
def type-completer-2 [] { ["boolean" "date" "dropdown" "longText" "multiselect" "number" "shortText"] }
def status-completer-1 [] { ["1" "2" "3"] }
def typeName-completer [] { ["aes-key" "apikeyauth" "apn" "basicauth" "clientcertauth" "eet" "gpg-private" "gpg-public" "webpay"] }
def pgsortBy-completer-7 [] { ["id"] }
def target-completer [] { ["both" "extras" "subscription"] }
def type-completer-3 [] { ["scenario" "tool"] }
def pgsortBy-completer-8 [] { ["created" "createdByUserName" "folderId" "id" "isActive" "isinvalid" "islinked" "islocked" "lastEdit" "name" "proprietal" "teamId" "updatedByUserName"] }
def pgsortBy-completer-9 [] { ["createdAt" "id" "title" "updated"] }
def typeId-completer [] { ["1" "10" "11" "12" "4" "9"] }
def moduleInitMode-completer [] { ["blank" "example" "module"] }
def type-completer-4 [] { ["apikey" "basic" "oauth" "oauth-1" "oauth-clicre" "oauth-refresh" "oauth-resowncre" "other"] }
def aiMappingBuiltinTier-completer [] { ["large" "medium" "small"] }
def aiToolkitBuiltinTier-completer [] { ["large" "medium" "small"] }
def pgsortBy-completer-10 [] { ["email" "id" "name"] }
def type-completer-5 [] { ["company" "organization"] }
def permissionType-completer [] { ["organization" "team"] }
def category-completer-1 [] { ["organization" "team"] }
def roleCategory-completer [] { ["organization" "team"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "login post" } } | get name | first)
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

# Log in
#
# POST /login
export def "login post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # format: email
  password: string # format: password
]: any -> record<userId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/login")
  let body = {email: $email, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Log out
#
# POST /logout
export def "logout post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ok: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Authorize URL
#
# POST /sso/authorize
export def "sso-authorize post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  redirect: string
]: any -> record<authorizeUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sso/authorize")
  let body = {redirect: $redirect} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# OAuth login
#
# POST /sso/login
export def "sso-login post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  code: string
  state: string
]: any -> record<redirect: string, redirectAction: record<action: string, data: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sso/login")
  let body = {code: $code, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List teams
#
# GET /admin/teams
export def "admin-teams get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int # The ID of the organization. (e.g. 22)
  --externalId: string # Custom team ID from an external system to the Make White Label platform.
  --pgsortBy: string@pgsortBy-completer # The value that will be used to sort returned entities by.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<teams: table<id: int, name: string, organizationId: int, scenarioDrafts: bool, deleted: bool, externalId: string>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar") (serialize-qp "externalId" $externalId "scalar") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a team
#
# POST /admin/teams
export def "admin-teams post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the team.
  organizationId: int # The ID of the organization.
  --userTeamAdmin: int # Set the user with the specified `userId` as the admin of the team.
]: any -> record<team: record<id: int, name: string, organizationId: int, operationsLimit: int, transferLimit: any>, userTeamRole: record<usersRoleId: int, userId: int, teamId: int, changeable: bool, ssoPending: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/teams")
  let body = {name: $name, organizationId: $organizationId, userTeamAdmin: $userTeamAdmin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update team
#
# PATCH /admin/teams/{teamId}
export def "admin-teams patch" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the team.
]: any -> record<team: record<id: int, name: string, organizationId: int, scenarioDrafts: bool, deleted: bool, externalId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/teams/($teamId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a team
#
# DELETE /admin/teams/{teamId}
export def "admin-teams delete" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<team: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/teams/($teamId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organizations
#
# GET /admin/organizations
export def "admin-organizations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # The ID of the organization.
  --name: string # The name of the organization.
  --externalId: string # Custom organization ID from a different system than Make White Label.
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
  --pgsortBy: string # The value that will be used to sort returned entities by.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<organizations: table<id: int, name: string, timezoneId: float, countryId: float, license: record, serviceName: string, teams: list, isPaused: bool, zone: string, externalId: string, scenarios: int, activeScenarios: int, deleted: bool>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "externalId" $externalId "scalar") (serialize-qp "cols" $cols "multi") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an organization
#
# POST /admin/organizations
export def "admin-organizations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the organization.
  --timezoneId: int # The ID of the timezone associated with the organization. Get the list of the timezone IDs with the API call `GET /enums/timezones`.
  --countryId: int # The ID of the country associated with the organization. Get the list of the country IDs with the API call `GET /enums/countries`.
  --userOrgAdmin: int # The ID of the user who will be the admin of the organization. Get the list of the user IDs with the API call `GET /admin/users`.
  --license: record # The resources and features available to the users in the organization.
]: any -> record<organization: record<id: int, name: string, createdAt: string, serviceName: string, nextReset: string, lastReset: string, isPaused: bool, countryId: int, timezoneId: int, deleted: bool, license: record, zone: string, teams: list<record>, productName: string, ssoType: string, scenarios: int, activeScenarios: int, tfaEnforced: bool, featureControls: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/organizations")
  let body = {name: $name, timezoneId: $timezoneId, countryId: $countryId, userOrgAdmin: $userOrgAdmin, license: $license} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update organization
#
# PATCH /admin/organizations/{organizationId}
export def "admin-organizations patch" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the organization.
  --timezoneId: int # The ID of the timezone associated with the organization. Get the list of the timezone IDs with the API call `GET /enums/timezones`.
  --countryId: int # The ID of the country associated with the organization. Get the list of the country IDs with the API call `GET /enums/countries`.
  --nextReset: string # The moment to which you want to schedule the reset of the organization's consumption. (format: date-time)
  --performReset: string@bool-completer # Set to `true` if you want to reset the organization's consumption with the API call. Make sets the next reset of the organization's consumption either to the moment from the `nextReset` parameter, or according to the organization's restart period.
  --license: record # The resources and features available to the users in the organization.
]: any -> record<organization: record<id: int, name: string, createdAt: string, serviceName: string, nextReset: string, lastReset: string, isPaused: bool, countryId: int, timezoneId: int, deleted: bool, license: record, zone: string, teams: list<record>, productName: string, ssoType: string, scenarios: int, activeScenarios: int, tfaEnforced: bool, featureControls: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/organizations/($organizationId)")
  let body = {name: $name, timezoneId: $timezoneId, countryId: $countryId, nextReset: $nextReset, performReset: $performReset, license: $license} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an organization
#
# DELETE /admin/organizations/{organizationId}
export def "admin-organizations delete" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/organizations/($organizationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get billing audit logs
#
# GET /admin/organizations/{organizationId}/billing-audit-logs
export def "admin-organizations-billing-audit-logs get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # Type of the audit event. Partial match. (e.g. subscription.change.)
  --qp-source: string # Source of the audit event. One of 'user', 'admin' or 'auto'. (e.g. admin)
  --pgsortBy: string # The value that will be used to sort returned entities by.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<billingLogs: table<id: string, type: string, source: string, metadata: record, authorId: int, authorEmail: string, createdAt: string>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/organizations/($organizationId)/billing-audit-logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get universal discount options
#
# GET /admin/organizations/{organizationId}/universal-discount-options
export def "admin-organizations-universal-discount-options get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<options: table<label: string, value: string, forceActivateImmediately: bool, defaultBannerText: string, defaultPercentOff: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/organizations/($organizationId)/universal-discount-options")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign universal discount
#
# POST /admin/organizations/{organizationId}/assign-universal-discount
export def "admin-organizations-assign-universal-discount post" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  discountType: string # The type of discount to assign (e.g. SOME_DISCOUNT_TYPE)
  percentOff: float # The percentage off for the discount (1-100) (e.g. 23)
  --activateImmediately: string@bool-completer # Whether to activate the discount immediately (default: false, e.g. true)
  --redeemUntil: string # The date until which the discount can be redeemed (format: date, e.g. 2024-12-31)
  --durationInMonths: int # The duration of the discount in months (e.g. 12)
  --bannerText: string # Custom banner text for the discount (overrides the type default) (e.g. Special offer just for you!)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/organizations/($organizationId)/assign-universal-discount")
  let body = {discountType: $discountType, percentOff: $percentOff, activateImmediately: $activateImmediately, redeemUntil: $redeemUntil, durationInMonths: $durationInMonths, bannerText: $bannerText} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove universal discount
#
# DELETE /admin/organizations/{organizationId}/universal-discount
export def "admin-organizations-universal-discount delete" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ok: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/organizations/($organizationId)/universal-discount")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get experiments for organization
#
# GET /admin/experiments/organization/{organizationId}
export def "admin-experiments-organization get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<experiments: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/experiments/organization/($organizationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organizations
#
# GET /admin/install/apps/{app}/logs
export def "admin-install-apps-logs get" [
  app: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --correlationId: string # Filter by Correlation ID. (e.g. abcd1234)
  --since: string # Filter logs by date. (e.g. 10-01-2023)
]: nothing -> record<logs: table<message: string, time: string>, correlationId: string, dateSince: string, error: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "correlationId" $correlationId "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/install/apps/($app)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List installation history
#
# GET /admin/apps/{app}/installation-history
export def "admin-apps-installation-history get" [
  app: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pglimit: int # Page size (max 1000). (default: 100)
  --pgoffset: int # Number of records to skip. (default: 0)
  --pgsortBy: string@pgsortBy-completer-1 # Field to sort by. (default: createdAt)
  --pgsortDir: string@pgsortDir-completer # Sort direction. (default: desc)
  --pgreturnTotalCount: string@bool-completer # When true, the response pagination block contains the total record count. This option is supported only for session (cookie) authentication. Token-authenticated requests that send `pg[returnTotalCount]=true` are rejected with HTTP 400.  (default: false)
]: nothing -> record<installationHistory: table<id: int, appName: string, appVersion: int, appVersionFull: string, previousVersion: int, previousVersionFull: string, status: string, userId: int, userName: string, userEmail: string, createdAt: string>, pg: record<limit: int, offset: int, sortBy: string, sortDir: string, returnTotalCount: bool, totalCount: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pg[limit]" $pglimit "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[returnTotalCount]" $pgreturnTotalCount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/apps/($app)/installation-history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rename Connection
#
# POST /admin/sdk/apps/{app}/connections/{connection}/rename
export def "admin-sdk-apps-connections-rename post" [
  app: string
  connection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The new connection name as a kebab-case slug. Must be globally unique across all connections.
]: any -> record<appConnection: record<name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/sdk/apps/($app)/connections/($connection)/rename")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get user's detail
#
# GET /admin/users-detail
export def "admin-users-detail get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # Optional filter parameter. (e.g. 1)
  --name: string # Optional filter parameter.
  --email: string # Optional filter parameter.
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
  --pgsortBy: string@pgsortBy-completer-2 # Sort the results in the APi call response by the values in the specified column.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<users: table<id: int, name: string, email: string, language: string, timezoneId: int, localeId: int, countryId: int, features: record, avatar: string, usersAdminsRoleId: int, tfaEnabled: bool, lastlogin: string, organizations: int, scenarios: int, activeScenarios: int, deleted: bool, created: string>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "cols" $cols "multi") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/users-detail" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List users
#
# GET /admin/users
export def "admin-users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int # The ID of the organization.
  --teamId: int # The ID of the team.
  --name: string # The name of the user.
  --email: string # The email of the user.
  --teamRoleId: int # The ID of the user's role in the team.
  --organizationRoleId: int # The ID of the user's role in the organization.
  --tfaStatus: int@tfaStatus-completer # The user's two-factor authentication (TFA) status. This field is available only on plans that have the TFA enforcement enabled.
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
  --pgsortBy: string@pgsortBy-completer-3 # Sort the results in the APi call response by the values in the specified column.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<users: table<id: int, name: string, email: string, language: string, timezoneId: int, localeId: int, countryId: int, features: record, avatar: string, usersAdminsRoleId: int, lastlogin: string, deleted: bool, created: string, tfaStatus: int>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "teamRoleId" $teamRoleId "scalar") (serialize-qp "organizationRoleId" $organizationRoleId "scalar") (serialize-qp "tfaStatus" $tfaStatus "scalar") (serialize-qp "cols" $cols "multi") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new user
#
# POST /admin/users
export def "admin-users post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the user.
  email: string # The user's email.
  --password: string # The password to the user's account. It has to contain at least 10 characters, including one number, one upper case character and one special character.
  --sendEmail: string@bool-completer # If set to `true`, Make sends an email to the user with their automatically generated password. The user has to change their password right after logging in.
  --countryId: int # The ID of user's country. Get the `countryId` values with the API call `GET /enums/countries`.
  --timezoneId: int # The ID of user's timezone. Get the list of the timezone IDs with the API call `GET /enums/timezones`.
  --localeId: int # The ID of user's locale. Get the list of locale IDs with the API call `GET /enums/locales`.
]: any -> record<user: record<id: int, name: string, email: string, language: string, timezoneId: int, localeId: int, countryId: int, features: record<allow_apps: bool>, avatar: string, lastLogin: string, organizations: int, scenarios: int, activeScenarios: int, deleted: bool, created: string, usersAdminsRoleId: int, tfaEnabled: bool, hasAddedApp: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/users")
  let body = {name: $name, email: $email, password: $password, sendEmail: $sendEmail, countryId: $countryId, timezoneId: $timezoneId, localeId: $localeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lookup user by ID or email
#
# GET /admin/users/lookup
export def "admin-users-lookup get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Lookup value. Use a numeric string when `type=id` or an email address when `type=email`.
  --type: string@type-completer # Lookup strategy for the `q` value. (e.g. id)
]: nothing -> record<user: record<id: int, email: string, name: string, deleted: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/users/lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user information
#
# PATCH /admin/users/{userId}
export def "admin-users patch" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the user.
  --email: string # The user's email.
  --language: string # The language of the user's UI. Currently, Make has the full UI in english only (value `en`).
  --countryId: int # The ID of user's country. Get the `countryId` values with the API call `GET /enums/countries`.
  --timezoneId: int # The ID of user's timezone. Get the list of the timezone IDs with the API call `GET /enums/timezones`.
  --localeId: int # The ID of user's locale. Get the list of locale IDs with the API call `GET /enums/locales`.
  --usersAdminsRoleId: int # The ID of the admin user's role. Get the list of available user admin roles and their IDs with the API call `GET /admin/users/admins-roles`.  Refer to the [user admin roles documentation](https://www.make.com/en/help/white-label/manage-organizations#instance-level-roles-1628394) for the full breakdown of the user admin roles permissions.
]: any -> record<user: record<id: int, name: string, email: string, language: string, timezoneId: int, localeId: int, countryId: int, features: record<allow_apps: bool>, avatar: string, lastLogin: string, organizations: int, scenarios: int, activeScenarios: int, deleted: bool, created: string, usersAdminsRoleId: int, tfaEnabled: bool, hasAddedApp: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($userId)")
  let body = {name: $name, email: $email, language: $language, countryId: $countryId, timezoneId: $timezoneId, localeId: $localeId, usersAdminsRoleId: $usersAdminsRoleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a user
#
# DELETE /admin/users/{userId}
export def "admin-users delete" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deleteConnections: string@bool-completer # Set to `true` to delete also user's connections when removing organizations, in which the user has the role "Owner". The default value is `false`. (e.g. true)
  --confirmed: string@bool-completer # Set to `true` to delete organizations in which the user has the "Owner" role. Use the parameter `deleteConnections` to delete the user's connections in the deleted organizations. (e.g. true)
]: nothing -> record<user: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteConnections" $deleteConnections "scalar") (serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/users/($userId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set user organization role
#
# POST /admin/users/{userId}/user-organization-roles/{organizationId}
export def "admin-users-user-organization-roles post" [
  userId: int
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
  --deleteConnections: string@bool-completer # When removing the user from the organization, set to `true` to delete also user's connections. The default value is `false`. To confirm deleting the user's connections you have to also set the `confirmed` parameter to `true`.
  --confirmed: string@bool-completer # Set to `true` to confirm deleting the user's connections in combination with the `deleteConnections` parameter. Otherwise, the API call fails with error requiring confirmation. (e.g. true)
  --usersRoleId: int # The ID of the user role. Check the `GET /users/roles` API call for the available `usersRoleId` values.
]: any -> record<userOrganizationRole: record<userId: int, organizationId: int, usersRoleId: int, invitation: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols" $cols "multi") (serialize-qp "deleteConnections" $deleteConnections "scalar") (serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/users/($userId)/user-organization-roles/($organizationId)" $qp)
  let body = {usersRoleId: $usersRoleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Transfer organization ownership
#
# POST /admin/users/{userId}/user-organization-roles/{organizationId}/transfer
export def "admin-users-user-organization-roles-transfer post" [
  userId: int
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<userOrganizationRoles: table<userId: int, organizationId: int, usersRoleId: int, invitation: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($userId)/user-organization-roles/($organizationId)/transfer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set user team role
#
# POST /admin/users/{userId}/user-team-roles/{teamId}
export def "admin-users-user-team-roles post" [
  userId: int
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # Use this parameter when you are removing a user from a team. Set this parameter to `true` is you want to delete the user's connections from the team with the parameter `deleteConnections`.
  --deleteConnections: string@bool-completer # Set this parameter to `true` if you are removing a user from a team to delete also the user's connections. If you set this parameter to `false`, the API call won't delete the user's connections.
  --usersRoleId: int # The ID of the user role. Check the `GET /users/roles` API call for the available `usersRoleId` values.
]: any -> record<userTeamRole: record<usersRoleId: int, userId: int, teamId: int, changeable: bool, ssoPending: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar") (serialize-qp "deleteConnections" $deleteConnections "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/users/($userId)/user-team-roles/($teamId)" $qp)
  let body = {usersRoleId: $usersRoleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List admin roles
#
# GET /admin/users/admins-roles
export def "admin-users-admins-roles get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --category: string@category-completer # Filter roles by category.
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
]: nothing -> record<usersAdminsRoles: table<id: int, name: string, permissions: list, category: string, identifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category" $category "scalar") (serialize-qp "cols" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/users/admins-roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get affiliate commission stats for a user
#
# GET /admin/users/{userId}/affiliate/stats
export def "admin-users-affiliate-stats get" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateFrom: string # format: date, e.g. 2021-08-01
  --dateTo: string # format: date, e.g. 2021-11-01
]: nothing -> record<stats: table<date: string, visits: int, registrations: int, commission: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/users/($userId)/affiliate/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get affiliate commission info for a user
#
# GET /admin/users/{userId}/affiliate/commission-info
export def "admin-users-affiliate-commission-info get" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateFrom: string # format: date, e.g. 2021-08-01
  --dateTo: string # format: date, e.g. 2021-11-01
]: nothing -> record<partnerCode: string, availablePayout: float, availablePayoutDistinctOrgs: int, isPayoutRequested: bool, isPayoutAvailable: bool, minimumPayout: float, minimumOrganizations: int, earningsRange: float, earningsTotal: float, usersBroughtPayingRange: int, usersBroughtPayingTotal: int, usersBroughtAllRange: int, usersBroughtAllTotal: int, orgsBroughtPayingRange: int, orgsBroughtPayingTotal: int, orgsBroughtAllRange: int, orgsBroughtAllTotal: int, conversionRateUsersPayingRange: float, conversionRateUsersPayingTotal: float, conversionRateUsersAllRange: float, conversionRateUsersAllTotal: float, conversionRateOrgsPayingRange: float, conversionRateOrgsPayingTotal: float, conversionRateOrgsAllRange: float, conversionRateOrgsAllTotal: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/users/($userId)/affiliate/commission-info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get affiliate commissions for a user
#
# GET /admin/users/{userId}/affiliate/commissions
export def "admin-users-affiliate-commissions get" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --statusId: int # e.g. 1
  --dateFrom: string # format: date, e.g. 2021-08-01
  --dateTo: string # format: date, e.g. 2021-11-01
  --pgsortBy: string # The value that will be used to sort returned entities by. (e.g. id)
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<commisions: table<id: int, organization_id: int, created: string, type: string, status: string, commission: float, source: string, payout_requested: string, payout_approved: string, payout_realized: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statusId" $statusId "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/users/($userId)/affiliate/commissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit one system setting
#
# PUT /admin/system-settings/{key}
export def "admin-system-settings put" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  value: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/system-settings/($key)")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get default license
#
# GET /admin/system-settings/default-license
export def "admin-system-settings-default-license get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<defaultLicense: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/system-settings/default-license")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List on-prem agents
#
# GET /agents
export def "agents list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int # e.g. 11
]: nothing -> record<agents: table<id: string, tenantId: string, name: string, clientSecret: string, status: string, alerted: bool, connected: bool, version: string, createdDate: string, lastConnectionDate: string, systemConnectionsCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/agents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get on-prem agent details
#
# GET /agents/{agentId}
export def "agents get" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int # e.g. 11
]: nothing -> record<agent: record<id: string, tenantId: string, name: string, clientSecret: string, status: string, alerted: bool, connected: bool, version: string, createdDate: string, lastConnectionDate: string, systemConnectionsCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/agents/($agentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create on-prem agent
#
# POST /agents/{agentId}
export def "agents post" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int # e.g. 11
  name: string
]: any -> record<agent: record<id: string, tenantId: string, name: string, clientSecret: string, status: string, alerted: bool, connected: bool, version: string, createdDate: string, lastConnectionDate: string, systemConnectionsCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/agents/($agentId)" $qp)
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update on-prem agent
#
# PATCH /agents/{agentId}
export def "agents patch" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int # e.g. 11
  --name: string
]: any -> record<agent: record<id: string, tenantId: string, name: string, clientSecret: string, status: string, alerted: bool, connected: bool, version: string, createdDate: string, lastConnectionDate: string, systemConnectionsCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/agents/($agentId)" $qp)
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete on-prem agent
#
# DELETE /agents/{agentId}
export def "agents delete" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int # e.g. 11
]: nothing -> record<agent: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/agents/($agentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Agent
#
# POST /ai-agents/v1/agents
# --llmConfig shape: {maxTokens?: float}
# --scenarios item shape: {makeScenarioId: float, approvalMode?: "auto-run"|"approval-required"}
# --historyConfig shape: {iterationsFromHistoryCount?: int}
# --mcpConfigs item shape: {mcpConnectionId?: int, toolIds?: list}
# --contexts item shape: {id?: string}
# --outputParserFormat shape: {type?: "text", schema?: list}
export def "ai-agents-agents post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: float
  name: string
  teamId: float
  makeConnectionId: float
  defaultModel: string
  systemPrompt: string
  --llmConfig: record # shape: {maxTokens?: float}
  --scenarios: list # item shape: {makeScenarioId: float, approvalMode?: "auto-run"|"approval-required"}
  --historyConfig: record # nullable — shape: {iterationsFromHistoryCount?: int}
  --mcpConfigs: list # item shape: {mcpConnectionId?: int, toolIds?: list}
  --contexts: list # item shape: {id?: string}
  --outputParserFormat: record # shape: {type?: "text", schema?: list}
]: any -> record<name: string, teamId: float, makeConnectionId: float, defaultModel: string, systemPrompt: string, agentId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ai-agents/v1/agents" $qp)
  let body = {name: $name, teamId: $teamId, makeConnectionId: $makeConnectionId, defaultModel: $defaultModel, systemPrompt: $systemPrompt, llmConfig: $llmConfig, scenarios: $scenarios, historyConfig: $historyConfig, mcpConfigs: $mcpConfigs, contexts: $contexts, outputParserFormat: $outputParserFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Agents
#
# GET /ai-agents/v1/agents
export def "ai-agents-agents list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: float
]: nothing -> record<id: string, name: string, teamId: int, createdAt: string, systemPrompt: string, defaultModel: string, invocationConfig: record<recursionLimit: int>, scenarios: table<makeScenarioId: int, approvalMode: string>, mcpConfigs: table<mcpConnectionId: int, toolIds: list, name: string>, historyConfig: record<iterationsFromHistoryCount: int>, llmConfig: record<maxTokens: int>, contexts: table<id: string, agentId: string, documentName: string, description: string, createdAt: string, metadata: record, isTemporary: bool>, outputParser: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ai-agents/v1/agents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Agent by ID
#
# GET /ai-agents/v1/agents/{agentId}
export def "ai-agents-agents get" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: float
]: nothing -> record<id: string, name: string, teamId: int, createdAt: string, systemPrompt: string, defaultModel: string, invocationConfig: record<recursionLimit: int>, makeConnectionId: int, makeConnectionType: string, pastConfigurations: table<name: string, llmConfig: record, scenarios: list, mcpConfigs: list, defaultModel: string, systemPrompt: string, historyConfig: record, invocationConfig: record>, scenarios: table<makeScenarioId: int, approvalMode: string>, mcpConfigs: table<mcpConnectionId: int, tools: list, name: string>, historyConfig: record<iterationsFromHistoryCount: int>, llmConfig: record<maxTokens: int>, llmProviderId: int, contexts: table<id: string, agentId: string, documentName: string, description: string, createdAt: string, metadata: record, isTemporary: bool>, outputParser: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ai-agents/v1/agents/($agentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify Agent by ID
#
# PATCH /ai-agents/v1/agents/{agentId}
# --llmConfig shape: {maxTokens?: float}
# --invocationConfig shape: {recursionLimit?: int, timeout?: int}
# --scenarios item shape: {makeScenarioId: float, approvalMode?: "auto-run"|"approval-required"}
# --historyConfig shape: {iterationsFromHistoryCount?: int}
# --mcpConfigs item shape: {mcpConnectionId: int, toolIds: list}
# --outputParserFormat shape: {type?: "text", schema?: list}
export def "ai-agents-agents patch" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: float
  --name: string
  --systemPrompt: string
  --defaultModel: string
  --llmConfig: record # shape: {maxTokens?: float}
  --invocationConfig: record # shape: {recursionLimit?: int, timeout?: int}
  --scenarios: list # item shape: {makeScenarioId: float, approvalMode?: "auto-run"|"approval-required"}
  --historyConfig: record # nullable — shape: {iterationsFromHistoryCount?: int}
  --mcpConfigs: list # item shape: {mcpConnectionId: int, toolIds: list}
  --outputParserFormat: record # shape: {type?: "text", schema?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ai-agents/v1/agents/($agentId)" $qp)
  let body = {name: $name, systemPrompt: $systemPrompt, defaultModel: $defaultModel, llmConfig: $llmConfig, invocationConfig: $invocationConfig, scenarios: $scenarios, historyConfig: $historyConfig, mcpConfigs: $mcpConfigs, outputParserFormat: $outputParserFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Agent by ID
#
# DELETE /ai-agents/v1/agents/{agentId}
export def "ai-agents-agents delete" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: float
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ai-agents/v1/agents/($agentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Run Agent
#
# POST /ai-agents/v1/agents/{agentId}/run
# --messages item shape: {role: "assistant"|"user", content: string}
# --config shape: {systemPrompt?: string, additionalSystemPrompt?: string, scenarios?: list, historyConfig?: record, llmConfig?: record, invocationConfig?: record, mcpConfigs?: list, outputParser?: record}
export def "ai-agents-agents-run post" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: float
  messages: list # item shape: {role: "assistant"|"user", content: string}
  --threadId: string # default: a64d23ed-2580-43e4-a898-e97193d7fd5e
  --callbackUrl: string
  config: record # shape: {systemPrompt?: string, additionalSystemPrompt?: string, scenarios?: list, historyConfig?: record, llmConfig?: record, invocationConfig?: record, mcpConfigs?: list, outputParser?: record}
]: any -> record<response: string, jsonResponse: record, executionSteps: table<id: string, index: float, role: string, content: string, executionTimeMs: float, tokenUsage: any, toolCalls: list, toolResponse: record, agentIterationId: string>, executionTimeMs: int, threadId: string, tokenUsageSummary: record<promptTokens: int, completionTokens: int, totalTokens: int>, lastAgentIterationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ai-agents/v1/agents/($agentId)/run" $qp)
  let body = {messages: $messages, threadId: $threadId, callbackUrl: $callbackUrl, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Run Agent with Server Sent Events (SSE) Streaming
#
# POST /ai-agents/v1/agents/{agentId}/run/stream
# --messages item shape: {role: "assistant"|"user", content: string}
# --config shape: {systemPrompt?: string, additionalSystemPrompt?: string, scenarios?: list, historyConfig?: record, llmConfig?: record, invocationConfig?: record, mcpConfigs?: list, outputParser?: record}
export def "ai-agents-agents-run-stream post" [
  agentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: float
  messages: list # item shape: {role: "assistant"|"user", content: string}
  --threadId: string # default: d7fbd183-6b53-4dba-9469-00ec3d047cef
  --callbackUrl: string
  config: record # shape: {systemPrompt?: string, additionalSystemPrompt?: string, scenarios?: list, historyConfig?: record, llmConfig?: record, invocationConfig?: record, mcpConfigs?: list, outputParser?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ai-agents/v1/agents/($agentId)/run/stream" $qp)
  let body = {messages: $messages, threadId: $threadId, callbackUrl: $callbackUrl, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Context
#
# POST /ai-agents/v1/contexts
export def "ai-agents-contexts post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: float
  agentId: string # format: uuid
  --content: string
  --name: string
  --autosave: string # default: true
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ai-agents/v1/contexts" $qp)
  let body = {agentId: $agentId, content: $content, name: $name, autosave: $autosave} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Context
#
# GET /ai-agents/v1/contexts
export def "ai-agents-contexts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agentId: string # format: uuid
  --teamId: float
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agentId" $agentId "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ai-agents/v1/contexts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Context
#
# DELETE /ai-agents/v1/contexts/{contextId}
export def "ai-agents-contexts delete" [
  contextId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: float
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ai-agents/v1/contexts/($contextId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List LLM Providers
#
# GET /ai-agents/v1/llm-providers
export def "ai-agents-llm-providers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: float
]: nothing -> table<id: int, provider: string, accountName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ai-agents/v1/llm-providers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get LLM Provider
#
# GET /ai-agents/v1/llm-providers/{providerId}
export def "ai-agents-llm-providers get" [
  providerId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: float
]: nothing -> table<id: int, provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ai-agents/v1/llm-providers/($providerId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Models for LLM Provider
#
# GET /ai-agents/v1/llm-providers/{providerId}/models
export def "ai-agents-llm-providers-models get" [
  providerId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: float
]: nothing -> table<model: string, provider: string, tokenLimit: int, settings: record<maxTokens: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ai-agents/v1/llm-providers/($providerId)/models" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Analyze scenario error with AI
#
# POST /ai-error-analysis
export def "ai-error-analysis post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  errorMessage: string # The error message from the failed module execution.
  --blueprint: record # The scenario blueprint JSON. Optional but recommended for more accurate analysis. The API trims designer-only metadata before forwarding it to the AI webhook.
  --errorModuleId: int # Module identifier where the error occurred. When provided, only modules up to and including this module are forwarded in the minified blueprint.
  --scenarioId: float # Scenario identifier when available (e.g. from the inspector).
  --executionId: any # Execution identifier when available. The API accepts both string and number values and normalizes to string before forwarding to the AI webhook.
  --suberrors: list # Sub-error lines shown under the main exception name in the UI.
  --errorType: string # Exception or error type name (e.g. the error class name).
]: any -> record<analysis: record<whatHappened: string, whyItHappened: string, whatToDoNext: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ai-error-analysis")
  let body = {errorMessage: $errorMessage, blueprint: $blueprint, errorModuleId: $errorModuleId, scenarioId: $scenarioId, executionId: $executionId, suberrors: $suberrors, errorType: $errorType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Register partner
#
# POST /affiliate/partner-register
export def "affiliate-partner-register post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  partnerCode: string
  paypalMeLink: string
  --termsAndConditions: string@bool-completer
]: any -> record<ok: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/affiliate/partner-register")
  let body = {partnerCode: $partnerCode, paypalMeLink: $paypalMeLink, termsAndConditions: $termsAndConditions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get commission stats
#
# GET /affiliate/stats
export def "affiliate-stats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateFrom: string # format: date, e.g. 2021-08-01
  --dateTo: string # format: date, e.g. 2021-11-01
]: nothing -> record<stats: table<date: string, visits: int, registrations: int, commission: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/affiliate/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get commissions
#
# GET /affiliate/commissions
export def "affiliate-commissions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --statusId: int # e.g. 1
  --dateFrom: string # format: date, e.g. 2021-08-01
  --dateTo: string # format: date, e.g. 2021-11-01
  --pgsortBy: string # The value that will be used to sort returned entities by. (e.g. id)
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<commisions: table<id: int, organization_id: int, created: string, type: string, status: string, commission: float, source: string, payout_requested: string, payout_approved: string, payout_realized: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statusId" $statusId "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/affiliate/commissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get commission info
#
# GET /affiliate/commission-info
export def "affiliate-commission-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateFrom: string # format: date, e.g. 2021-08-01
  --dateTo: string # format: date, e.g. 2021-11-01
]: nothing -> record<partnerCode: string, availablePayout: float, availablePayoutDistinctOrgs: int, isPayoutRequested: bool, isPayoutAvailable: bool, minimumPayout: float, minimumOrganizations: int, earningsRange: float, earningsTotal: float, usersBroughtPayingRange: int, usersBroughtPayingTotal: int, usersBroughtAllRange: int, usersBroughtAllTotal: int, orgsBroughtPayingRange: int, orgsBroughtPayingTotal: int, orgsBroughtAllRange: int, orgsBroughtAllTotal: int, conversionRateUsersPayingRange: float, conversionRateUsersPayingTotal: float, conversionRateUsersAllRange: float, conversionRateUsersAllTotal: float, conversionRateOrgsPayingRange: float, conversionRateOrgsPayingTotal: float, conversionRateOrgsAllRange: float, conversionRateOrgsAllTotal: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/affiliate/commission-info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request payout
#
# POST /affiliate/payout-request
export def "affiliate-payout-request post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ok: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/affiliate/payout-request")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organization audit logs
#
# GET /audit-logs/organization/{organizationId}
# operationId: getOrganizationAuditLogs
export def "audit-logs-organization get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team: string # The identification of the teams for which you want to get the audit log entries. You can use either team IDs or team names.  The team name can contain any valid UTF8 symbols and spaces.
  --dateFrom: string # Use the `dateFrom` parameter to get audit log entries from the specified date or newer. Specify the date in the YYYY-MM-DD format. (format: date, e.g. 2021-09-23T00:00:00.000Z)
  --dateTo: string # Use the `dateTo` parameter to get audit log entries until the specified date or older. Specify the date in the YYYY-MM-DD format. (format: date, e.g. 2021-09-24T00:00:00.000Z)
  --event: string # The list of events for which you want to get audit log entries. To specify multiple events, use the array notation like: `GET /audit-logs/organization/{organizationId}?event[0]=key_created&event[1]=connection_created`.  You can check the list of supported events with the API call `GET /audit-logs/organization/{organizationId}/filters` in the `events` array in the response.
  --author: string # The identification of the users for whose actions you want to get the audit log entries. You can use either user IDs or user names.  The user name can contain any valid UTF8 symbols and spaces.
  --pgoffset: int # The number of entities you want to skip before getting entities you want.
  --pglimit: int # The maximum number of entities you want to get in the response.
  --pglast: int # The last retrieved key. In response, you get only entries that follow after the key. (e.g. 10)
  --pgsortBy: string@pgsortBy-completer-4 # Specify the response property values that Make will use to sort the audit log entries in the response. The default is `triggeredAt`.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pgreturnTotalCount: string@bool-completer # Set to `true` to get also the total number of audit log entries in the response. (e.g. true)
]: nothing -> record<auditLogs: table<uuid: string, createdAt: string, triggeredAt: int, organizationId: int, organization: record, eventName: string, team: record, actor: record, targetId: string, version: record>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int, totalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team" $team "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "event" $event "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[limit]" $pglimit "scalar") (serialize-qp "pg[last]" $pglast "scalar") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[returnTotalCount]" $pgreturnTotalCount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/audit-logs/organization/($organizationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization audit log filters
#
# GET /audit-logs/organization/{organizationId}/filters
# operationId: getOrganizationAuditLogsFilters
export def "audit-logs-organization-filters get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<users: table<id: int, name: string, email: string>, teams: table<id: int, name: string>, events: table<header: string, items: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/audit-logs/organization/($organizationId)/filters")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List team audit logs
#
# GET /audit-logs/team/{teamId}
# operationId: getTeamAuditLogs
export def "audit-logs-team get" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateFrom: string # Use the `dateFrom` parameter to get audit log entries from the specified date or newer. Specify the date in the YYYY-MM-DD format. (format: date, e.g. 2021-09-23T00:00:00.000Z)
  --dateTo: string # Use the `dateTo` parameter to get audit log entries until the specified date or older. Specify the date in the YYYY-MM-DD format. (format: date, e.g. 2021-09-24T00:00:00.000Z)
  --event: string # The list of events for which you want to get audit log entries. To specify multiple events, use the array notation like: `GET /audit-logs/team/{teamId}?event[0]=key_created&event[1]=connection_created`.  You can check the list of supported events with the API call `GET /audit-logs/team/{teamId}/filters` in the `events` array in the response.
  --author: string # The identification of the users for whose actions you want to get the audit log entries. You can use either user IDs or user names.  The user name can contain any valid UTF8 symbols and spaces.
  --pgoffset: int # The number of entities you want to skip before getting entities you want.
  --pglimit: int # The maximum number of entities you want to get in the response.
  --pglast: int # The last retrieved key. In response, you get only entries that follow after the key. (e.g. 10)
  --pgsortBy: string@pgsortBy-completer-4 # Specify the response property values that Make will use to sort the audit log entries in the response. The default is `triggeredAt`.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pgreturnTotalCount: string@bool-completer # Set to `true` to get also the total number of audit log entries in the response. (e.g. true)
]: nothing -> record<auditLogs: table<uuid: string, createdAt: string, triggeredAt: int, organizationId: int, organization: record, eventName: string, team: record, actor: record, targetId: string, version: record>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int, totalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "event" $event "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[limit]" $pglimit "scalar") (serialize-qp "pg[last]" $pglast "scalar") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[returnTotalCount]" $pgreturnTotalCount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/audit-logs/team/($teamId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization audit log filters
#
# GET /audit-logs/team/{teamId}/filters
# operationId: getTeamAuditLogsFilters
export def "audit-logs-team-filters get" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<users: table<id: int, name: string, email: string>, events: table<header: string, items: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/audit-logs/team/($teamId)/filters")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get audit log detail
#
# GET /audit-logs/{organizationId}/{uuid}
# operationId: getAuditLogDetail
export def "audit-logs get" [
  uuid: string
  organizationId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uuid: string, createdAt: string, triggeredAt: int, organizationId: int, organization: record<id: int, name: string>, eventName: string, team: record<id: int, name: string>, actor: record<id: int, name: string, email: string>, targetId: string, version: record<from: string, to: string>, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/audit-logs/($organizationId)/($uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization analytics
#
# GET /analytics/{organizationId}
export def "analytics get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # IDs of the teams for which you want to get the analytics data.
  --folderId: string # IDs of the scenario folders for which you want to get the analytics data.
  --status: string # You can use the `status` parameter to get analytics data about scenarios with specific scenario statuses. The available scenario statuses are:  - `active`: scenario is enabled - `inactive`: scenario is disabled - `invalid`: scenario is disabled due to errors
  --timeframedateFrom: string # Use the `timeframe[dateFrom]` parameter to get analytics data from the specified date. Specify the date and time in the ISO 8601 compliant format.  The default is the date since one year from today. You can't use a date older than a year from today.  (format: date-time, e.g. 2020-03-20T05:53:27.368Z)
  --timeframedateTo: string # Use the `timeframe[dateTo]` parameter to get analytics data until the specified date. Specify the date and time in the ISO 8601 compliant format.  The default is to get data until today.  (format: date-time, e.g. 2020-03-27T05:53:27.368Z)
  --pgoffset: int # The number of entities you want to skip before getting entities you want.
  --pglimit: int # The maximum number of entities you want to get in the response.
  --pglast: int # The last retrieved key. In response, you get only entries that follow after the key. (e.g. 10)
  --pgsortBy: string@pgsortBy-completer-5 # Specify which property Make will use to sort the analytics entries in the response. The default is `operations`.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pgreturnTotalCount: string@bool-completer # Set to `true` to get also the total number of analytics entries in the response. (e.g. true)
]: nothing -> record<total: record<executions: int, operations: int, centicredits: string, errors: int, errorRate: float, executionsChange: float, operationsChange: float, centicreditsChange: float, errorsChange: float, errorRateChange: float>, analytics: table<executions: int, operations: int, centicredits: string, errors: int, errorRate: float, executionsChange: float, operationsChange: float, centicreditsChange: float, errorsChange: float, errorRateChange: float, imtId: string, id: float, name: string, status: string, teamId: float, teamName: string>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int, totalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "folderId" $folderId "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "timeframe[dateFrom]" $timeframedateFrom "scalar") (serialize-qp "timeframe[dateTo]" $timeframedateTo "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[limit]" $pglimit "scalar") (serialize-qp "pg[last]" $pglast "scalar") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[returnTotalCount]" $pgreturnTotalCount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analytics/($organizationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get list of cashier products
#
# GET /cashier/products
export def "cashier-products get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-1 # e.g. PLAN
  --includeInvisible: string@bool-completer # e.g. true
  --relatedPriceId: int
  --organizationId: int
]: nothing -> record<products: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "includeInvisible" $includeInvisible "scalar") (serialize-qp "relatedPriceId" $relatedPriceId "scalar") (serialize-qp "organizationId" $organizationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cashier/products" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get price detail
#
# GET /cashier/prices/{priceId}
export def "cashier-prices get" [
  priceId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, productId: float, price: float, currencyCode: string, period: string, priority: float, visible: bool, default: bool, config: record<dslimit: float, iolimit: float, dsslimit: float, transfer: float, dlqStorage: float, operations: float, restartPeriod: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cashier/prices/($priceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get VAT ID format patterns
#
# GET /cashier/vat-validation/patterns
export def "cashier-vat-validation-patterns get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<patterns: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cashier/vat-validation/patterns")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List connections
#
# GET /connections
export def "connections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The unique ID of the team whose connections will be retrieved. (e.g. 22)
  --type: list # Specifies the type of the connections to return details for. The connection type is defined in the `accountName` property and you can get it from the [Get connection details](./get--connections--connectionid.md) endpoint.
  --<connectionType>: list # Allows utilizing the scopes check. The particular connection type (`<connectionType>`) should be one of the types specified in the `type[]` parameter. The values are the scopes to check for the given connection type. You can send multiple `<connectionType>` values with corresponding arrays to check multiple connection types scopes at once. The result of the check is reflected in the `scoped` property of the returned connection object.
  --cols: list # Specifies the group of values to return. For example, you may want to check which returned connections can be upgraded.
]: nothing -> record<connections: table<id: int, name: string, accountName: string, accountLabel: string, packageName: string, expire: string, metadata: record, teamId: int, theme: string, upgradeable: bool, scopesCnt: int, scoped: bool, accountType: string, editable: bool, uid: string, connectedSystemId: string, organizationId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "type[]" $type "multi") (serialize-qp "<connectionType>[]" $<connectionType> "multi") (serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create connection
#
# POST /connections
export def "connections post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The unique ID of the team whose connections will be retrieved. (e.g. 1)
  --accountName: string # The connection name. The name must be at most 128 characters long and does not need to be unique.
  --accountType: string # The connection type corresponding to the connected app. For some connection types, this property may require providing additional properties in the request body,  such as `clientId` and `clientSecret`, in order to authorize the connection and make it functional.
  --scopes: list # The connection scope determining the module use. The format and number of available scopes vary depending on the `accountType` parameter.
]: any -> record<connection: record<id: int, name: string, accountName: string, accountLabel: string, packageName: string, expire: string, metadata: record<value: string, type: string>, teamId: int, theme: string, upgradeable: bool, scopesCnt: int, scoped: bool, accountType: string, editable: bool, uid: string, connectedSystemId: string, organizationId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/connections" $qp)
  let body = {accountName: $accountName, accountType: $accountType, scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List updatable connection parameters
#
# GET /connections/{connectionId}/editable-data-schema
export def "connections-editable-data-schema get" [
  connectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<editableParameters: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($connectionId)/editable-data-schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a connection
#
# POST /connections/{connectionId}/set-data
export def "connections-set-data post" [
  connectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<changed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($connectionId)/set-data")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get connection details
#
# GET /connections/{connectionId}
export def "connections get" [
  connectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies the group of values to return. For example, you may want to retrieve only the name and scope for a given connection.
]: nothing -> record<connection: record<id: int, name: string, accountName: string, accountLabel: string, packageName: string, expire: string, metadata: record<value: string, type: string>, teamId: int, theme: string, upgradeable: bool, scopesCnt: int, scoped: bool, accountType: string, editable: bool, uid: string, connectedSystemId: string, organizationId: int, scopes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/connections/($connectionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rename a connection
#
# PATCH /connections/{connectionId}
export def "connections patch" [
  connectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies the group of values to return. For example, you may want to retrieve only the expiration of the updated connection.
  --name: string # The updated connection name. The name must be at most 128 characters long and does not need to be unique.
]: any -> record<connection: record<id: int, name: string, accountName: string, accountLabel: string, packageName: string, expire: string, metadata: record<value: string, type: string>, teamId: int, theme: string, upgradeable: bool, scopesCnt: int, scoped: bool, accountType: string, editable: bool, uid: string, connectedSystemId: string, organizationId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/connections/($connectionId)" $qp)
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete connection
#
# DELETE /connections/{connectionId}
export def "connections delete" [
  connectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # Confirms the deletion if the connection is included in at least one scenario. Confirmation is required because the scenario will stop working without the connection. If the parameter is missing or it is set to `false` an error code is returned and the resource is not deleted. (e.g. true)
]: nothing -> record<connection: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/connections/($connectionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify connection
#
# POST /connections/{connectionId}/test
export def "connections-test post" [
  connectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($connectionId)/test")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify if connection is scoped
#
# POST /connections/{connectionId}/scoped
export def "connections-scoped post" [
  connectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scope: list # The array with IDs of the scopes for a given connection. The scope ID of a specific connection can be retrieved from the [Get connection details](./get--connections--connectionid.md) endpoint.
]: any -> record<connection: record<scoped: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($connectionId)/scoped")
  let body = {scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create new Credential Request - deprecated
#
# POST /credential-requests/requests
# DEPRECATED
# --connections item shape: {type: string, label?: string, description?: string, scope?: list, nameOverride?: string, appName: string, appModules: list, appVersion: string}
# --keys item shape: {type: string, label?: string, description?: string, nameOverride?: string, appName: string, appModules: list, appVersion: string}
@deprecated
export def "credential-requests-requests post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the Request which will be displayed to the End Users who open it.
  teamId: float # ID of the Team the Credential Request should be bound to.
  --description: string # Description of the Request which will be displayed to the End Users who open it.
  --connections: list # Array of connections to include in the request. — item shape: {type: string, label?: string, description?: string, scope?: list, nameOverride?: string, appName: string, appModules: list, appVersion: string}
  --keys: list # Array of keys to include in the request. — item shape: {type: string, label?: string, description?: string, nameOverride?: string, appName: string, appModules: list, appVersion: string}
  provider: any # Provider information. Either an existing Make user ID or a new user to invite (name & email).
]: any -> record<request: record<id: string, organizationId: int, teamId: int, userId: int, name: string, description: string, externalProviderId: float, makeProviderId: float, createdAt: string, updatedAt: string, expiresAt: string, status: string, shouldSendEmail: bool, emailSentAt: string>, publicUri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credential-requests/requests")
  let body = {name: $name, teamId: $teamId, description: $description, connections: $connections, keys: $keys, provider: $provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Credential Requests
#
# GET /credential-requests/requests
export def "credential-requests-requests list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # Team ID to filter credential requests.
  --cols: list # Not all properties of the Entity may be returned by default, for example because of their size. Using the Column Filter parameter, you can ask the Server to provide additional properties when needed.
  --userId: float # User ID to filter credential requests.
  --makeProviderId: float # Make Provider ID to filter credential requests.
  --status: string@status-completer # Status to filter credential requests.
  --name: string # Name to filter credential requests.
]: nothing -> record<requests: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "cols" $cols "multi") (serialize-qp "userId" $userId "scalar") (serialize-qp "makeProviderId" $makeProviderId "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/credential-requests/requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new Credential Request (V2)
#
# POST /credential-requests/requests/v2
# --credentials item shape: {appName: string, appModules: list, appVersion?: int, nameOverride?: string, description?: string}
export def "credential-requests-requests post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the Request which will be displayed to the End Users who open it.
  teamId: int # ID of the Team the Credential Request should be bound to.
  --description: string # Description of the Request which will be displayed to the End Users who open it.
  credentials: list # Array of app/module selections to derive credentials from. — item shape: {appName: string, appModules: list, appVersion?: int, nameOverride?: string, description?: string}
  provider: any # Provider information. Either an existing Make user ID or a new user to invite (name & email).
]: any -> record<request: record<id: string, organizationId: int, teamId: int, userId: int, name: string, description: string, externalProviderId: float, makeProviderId: float, createdAt: string, updatedAt: string, expiresAt: string, status: string, shouldSendEmail: bool, emailSentAt: string>, publicUri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credential-requests/requests/v2")
  let body = {name: $name, teamId: $teamId, description: $description, credentials: $credentials, provider: $provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Credential Request
#
# GET /credential-requests/requests/{requestId}
export def "credential-requests-requests get" [
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Not all properties of the Entity may be returned by default, for example because of their size. Using the Column Filter parameter, you can ask the Server to provide additional properties when needed.
]: nothing -> record<request: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/credential-requests/requests/($requestId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Credential Request
#
# DELETE /credential-requests/requests/{requestId}
export def "credential-requests-requests delete" [
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # When true, also deletes credentials (connections and keys) associated with the credential request. When false or omitted the API will return an error if there are any associated credentials, preventing accidental deletion of credentials.
]: nothing -> record<deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/credential-requests/requests/($requestId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Credential Request Detail
#
# GET /credential-requests/requests/{requestId}/detail
export def "credential-requests-requests-detail get" [
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<requestDetail: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credential-requests/requests/($requestId)/detail")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Decline Credential
#
# POST /credential-requests/credentials/{credentialId}/decline
export def "credential-requests-credentials-decline post" [
  credentialId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Not all properties of the Entity may be returned by default, for example because of their size. Using the Column Filter parameter, you can ask the Server to provide additional properties when needed.
  --reason: string # The reason why the credential was declined. This will be visible to support teams and helps with troubleshooting.
]: any -> record<credential: record<id: string, requestId: string, component: string, type: string, name: string, label: string, description: string, scope: list<string>, remoteId: string, remoteScope: list<string>, tokenId: string, createdAt: string, updatedAt: string, state: string, declineReason: string, appName: string, appModules: list<string>, appVersion: string, nameOverride: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/credential-requests/credentials/($credentialId)/decline" $qp)
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Remote Credential
#
# POST /credential-requests/credentials/{credentialId}/delete-remote
export def "credential-requests-credentials-delete-remote post" [
  credentialId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Not all properties of the Entity may be returned by default, for example because of their size. Using the Column Filter parameter, you can ask the Server to provide additional properties when needed.
]: nothing -> record<credential: record<id: string, requestId: string, component: string, type: string, name: string, label: string, description: string, scope: list<string>, remoteId: string, remoteScope: list<string>, tokenId: string, createdAt: string, updatedAt: string, state: string, declineReason: string, appName: string, appModules: list<string>, appVersion: string, nameOverride: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/credential-requests/credentials/($credentialId)/delete-remote" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request Credential Reauthorization
#
# POST /credential-requests/credentials/{credentialId}/request-reauthorize
export def "credential-requests-credentials-request-reauthorize post" [
  credentialId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Not all properties of the Entity may be returned by default, for example because of their size. Using the Column Filter parameter, you can ask the Server to provide additional properties when needed.
]: nothing -> record<credential: record<id: string, requestId: string, component: string, type: string, name: string, label: string, description: string, scope: list<string>, remoteId: string, remoteScope: list<string>, tokenId: string, createdAt: string, updatedAt: string, state: string, declineReason: string, appName: string, appModules: list<string>, appVersion: string, nameOverride: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/credential-requests/credentials/($credentialId)/request-reauthorize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Action
#
# POST /credential-requests/actions/create
# --connection shape: {teamId: int, accountName: string, name?: string, scopes?: list, appName?: string, appModules?: list, appVersion?: string}
# --key shape: {teamId: int, type: string, name?: string, appName?: string, appModules?: list, appVersion?: string}
export def "credential-requests-actions-create post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the Request which will be displayed to the End Users who open it.
  --description: string # Description of the Request which will be displayed to the End Users who open it.
  --connection: record # Connection creation parameters for action. — shape: {teamId: int, accountName: string, name?: string, scopes?: list, appName?: string, appModules?: list, appVersion?: string}
  --key: record # Key creation parameters for action. — shape: {teamId: int, type: string, name?: string, appName?: string, appModules?: list, appVersion?: string}
]: any -> record<request: record<id: string, organizationId: int, teamId: int, userId: int, name: string, description: string, externalProviderId: float, makeProviderId: float, createdAt: string, updatedAt: string, expiresAt: string, status: string, shouldSendEmail: bool, emailSentAt: string>, publicUri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credential-requests/actions/create")
  let body = {name: $name, description: $description, connection: $connection, key: $key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List App Modules with Credentials
#
# GET /credential-requests/apps/{name}/{version}/modules-with-credentials
export def "credential-requests-apps-modules-with-credentials get" [
  name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appModules: table<id: string, name: string, label: string, type: string, scope: list, hook: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credential-requests/apps/($name)/($version)/modules-with-credentials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List custom property structures
#
# GET /custom-property-structures
export def "custom-property-structures get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int # The ID of the organization. (e.g. 57)
]: nothing -> record<customPropertyStructures: table<id: int, created: string, belongers: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom-property-structures" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a custom property structure
#
# POST /custom-property-structures
export def "custom-property-structures post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  associatedType: string # The type of the entity which uses the custom properties structure. Fill in `scenario` to create custom scenario properties structure.
  belongerType: string # The type of the entity that owns the custom properties structure. Fill in `organization` to create custom scenario properties structure.
  belongerId: int # The ID of the entity that owns the custom properties structure.
]: any -> record<id: int, created: string, belongers: table<belongerId: int, belongerType: string, associatedTypes: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom-property-structures")
  let body = {associatedType: $associatedType, belongerType: $belongerType, belongerId: $belongerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List custom property structure items
#
# GET /custom-property-structures/{customPropertyStructureId}/custom-property-structure-items
export def "custom-property-structures-custom-property-structure-items get" [
  customPropertyStructureId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
  --pgsortBy: string@pgsortBy-completer-6 # Specify the custom property item attribute. The custom property items in the response are sorted by the value of the attribute.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<customPropertyStructureItems: table<id: int, created: string, belongers: list>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols[]" $cols "multi") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom-property-structures/($customPropertyStructureId)/custom-property-structure-items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a custom property structure item
#
# POST /custom-property-structures/{customPropertyStructureId}/custom-property-structure-items
export def "custom-property-structures-custom-property-structure-items post" [
  customPropertyStructureId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The ID of the structure item. The `name` has to be unique in the custom properties structure.
  label: string # Make displays the item label to users in the scenario table header.
  --description: string # The description of the custom property structure item. You can review the item description in the **Scenario properties** tab in the Organization dashboard.
  type: string@type-completer-2 # The data type of the custom property structure item. The data types `dropdown` and `multiselect` allow you to specify available options for the item data.
  --options: any # The options available to users when filling in the item data. For the data types `dropdown` and `multiselect`, fill in an object like `{"options":[{"value": "Marketing"}, {"value": "Sales"}]}`. You can omit the `options` parameter for the rest of the data types. 
  --required: string@bool-completer # Set to `true` in order to make a structure item required when adding custom property data. Default value is `false`.
]: any -> record<customPropertyStructureItem: record<id: int, created: string, belongers: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-property-structures/($customPropertyStructureId)/custom-property-structure-items")
  let body = {name: $name, label: $label, description: $description, type: $type, options: $options, required: $required} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update custom property structure item
#
# PATCH /custom-property-structures/custom-property-structure-items/{customPropertyStructureItemId}
export def "custom-property-structures-custom-property-structure-items patch" [
  customPropertyStructureItemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --label: string # Make displays the item label to users in the scenario table header.
  --description: string # The description of the custom property structure item. You can review the item description in the **Scenario properties** tab in the Organization dashboard.
  --options: any # The options available to users when filling in the item data. For the data types `dropdown` and `multiselect`, fill in an object like `{"options":[{"value": "Marketing"}, {"value": "Sales"}]}`. You can omit the `options` parameter for the rest of the data types. 
  --required: string@bool-completer # Set to `true` if you require to fill in data to the structure item when adding custom property data. Default value is `false`.
]: any -> record<customPropertyStructureItem: record<id: int, created: string, belongers: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom-property-structures/custom-property-structure-items/($customPropertyStructureItemId)")
  let body = {label: $label, description: $description, options: $options, required: $required} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete custom property structure item
#
# DELETE /custom-property-structures/custom-property-structure-items/{customPropertyStructureItemId}
export def "custom-property-structures-custom-property-structure-items delete" [
  customPropertyStructureItemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # e.g. true
]: nothing -> record<customPropertyStructureItem: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom-property-structures/custom-property-structure-items/($customPropertyStructureItemId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List data stores
#
# GET /data-stores
export def "data-stores list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The unique ID of the team whose data stores will be retrieved. (e.g. 1)
  --cols: list # Specifies the group of values to return. For example, you can retrieve only names and IDs of data stores for a team with a given ID.
  --pgsortBy: string@pgsortBy-completer # The value that will be used to sort returned entities by.
  --pgoffset: int # The number of entities you want to skip before getting entities you want.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # The maximum number of entities you want to get in the response.
]: nothing -> record<dataStores: table<id: int, name: string, records: int, size: string, maxSize: string, teamId: int, datastructureId: int>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "cols[]" $cols "multi") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/data-stores" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create data store
#
# POST /data-stores
export def "data-stores post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The data store name. The name must be at most 128 characters long and does not need to be unique.
  teamId: int # The unique ID of the team in which the data store will be created.
  datastructureId: int # The unique ID of the data structure that will be included in the data store. All data structures IDs for a given team can be retrieved from the [List data structures](/api-reference/data-structures/get--data-structures.md) endpoint.
  maxSizeMB: int # The maximum size of the data store (defined in MB).
]: any -> record<dataStore: record<id: int, name: string, records: int, size: string, maxSize: string, teamId: int, datastructureId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-stores")
  let body = {name: $name, teamId: $teamId, datastructureId: $datastructureId, maxSizeMB: $maxSizeMB} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete data stores
#
# DELETE /data-stores
export def "data-stores delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # Confirms the deletion if a data store is included in at least one scenario. Confirmation is required because the scenario will stop working without the data store. If the parameter is missing or it is set to `false` an error code is returned and the resource is not deleted. (e.g. true)
  --teamId: int # The unique ID of the team from which the data store will be deleted. (e.g. 1)
  --ids: list # The IDs of data stores to delete. You can either use only this parameter alone or use the `all` parameter, or the `all` parameter together with the `exceptIds` parameter.
  --exceptIds: list # The IDs of data stores to be excluded from deleting. It can be only used together with the `all` parameter set to `true`.
  --all: string@bool-completer # If set to `true`, all data stores will be deleted. It can be used alone or together with the `exceptIds` parameter.
]: any -> record<dataStores: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/data-stores" $qp)
  let body = {ids: $ids, exceptIds: $exceptIds, all: $all} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get data store details
#
# GET /data-stores/{dataStoreId}
export def "data-stores get" [
  dataStoreId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies the group of values to return. For example, you can retrieve only names and IDs of data stores for a team with a given ID.
]: nothing -> record<dataStore: record<id: int, name: string, records: int, size: string, maxSize: string, teamId: int, datastructureId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/data-stores/($dataStoreId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update data store
#
# PATCH /data-stores/{dataStoreId}
export def "data-stores patch" [
  dataStoreId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The data store name. The name must be at most 128 characters long and does not need to be unique.
  --datastructureId: int # The unique ID of the data structure included in the data store. All data structures IDs for a given team can be retrieved from the [List data structures](/api-reference/data-structures/get--data-structures.md) endpoint.
  --maxSizeMB: int # The maximum size of the data store (defined in MB).
]: any -> record<dataStore: record<id: int, name: string, records: int, size: string, maxSize: string, teamId: int, datastructureId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-stores/($dataStoreId)")
  let body = {name: $name, datastructureId: $datastructureId, maxSizeMB: $maxSizeMB} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List data store records
#
# GET /data-stores/{dataStoreId}/data
export def "data-stores-data get" [
  dataStoreId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pglimit: int # The maximum number of entities you want to get in the response.
  --pgoffset: int # The number of entities you want to skip before getting entities you want.
]: nothing -> record<records: table<key: string, data: record>, spec: list<record>, strict: bool, count: int, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pg[limit]" $pglimit "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data-stores/($dataStoreId)/data" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create data store record
#
# POST /data-stores/{dataStoreId}/data
export def "data-stores-data post" [
  dataStoreId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string # The unique key of the data store record. If no key is provided, it will be automatically generated.
  --data: record # The data of the data store record. The structure strictly depends on the included data structure. If no data is provided, in response the values will be set to null.
]: any -> record<key: string, data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-stores/($dataStoreId)/data")
  let body = {key: $key, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete data store records
#
# DELETE /data-stores/{dataStoreId}/data
export def "data-stores-data delete" [
  dataStoreId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # Set to `true` to confirm deleting of the data store records. Otherwise, you get an error and Make won't delete the data store records. (e.g. true)
  --keys: list # The keys of data store records you want to delete. Use the `all` and `confirmed` parameters if you want to delete all records in the data store.
  --all: string@bool-completer # Set to `true` to delete all records in the data store. Use the `confirmed` parameter to confirm the deletion. You can also use the `exceptKeys` parameter to specify keys of the records that you want to keep in the data store.
  --exceptKeys: list # Specify the keys of the data store records you want to keep when deleting all records from the data store.
]: any -> record<keys: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data-stores/($dataStoreId)/data" $qp)
  let body = {keys: $keys, all: $all, exceptKeys: $exceptKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update entire data store record
#
# PUT /data-stores/{dataStoreId}/data/{dataStoreKeyRecord}
export def "data-stores-data put" [
  dataStoreId: int
  dataStoreKeyRecord: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<key: string, data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-stores/($dataStoreId)/data/($dataStoreKeyRecord)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update data store record details
#
# PATCH /data-stores/{dataStoreId}/data/{dataStoreKeyRecord}
export def "data-stores-data patch" [
  dataStoreId: int
  dataStoreKeyRecord: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<key: string, data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-stores/($dataStoreId)/data/($dataStoreKeyRecord)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List data structures
#
# GET /data-structures
export def "data-structures list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The unique ID of the team whose data structures will be retrieved. (e.g. 123)
  --cols: list # Specifies the group of values to return. For example, you can retrieve only names of data structures for a team with a given ID.
  --pgsortBy: string@pgsortBy-completer # The value that will be used to sort returned entities by.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<dataStructures: table<id: int, teamId: int, name: string, strict: bool, spec: list>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "cols[]" $cols "multi") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/data-structures" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create data structure
#
# POST /data-structures
export def "data-structures post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  teamId: int # The unique ID of the team in which the data structure will be created.
  name: string # The name of the data structure. The maximum length of the name is 128 characters.
  --strict: string@bool-completer # Set to `true` to enforce strict validation of the data put in the data structure. With the strict validation enabled, the data structure won't store data that don't fit into the structure and the storing module will return an error.  The default value of this parameter is `false`. With the default setting, the modules using the data structure will process data that don't conform to the data structure.  (e.g. true)
  spec: list # Sets the data structure specification.
]: any -> record<dataStructure: record<id: int, teamId: int, name: string, strict: bool, spec: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-structures")
  let body = {teamId: $teamId, name: $name, strict: $strict, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get data structure
#
# GET /data-structures/{dataStructureId}
export def "data-structures get" [
  dataStructureId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies the group of values to return. For example, you can retrieve only name of a data structure.
]: nothing -> record<dataStructure: record<id: int, teamId: int, name: string, strict: bool, spec: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/data-structures/($dataStructureId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update data structure
#
# PATCH /data-structures/{dataStructureId}
export def "data-structures patch" [
  dataStructureId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the data structure. The maximum length of the name is 128 characters.
  --strict: string@bool-completer # Set to `true` to enforce strict validation of the data put in the data structure. With the strict validation enabled, the data structure won't store data that don't fit into the structure and the storing module will return an error.  The default value of this parameter is `false`. With the default setting, the modules using the data structure will process data that don't conform to the data structure.  (e.g. false)
  --spec: list # Sets the data structure specification.   Note that when you update the data structure specification with the `spec` parameter, you have to provide all structure fields you want to use. Make replaces the old structure specification with the new one."
]: any -> record<dataStructure: record<id: int, teamId: int, name: string, strict: bool, spec: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-structures/($dataStructureId)")
  let body = {name: $name, strict: $strict, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete data structure
#
# DELETE /data-structures/{dataStructureId}
export def "data-structures delete" [
  dataStructureId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # Confirms the deletion if a data structure is included in at least one scenario. Confirmation is required because the scenario will stop working without the data structure. If the parameter is missing or it is set to `false` an error code is returned and the resource is not deleted. (e.g. true)
]: nothing -> record<dataStructure: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data-structures/($dataStructureId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Clone data structure
#
# POST /data-structures/{dataStructureId}/clone
export def "data-structures-clone post" [
  dataStructureId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the data structure clone. The maximum length of the name is 128 characters.
  --targetTeamId: int # The ID of the team that should use the data structure clone. If you don't specify the `targetTeamId` Make clones the data structure in the original team.
]: any -> record<dataStructure: record<id: int, teamId: int, name: string, strict: bool, spec: list<any>>, differentTeam: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-structures/($dataStructureId)/clone")
  let body = {name: $name, targetTeamId: $targetTeamId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List
#
# GET /devices
export def "devices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # e.g. 1
  --assigned: string@bool-completer # true = devices with scenarioId; false = devices without scenarioId - this filter only affects the trigger scope (e.g. true)
  --viewForScenarioId: int # Devices assigned to the scenario and not assigned devices. If this parameter is set assigned parameter is ignored. (e.g. 4)
  --scope: list # e.g. call
  --cols: list # e.g. name
]: nothing -> record<devices: table<id: int, name: string, teamId: int, udid: string, scope: list, info: record, queueCount: int, queueLimit: int, scenarioId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "assigned" $assigned "scalar") (serialize-qp "viewForScenarioId" $viewForScenarioId "scalar") (serialize-qp "scope[]" $scope "multi") (serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/devices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Detail
#
# GET /devices/{deviceId}
export def "devices get" [
  deviceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --inspector: int # e.g. 1
  --cols: list # e.g. name
]: nothing -> record<device: record<id: int, name: string, teamId: int, udid: string, scope: list<string>, info: record, queueCount: int, queueLimit: int, scenarioId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "inspector" $inspector "scalar") (serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/devices/($deviceId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Partial update
#
# PATCH /devices/{deviceId}
export def "devices patch" [
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # e.g. name
  --body: record
]: any -> record<device: record<id: int, name: string, teamId: int, udid: string, scope: list<string>, info: record, queueCount: int, queueLimit: int, scenarioId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/devices/($deviceId)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /devices/{deviceId}
export def "devices delete" [
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # e.g. true
]: nothing -> record<device: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/devices/($deviceId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create request
#
# POST /devices/request
export def "devices-request post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --inspector: int # e.g. 1
  --name: string
  --teamId: int
]: any -> record<createDeviceRequest: record<udid: string, inspector: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "inspector" $inspector "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/devices/request" $qp)
  let body = {name: $name, teamId: $teamId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List
#
# GET /devices/{deviceId}/incomings
export def "devices-incomings list" [
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scope: string # e.g. new_sms
  --pgsortBy: string # The value that will be used to sort returned entities by.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<incomings: table<id: string, scope: string, size: int, created: string>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/devices/($deviceId)/incomings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete
#
# DELETE /devices/{deviceId}/incomings
export def "devices-incomings delete" [
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # e.g. true
  --ids: list
  --exceptIds: list
  --all: string@bool-completer
]: any -> record<incomings: list<string>, error: record<name: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/devices/($deviceId)/incomings" $qp)
  let body = {ids: $ids, exceptIds: $exceptIds, all: $all} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Detail
#
# GET /devices/{deviceId}/incomings/{incomingId}
export def "devices-incomings get" [
  deviceId: string
  incomingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, scope: string, size: int, created: string, data: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/devices/($deviceId)/incomings/($incomingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stats
#
# GET /devices/{deviceId}/incomings/stats
export def "devices-incomings-stats get" [
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scope: string # e.g. new_sms
]: nothing -> record<incomingStat: record<queue: int, limit: int, enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/devices/($deviceId)/incomings/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List
#
# GET /devices/{deviceId}/outgoings
export def "devices-outgoings list" [
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scope: string # e.g. new_sms
  --pgsortBy: string # The value that will be used to sort returned entities by.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<outgoings: table<id: string, scope: string, size: int, created: string>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/devices/($deviceId)/outgoings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete
#
# DELETE /devices/{deviceId}/outgoings
export def "devices-outgoings delete" [
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # e.g. true
  --ids: list
  --exceptIds: list
  --all: string@bool-completer
]: any -> record<outgoings: list<string>, error: record<name: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/devices/($deviceId)/outgoings" $qp)
  let body = {ids: $ids, exceptIds: $exceptIds, all: $all} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Detail
#
# GET /devices/{deviceId}/outgoings/{outgoingId}
export def "devices-outgoings get" [
  deviceId: string
  outgoingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, scope: string, size: int, created: string, data: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/devices/($deviceId)/outgoings/($outgoingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List scenario incomplete executions
#
# GET /dlqs
export def "dlqs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scenarioId: int # The ID value of the scenario. Use the API call `GET /scenarios` to get the ID of the scenario. If your scenario is placed in a folder, use the API call `GET /scenarios-folders?teamId={teamId}` first. (e.g. 4)
]: nothing -> record<dlqs: table<id: string, reason: string, created: string, size: int, resolved: bool, retry: bool, attempts: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scenarioId" $scenarioId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dlqs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete scenario incomplete executions
#
# DELETE /dlqs
export def "dlqs delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scenarioId: int # The ID value of the scenario. Use the API call `GET /scenarios` to get the ID of the scenario. If your scenario is placed in a folder, use the API call `GET /scenarios-folders?teamId={teamId}` first. (e.g. 4)
  --confirmed: string@bool-completer # Set to `true` to confirm deleting the incomplete executions. Otherwise the API call fails with the error IM004 (406). (e.g. true)
  --ids: list # The ID values of the scenario incomplete executions that you want to delete. Use the API call `GET /dlqs/?scenarioId={scenarioId}` to get the ID values of the webhook processing queue items.
  --exceptIds: list # If you are deleting all of the incomplete executions with the `all:true` parameter, you can specify the ID values of the incomplete executions that you want to keep. Use the API call `GET /dlqs?scenarioId={scenarioId}` to get the ID values of the incomplete executions.
  --all: string@bool-completer # Set to `true` to delete all incomplete executions of the specified scenario.
]: any -> record<dlqs: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scenarioId" $scenarioId "scalar") (serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dlqs" $qp)
  let body = {ids: $ids, exceptIds: $exceptIds, all: $all} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Incomplete execution detail
#
# GET /dlqs/{dlqId}
export def "dlqs get" [
  dlqId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dlq: record<id: string, scenarioId: int, scenarioName: string, companyId: int, companyName: string, resolved: bool, deleted: bool, index: int, created: string, executionId: string, retry: bool, attempts: int, size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dlqs/($dlqId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update incomplete execution
#
# PATCH /dlqs/{dlqId}
export def "dlqs patch" [
  dlqId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blueprint: string # The blueprint you want to use to resolve the incomplete execution. If you download the blueprint from a Make scenario as a JSON object, you have to escape the blueprint contents to be able to send it as a string.
  --failer: int # The module ID which caused the incomplete execution of the scenario.
]: any -> record<dlq: record<failer: int, blueprint: record<flow: list, name: string, metadata: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dlqs/($dlqId)")
  let body = {blueprint: $blueprint, failer: $failer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete - deprecated
#
# DELETE /dlqs/{dlqId}
# DEPRECATED
@deprecated
export def "dlqs delete-by-dlqId" [
  dlqId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dlq: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dlqs/($dlqId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get failed scenario blueprint
#
# GET /dlqs/{dlqId}/blueprint
export def "dlqs-blueprint get" [
  dlqId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, response: record<blueprint: record<flow: list, name: string, metadata: record>, company: int, idSequence: int, reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dlqs/($dlqId)/blueprint")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get incomplete execution bundles
#
# GET /dlqs/{dlqId}/bundle
export def "dlqs-bundle get" [
  dlqId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, response: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dlqs/($dlqId)/bundle")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List incomplete executions logs
#
# GET /dlqs/{dlqId}/logs
export def "dlqs-logs list" [
  dlqId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: int@status-completer-1 # The status number of the incomplete execution. The status numbers correspond to the following statuses:  - 1: success,  - 2: warning,  - 3: error. (e.g. 3)
  --qp-from: int # The moment from which you want to list the incomplete execution logs. The timestamp is in the [UNIX timestamp](https://en.wikipedia.org/wiki/Unix_time) format. (format: timestamp, e.g. 1548975600000)
  --qp-to: int # Limits the returned incomplete execution logs to those that were created before the specified moment. The timestamp is in the [UNIX timestamp](https://en.wikipedia.org/wiki/Unix_time) format. (format: timestamp, e.g. 1574782119387)
]: nothing -> record<dlqLogs: table<imtId: string, duration: int, transfer: int, operations: int, centicredits: any, teamId: int, id: string, type: string, authorId: string, timestamp: string, status: int, instant: bool, organizationId: int>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dlqs/($dlqId)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Incomplete execution log detail
#
# GET /dlqs/{dlqId}/logs/{executionDlqId}
export def "dlqs-logs get" [
  dlqId: string
  executionDlqId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dlqLog: record<imtId: string, duration: int, transfer: int, operations: int, centicredits: any, teamId: int, id: string, type: string, authorId: string, timestamp: string, status: int, instant: bool, organizationId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dlqs/($dlqId)/logs/($executionDlqId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retry incomplete execution
#
# POST /dlqs/{dlqId}/retry
export def "dlqs-retry post-by-dlqId" [
  dlqId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dlq: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dlqs/($dlqId)/retry")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retry multiple incomplete executions
#
# POST /dlqs/retry
export def "dlqs-retry post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scenarioId: int # The ID of the scenario. You can get the `scenarioId` with the [List scenarios](/scenarios-get) API call. (e.g. 112)
  --ids: list # The list of incomplete execution IDs you want to retry. All of the IDs have to belong to the same scenario.
  --all: string@bool-completer # Set to `true` to retry all incomplete executions of the scenario.
  --exceptIds: list # You can use this parameter together with the `all` parameter to specify incomplete execution IDs which shouldn't be retried.
]: any -> record<dlqs: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scenarioId" $scenarioId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dlqs/retry" $qp)
  let body = {ids: $ids, all: $all, exceptIds: $exceptIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List module types
#
# GET /enums/module-types
export def "enums-module-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<moduleTypes: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enums/module-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List timezones
#
# GET /enums/timezones
export def "enums-timezones get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<timezones: table<id: int, name: string, code: string, offset: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enums/timezones")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List countries
#
# GET /enums/countries
export def "enums-countries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<countries: table<id: int, name: string, code: string, code2: string, stripeRegion: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enums/countries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List US states
#
# GET /enums/us-states
export def "enums-us-states get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<usStates: table<id: int, name: string, code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enums/us-states")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List locales
#
# GET /enums/locales
export def "enums-locales get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<locales: table<id: int, name: string, code: string, angularCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enums/locales")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List languages
#
# GET /enums/languages
export def "enums-languages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --localized: string@bool-completer # When set to true, the response contains localized language names, for example --  German: Deutch or Czech: Čeština. This setting limits the number of returned languages to those that have defined their localized name. The default value is `false`. (e.g. true)
]: nothing -> record<languages: table<code: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "localized" $localized "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/enums/languages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user features
#
# GET /enums/user-features
export def "enums-user-features get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<userFeatures: table<title: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enums/user-features")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organization features
#
# GET /enums/organization-features
export def "enums-organization-features get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organizationFeatures: table<title: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enums/organization-features")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List email notification settings
#
# GET /enums/user-email-notifications
export def "enums-user-email-notifications get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --language: string # Language code in the ISO 639-1 code standard. Only `en` (English) language is supported. (e.g. en)
]: nothing -> record<userEmailNotifications: table<id: int, translationKey: string, name: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/enums/user-email-notifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List API token scopes
#
# GET /enums/user-api-token-scopes
export def "enums-user-api-token-scopes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<userApiTokenScopes: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enums/user-api-token-scopes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Make regions
#
# GET /enums/imt-regions
export def "enums-imt-regions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<imtRegions: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enums/imt-regions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Make zones
#
# GET /enums/imt-zones
export def "enums-imt-zones get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<imtZones: table<id: int, domain: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enums/imt-zones")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List apps review status
#
# GET /enums/apps-review-statuses
export def "enums-apps-review-statuses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<reviewStatuses: table<value: int, label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enums/apps-review-statuses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List variable types
#
# GET /enums/variable-types
export def "enums-variable-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<variableTypes: table<id: int, name: string, teamOnly: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enums/variable-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List LLM models
#
# GET /enums/llm-models
export def "enums-llm-models get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<llmModels: table<modelName: string, providerName: string, modelDisplayName: string, modelDisplayPriority: int, providerDisplayName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enums/llm-models")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List LLM builtin tiers
#
# GET /enums/llm-builtin-tiers
export def "enums-llm-builtin-tiers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<llmBuiltinTiers: table<tierName: string, modelName: string, providerName: string, centicreditsCoefficient: float, modelDisplayName: string, providerDisplayName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enums/llm-builtin-tiers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List custom functions
#
# GET /functions
export def "functions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The ID of the team. (e.g. 11)
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
]: nothing -> record<functions: table<id: int, name: string, args: string, description: string, updatedAt: string, createdByUser: record, createdAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "cols" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/functions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a custom function
#
# POST /functions
export def "functions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The ID of the team. (e.g. 11)
  name: string # The name of the custom function.
  description: string # The description of the custom function.
  --code: string # The code of the custom function.
]: any -> record<function: record<id: int, name: string, description: string, code: string, args: string, updatedAt: string, createdByUser: record<id: int, name: string, email: string>, createdAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/functions" $qp)
  let body = {name: $name, description: $description, code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check custom function code
#
# POST /functions/eval
export def "functions-eval post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The ID of the team. (e.g. 11)
  code: string # The code of the custom function.
]: any -> record<success: bool, error: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/functions/eval" $qp)
  let body = {code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Custom function detail
#
# GET /functions/{functionId}
export def "functions get" [
  functionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
]: nothing -> record<function: record<id: int, name: string, description: string, code: string, args: string, scenarios: list<record>, updatedAt: string, createdByUser: record<id: int, name: string, email: string>, createdAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/functions/($functionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a custom function
#
# PATCH /functions/{functionId}
export def "functions patch" [
  functionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # The description of the custom function. You can use maximum of 128 characters.
  --code: string # The code of the custom function.
]: any -> record<function: record<id: float, name: string, description: string, code: string, args: string, updatedAt: string, createdByUser: record<id: int, name: string, email: string>, createdAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/functions/($functionId)")
  let body = {description: $description, code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete custom function
#
# DELETE /functions/{functionId}
export def "functions delete" [
  functionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # Confirms deleting of the custom function. If you are using the custom function in a scenario Make requires the confirmation. (e.g. true)
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/functions/($functionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Custom function updates history
#
# GET /functions/{functionId}/history
export def "functions-history get" [
  functionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The ID of the team. (e.g. 11)
]: nothing -> record<functionHistory: table<id: int, previousCode: string, updatedAt: string, updatedBy: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/functions/($functionId)/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ping
#
# GET /ping
export def "ping get" [
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
  let full_url = (build-url $base "/ping")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List hooks
#
# GET /hooks
export def "hooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The unique ID of the team whose hooks will be retrieved. (e.g. 4)
  --typeName: string # The hook type. Two native Make hook types are `gateway-webhook` and `gateway-mailhook`. (e.g. gateway-webhook)
  --assigned: string@bool-completer # Specifies if the hook is assigned to a scenario. If set to `true`, the request will return only the hooks which the `scenarioId` value is not set to null. (e.g. true)
  --viewForScenarioId: int # This parameter shows only the hooks that can be used by a scenario with a specific ID, which means hooks that are not assigned to another scenario yet and the hook that is already assigned to this scenario. This can be useful because Make allows assigning any hook to only one scenario. If this parameter is set the `assigned` parameter is ignored. (e.g. 123)
]: nothing -> record<hooks: table<id: int, name: string, teamId: int, udid: string, type: string, packageName: string, theme: string, flags: record, editable: bool, queueCount: int, queueLimit: int, enabled: bool, gone: bool, typeName: string, data: record, scenarioId: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "typeName" $typeName "scalar") (serialize-qp "assigned" $assigned "scalar") (serialize-qp "viewForScenarioId" $viewForScenarioId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create hook
#
# POST /hooks
export def "hooks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the hook. The name must be at most 128 characters long and does not need to be unique.
  teamId: string # The unique ID of the team in which a hook will be created.
  typeName: string # The hook type strictly related to the app for which the hook was created.
  --method: string@bool-completer # Set the `method` parameter to `true` to add the HTTP method to the request body.
  --headers: string@bool-completer # Set the `headers` parameter to `true` to add headers to the request body.
  --stringify: string@bool-completer # Set the `stringify` parameter to `true` to return JSON payloads as strings.
  --IMTCONN: int # The unique ID of the connection that will be included in the created hook.
  --formId: string # The unique ID of the form that will be included in the created hook.
]: any -> record<hook: record<id: int, name: string, teamId: int, udid: string, type: string, packageName: string, theme: string, flags: record<form: bool>, editable: bool, queueCount: int, queueLimit: int, enabled: bool, gone: bool, typeName: string, data: record<headers: bool, method: bool, stringify: bool, teamId: int, ip: string, udt: int>, scenarioId: int, url: string>, formula: record<success: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hooks")
  let body = {name: $name, teamId: $teamId, typeName: $typeName, method: $method, headers: $headers, stringify: $stringify, __IMTCONN__: $IMTCONN, formId: $formId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get hook details
#
# GET /hooks/{hookId}
export def "hooks get" [
  hookId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<hook: record<id: int, name: string, teamId: int, udid: string, type: string, packageName: string, theme: string, flags: record<form: bool>, editable: bool, queueCount: int, queueLimit: int, enabled: bool, gone: bool, typeName: string, data: record<headers: bool, method: bool, stringify: bool, teamId: int, ip: string, udt: int>, scenarioId: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($hookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete hook
#
# DELETE /hooks/{hookId}
export def "hooks delete" [
  hookId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # Confirms the deletion if a hook is included in the scenario. Confirmation is required because the scenario will stop working without the hook. If the parameter is missing or it is set to `false` an error code is returned and the resource is not deleted. (e.g. true)
]: nothing -> record<hook: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/hooks/($hookId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update hook
#
# PATCH /hooks/{hookId}
export def "hooks patch" [
  hookId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the updated hook. The name must be at most 128 characters long and does not need to be unique.
]: any -> record<hook: record<id: int, name: string, teamId: int, udid: string, type: string, packageName: string, theme: string, flags: record<form: bool>, editable: bool, queueCount: int, queueLimit: int, enabled: bool, gone: bool, typeName: string, data: record<headers: bool, method: bool, stringify: bool, teamId: int, ip: string, udt: int>, scenarioId: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($hookId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Ping hook
#
# GET /hooks/{hookId}/ping
export def "hooks-ping get" [
  hookId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: string, attached: bool, learning: bool, gone: bool, dataStructure: table<name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($hookId)/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Learn start
#
# POST /hooks/{hookId}/learn-start
export def "hooks-learn-start post" [
  hookId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($hookId)/learn-start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Learn stop
#
# POST /hooks/{hookId}/learn-stop
export def "hooks-learn-stop post" [
  hookId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($hookId)/learn-stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable hook
#
# POST /hooks/{hookId}/enable
export def "hooks-enable post" [
  hookId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($hookId)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable hook
#
# POST /hooks/{hookId}/disable
export def "hooks-disable post" [
  hookId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($hookId)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set hook details
#
# POST /hooks/{hookId}/set-data
export def "hooks-set-data post" [
  hookId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<changed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($hookId)/set-data")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get webhook queue
#
# GET /hooks/{hookId}/incomings
export def "hooks-incomings list" [
  hookId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pgsortBy: string # The value that will be used to sort returned entities by.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<incomings: table<id: string, scope: string, size: int, created: string, data: record>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/hooks/($hookId)/incomings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete items from webhook queue
#
# DELETE /hooks/{hookId}/incomings
export def "hooks-incomings delete" [
  hookId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # Set to `true` to confirm deleting the webhook queue items. Otherwise the API call fails with the error IM004 (406). (e.g. true)
  --ids: list # The ID values of the webhook processing queue items that you want to delete. Use the API call `GET /hooks/{hookId}/incomings` to get the ID values of the webhook processing queue items.
  --exceptIds: list # If you are deleting all of the incomplete executions with the `all:true` parameter, you can specify the ID values of the webhook queue items that you want to keep. Use the API call `GET /hooks/{hookId}/incomings` to get the ID values of the webhook queue items.
  --all: string@bool-completer # Set to `true` to delete all items in the webhook processing queue.
]: any -> record<incomings: list<string>, error: record<name: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/hooks/($hookId)/incomings" $qp)
  let body = {ids: $ids, exceptIds: $exceptIds, all: $all} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get webhook queue item detail
#
# GET /hooks/{hookId}/incomings/{incomingId}
export def "hooks-incomings get" [
  hookId: int
  incomingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<incoming: record<id: string, scope: string, size: int, created: string, data: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($hookId)/incomings/($incomingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get webhook queue stats
#
# GET /hooks/{hookId}/incomings/stats
export def "hooks-incomings-stats get" [
  hookId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<incomingStat: record<queue: int, limit: int, enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hooks/($hookId)/incomings/stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get webhook logs
#
# GET /hooks/{hookId}/logs
export def "hooks-logs list" [
  hookId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-to: int # Limits data in the response to entries older than the specified timestamp. Use the [UNIX timestamp](https://en.wikipedia.org/wiki/Unix_time) format in milliseconds. (e.g. 1663495749015)
  --qp-from: int # Limits data in the response to entries newer than the specified timestamp. Use the [UNIX timestamp](https://en.wikipedia.org/wiki/Unix_time) format in milliseconds. (e.g. 1663495749015)
  --pgsortBy: string # The value that will be used to sort returned entities by.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<hookLogs: table<statusId: int, parser: string, replayable: bool, sizes: record, loggedAt: string, udids: list, typeId: int, id: int, appParser: string, imtId: string>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "to" $qp_to "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/hooks/($hookId)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get webhook execution detail
#
# GET /hooks/{hookId}/logs/{logId}
export def "hooks-logs get" [
  hookId: int
  logId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pgsortBy: string # The value that will be used to sort returned entities by.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<hookLog: record<statusId: int, parser: string, replayable: bool, data: record<request: record, response: record>, sizes: record<before: int, after: int>, loggedAt: string, udids: list<string>, typeId: int, id: int, appParser: string, imtId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/hooks/($hookId)/logs/($logId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List of apps+modules available to the current user for the scenario editor app search.
#
# GET /imt/apps
export def "imt-apps get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int # Organization context for filtering custom (SDK) apps and resolving feature controls.
  --scoredSearch: string@bool-completer # If `true`, the response is enriched with scoring (zone + team usage) and modules are aggregated per version. Requires `teamId`. When omitted, a non-scored shape is returned.
  --teamId: int # Team whose usage drives team-level module scoring. **Required when `scoredSearch=true`**; ignored otherwise.
]: nothing -> record<apps: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar") (serialize-qp "scoredSearch" $scoredSearch "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/imt/apps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# All verified and custom apps, that are available to current user or selected organisation.
#
# GET /imt/apps-meta
export def "imt-apps-meta get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --skipSdkApps: string@bool-completer # If set to true, custom apps will be excluded from response. These are either apps developed by the requesters organisation or installed from a shared link
  --organizationId: int # If set, return custom apps only from given organizationid, still returning all verified apps Has no effect if skipSdkApps is set to true
]: nothing -> record<apps: table<name: string, label: string, foreign: bool, theme: string, version: int, isPrivate: bool, app: bool, categories: list, keywords: string, premiumTier: int, brand: any, coming_soon: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skipSdkApps" $skipSdkApps "scalar") (serialize-qp "organizationId" $organizationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/imt/apps-meta" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List App Modules with Credentials
#
# GET /imt/apps/{name}/{version}/modules-with-credentials
# DEPRECATED
@deprecated
export def "imt-apps-modules-with-credentials get" [
  name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appModules: table<id: string, name: string, label: string, type: string, scope: list, hook: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/imt/apps/($name)/($version)/modules-with-credentials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Internal - Get organization details by IDs
#
# GET /internal/organizations
export def "internal-organizations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # An array of organization IDs to retrieve details for.
  --cols: list # An array of column names to include in the response for each organization. If omitted, all available columns are returned. (e.g. [id, name, created])
]: nothing -> record<organizations: table<id: int, name: string, created: string, updated: string, deleted: bool, deletedAt: string, countryId: int, externalId: string, features: record, initialTeamId: int, license: record, productFlags: record, productName: record, rev: int, slug: string, ssoType: string, timezoneId: int, userSessionTimeout: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "cols" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/internal/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization pause status
#
# GET /internal/organizations/{organizationId}/paused
export def "internal-organizations-paused get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<isPaused: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/internal/organizations/($organizationId)/paused")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get scenario credentials
#
# GET /internal/scenarios/{scenarioId}/credentials
export def "internal-scenarios-credentials get" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<scenarioAccounts: table<id: int, name: string, authorId: int, email: string, userName: string>, scenarioKeys: table<id: int, name: string, authorId: int, email: string, userName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/internal/scenarios/($scenarioId)/credentials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get device enrichments
#
# GET /internal/devices/enrichments
export def "internal-devices-enrichments get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Array of device IDs to retrieve enrichment data for. Each ID must be a positive integer. (e.g. [123, 456, 789])
]: nothing -> record<devices: table<id: int, udid: string, teamId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/internal/devices/enrichments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get scenario executions list
#
# GET /internal/scenarios/executions
export def "internal-scenarios-executions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --executionIds: list # Execution IDs which will be listed (limited to 1000)
]: nothing -> record<executions: table<executionId: string, scenarioId: int, teamId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "executionIds" $executionIds "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/internal/scenarios/executions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List scenarios for a team
#
# GET /internal/scenarios/list-for-team
export def "internal-scenarios-list-for-team get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # Numeric ID of the team whose scenarios to list.
  --updatedSince: int # Optional epoch-ms timestamp. When provided, switches to delta mode: returns all scenarios (including soft-deleted) whose lastEdit >= this value.  (format: int64)
]: nothing -> record<scenarios: table<id: int, name: string, isActive: bool, updatedAt: string, isDeleted: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "updatedSince" $updatedSince "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/internal/scenarios/list-for-team" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user features
#
# GET /internal/users/{userId}/features
export def "internal-users-features get" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<features: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/internal/users/($userId)/features")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Internal - Get platform settings
#
# GET /internal/settings
export def "internal-settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --settings: list # An array of settings IDs to include in the response. If omitted, all available settings are returned.
  --includeNulls: string@bool-completer # Should the response include null values for settings that are not set for the specified?
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "settings" $settings "multi") (serialize-qp "includeNulls" $includeNulls "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/internal/settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Internal - Create a team connection
#
# POST /internal/teams/{teamId}/connections
export def "internal-teams-connections post" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  accountName: string # The connection type identifier (e.g. 'ai-provider').
  accountType: string # The account type identifier, usually same as accountName.
  userId: int # The ID of the user creating the connection. Must exist and have 'account add' permission on the team.
  --language: string # Language code for localized labels (e.g. 'en', 'cs'). Defaults to 'en'.
  --data: record # Optional connection data/credentials.
]: any -> record<connection: record<id: int, name: string, accountName: string, accountType: string, oauth: bool, teamId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/internal/teams/($teamId)/connections")
  let body = {accountName: $accountName, accountType: $accountType, userId: $userId, language: $language, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Internal - Get a data structure (UDT) by id
#
# GET /internal/data-structures/{dataStructureId}
export def "internal-data-structures get" [
  dataStructureId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dataStructure: record<id: int, name: string, teamId: int, spec: list<record>, strict: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/internal/data-structures/($dataStructureId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List keys
#
# GET /keys
export def "keys list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The ID of the team. (e.g. 22)
  --typeName: string@typeName-completer # Use the key type to get only keys with the specified type. You can use the API call `GET /keys/types` to list available key types. (e.g. basicauth)
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for each column that you want included. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
]: nothing -> record<keys: table<id: int, name: string, typeName: string, teamId: int, packageName: string, theme: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "typeName" $typeName "scalar") (serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a key
#
# POST /keys
export def "keys post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  teamId: int # The ID of the team.
  name: string # The name of the key.
  typeName: string # Use the key type to get only keys with the specified type. You can use the API call `GET /keys/types` to list available key types.
  parameters: record # Additional parameters required to create the key.  Check the [list of key types](./get--keys--types.md) API call for the parameters you need to specify.
]: any -> record<key: record<id: int, name: string, typeName: string, teamId: int, packageName: string, theme: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/keys")
  let body = {teamId: $teamId, name: $name, typeName: $typeName, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List key types
#
# GET /keys/types
export def "keys-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<keysTypes: table<name: string, label: string, parameters: list, componentType: string, author: string, version: string, theme: string, icon: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/keys/types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get key details
#
# GET /keys/{keyId}
export def "keys get" [
  keyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the \"Filtering\" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
]: nothing -> record<key: record<id: int, name: string, typeName: string, teamId: int, packageName: string, theme: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($keyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a key
#
# PATCH /keys/{keyId}
export def "keys patch" [
  keyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<key: record<id: int, name: string, typeName: string, teamId: int, packageName: string, theme: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/($keyId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a key
#
# DELETE /keys/{keyId}
export def "keys delete" [
  keyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # Set this parameter to `true` to confirm deleting the key. Otherwise, you get an error and the key is not deleted. (e.g. true)
]: nothing -> record<key: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($keyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List notifications
#
# GET /notifications
export def "notifications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --unreadOnly: string@bool-completer # If set to `true`, this parameter returns only the unread notifications. (e.g. false)
  --imtZoneId: int # The unique ID of the Make zone. This parameter is required to retrieve notifications from the Make version. For other Make platforms, it can be ignored. The IDs of the zones can be obtained from the `/enums/imt-zones` endpoint. (e.g. 2)
  --pgsortBy: string@pgsortBy-completer-7 # The value that will be used to sort returned entities by. Notifications can be currently sorted only by ID.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<notifications: table<id: string, subject: string, read: string, created: string, type: int>, userUnreadNotifications: int, userZoneNotifications: table<imtZoneId: int, unreadNotifications: int>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unreadOnly" $unreadOnly "scalar") (serialize-qp "imtZoneId" $imtZoneId "scalar") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete notifications
#
# DELETE /notifications
export def "notifications delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --imtZoneId: int # The unique ID of the Make zone. This parameter is required to retrieve notifications from the Make version. For other Make platforms, it can be ignored. The IDs of the zones can be obtained from the `/enums/imt-zones` endpoint. (e.g. 2)
  ids: list # The array with IDs of the notifications to delete. Since the number of notifications can reach a `BigInt` and because of the limitations of the Open API format, the IDs need to be strings.
]: any -> record<notifications: table<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "imtZoneId" $imtZoneId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications" $qp)
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get notification detail
#
# GET /notifications/{notificationId}
export def "notifications get" [
  notificationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --imtZoneId: int # The unique ID of the Make zone. This parameter is required to retrieve notifications from the Make version. For other Make platforms, it can be ignored. The IDs of the zones can be obtained from the `/enums/imt-zones` endpoint. (e.g. 2)
]: nothing -> record<notification: record<id: string, subject: string, read: string, created: string, type: int, body: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "imtZoneId" $imtZoneId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/notifications/($notificationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark all notifications as read
#
# POST /notifications/mark-as-read
export def "notifications-mark-as-read post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # Forces the request to mark all notifications as read. This parameter can only have the `all` value.
  --imtZoneId: int # The unique ID of the Make zone. This parameter is required to retrieve notifications from the Make version. For other Make platforms, it can be ignored. The IDs of the zones can be obtained from the `/enums/imt-zones` endpoint. (e.g. 2)
]: nothing -> record<notifications: table<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar") (serialize-qp "imtZoneId" $imtZoneId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/mark-as-read" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Authorize (deprecated)
#
# POST /oauth/auth/{connectionId}
# DEPRECATED
@deprecated
export def "oauth-auth post" [
  connectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scope: list
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/oauth/auth/($connectionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Authorize
#
# GET /oauth/auth/{connectionId}
export def "oauth-auth get" [
  connectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scope: list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/oauth/auth/($connectionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reauthorize (deprecated)
#
# POST /oauth/reauth/{connectionId}
# DEPRECATED
@deprecated
export def "oauth-reauth post" [
  connectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scope: string # e.g. scope=value&scope=another_value
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/oauth/reauth/($connectionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reauthorize
#
# GET /oauth/reauth/{connectionId}
export def "oauth-reauth get" [
  connectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scope: list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/oauth/reauth/($connectionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Extend (deprecated)
#
# POST /oauth/extend/{connectionId}
# DEPRECATED
@deprecated
export def "oauth-extend post" [
  connectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/oauth/extend/($connectionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Extend
#
# GET /oauth/extend/{connectionId}
export def "oauth-extend get" [
  connectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/oauth/extend/($connectionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Oauth Callback (deprecated)
#
# POST /oauth/cb/{connectionType}
# DEPRECATED
@deprecated
export def "oauth-cb post-by-connectionType" [
  connectionType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ok: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/oauth/cb/($connectionType)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Oauth Callback
#
# GET /oauth/cb/{connectionType}
export def "oauth-cb list" [
  connectionType: string
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
  let full_url = (build-url $base $"/oauth/cb/($connectionType)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Oauth Callback Id (deprecated)
#
# POST /oauth/cb/{connectionType}/{connectionId}
# DEPRECATED
@deprecated
export def "oauth-cb post-by-connectionType-connectionId" [
  connectionType: string
  connectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ok: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/oauth/cb/($connectionType)/($connectionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Oauth Callback Id
#
# GET /oauth/cb/{connectionType}/{connectionId}
export def "oauth-cb get" [
  connectionType: string
  connectionId: int
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
  let full_url = (build-url $base $"/oauth/cb/($connectionType)/($connectionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Parses saml xml to json with info about user
#
# POST /oauth/convert/saml-xml-to-json
export def "oauth-convert-saml-xml-to-json post" [
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
  let full_url = (build-url $base "/oauth/convert/saml-xml-to-json")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List user organizations
#
# GET /organizations
export def "organizations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --zone: string # The URL of your Make instance domain. (e.g. eu1.make.com)
  --externalId: string # Make White Label product instances use the `externalId` parameter for security reasons. This parameter has `null` value in the public Make Cloud instance.
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
  --pgsortBy: string # The value that will be used to sort returned entities by.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<organizations: table<id: int, name: string, createdAt: string, serviceName: string, nextReset: string, lastReset: string, isPaused: bool, countryId: int, timezoneId: int, deleted: bool, license: record, zone: string, teams: list, productName: string, ssoType: string, scenarios: int, activeScenarios: int, tfaEnforced: bool, featureControls: list>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "zone" $zone "scalar") (serialize-qp "externalId" $externalId "scalar") (serialize-qp "cols" $cols "multi") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an organization
#
# POST /organizations
export def "organizations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the organization. The name may contain only letters, numbers, spaces, and the following special characters: `'`, `-`, `.`, `(`, `)`, `*`, `+`, `,`, `@`, `_`, `/`. The name must not start or end with a space.
  regionId: int # ID of the Make region instance associated with the organization. Get the list of Make regions with the API call `GET /enums/imt-regions`.
  timezoneId: int # The ID of the timezone associated with the organization. Get the list of the timezone IDs with the API call `GET /enums/timezones`.
  countryId: int # The ID of the country associated with the organization. Get the list of the country IDs with the API call `GET /enums/countries`.
]: any -> record<organization: record<id: int, name: string, createdAt: string, serviceName: string, nextReset: string, lastReset: string, isPaused: bool, countryId: int, timezoneId: int, deleted: bool, license: record, zone: string, teams: list<record>, productName: string, ssoType: string, scenarios: int, activeScenarios: int, tfaEnforced: bool, featureControls: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizations")
  let body = {name: $name, regionId: $regionId, timezoneId: $timezoneId, countryId: $countryId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Invitation detail
#
# GET /organizations/invitation
export def "organizations-invitation get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hash: string # e.g. bf1effe1-bc9d-4ab3-9414-9c3b66175305
]: nothing -> record<organization: record<id: int, name: string>, user: record<id: int, name: string, email: string, language: string, timezoneId: int, localeId: int, countryId: int, features: record<allow_apps: bool>, avatar: string, lastLogin: string, tfaStatus: int, supportEligible: bool, userTeamIds: list<int>, privateSpace: record<id: int, name: string, globalAgentsEnabled: bool, type: string, operationsLimit: int, transferLimit: any, consumedOperations: int, consumedTransfer: any, isPaused: bool, consumedCenticredits: int>>, userOrganizationRole: record<userId: int, organizationId: int, usersRoleId: int, invitation: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hash" $hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizations/invitation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept invitation
#
# POST /organizations/accept-invitation
export def "organizations-accept-invitation post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hash: string
]: any -> record<user: record<id: int, name: string, email: string, language: string, timezoneId: int, localeId: int, countryId: int, features: record<allow_apps: bool>, avatar: string, lastLogin: string, tfaStatus: int, supportEligible: bool, userTeamIds: list<int>, privateSpace: record<id: int, name: string, globalAgentsEnabled: bool, type: string, operationsLimit: int, transferLimit: any, consumedOperations: int, consumedTransfer: any, isPaused: bool, consumedCenticredits: int>>, userOrganizationRole: record<userId: int, organizationId: int, usersRoleId: int, invitation: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizations/accept-invitation")
  let body = {hash: $hash} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get organization details
#
# GET /organizations/{organizationId}
export def "organizations get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: string@bool-completer # Set this parameter to `true` if you are using the API call `GET /organizations/{organizationId}` shortly after creating the organization. The API call will first check synchronization of the Make backend and your Make zone data. If you don't use this argument, the API call might fail with an error due to unfinished data synchronization. The default value of this argument is `false`. (e.g. true)
]: nothing -> record<organization: record<id: int, name: string, createdAt: string, serviceName: string, nextReset: string, lastReset: string, isPaused: bool, countryId: int, timezoneId: int, deleted: bool, license: record, zone: string, teams: list<record>, productName: string, ssoType: string, scenarios: int, activeScenarios: int, tfaEnforced: bool, featureControls: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update organization information
#
# PATCH /organizations/{organizationId}
export def "organizations patch" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The new name of the organization. The name may contain only letters, numbers, spaces, and the following special characters: `'`, `-`, `.`, `(`, `)`, `*`, `+`, `,`, `@`, `_`, `/`. The name must not start or end with a space.
  --countryId: int # The ID of the country associated with the organization. Get the list of the country IDs with the API call `GET /enums/countries`.
  --timezoneId: int # The ID of the timezone associated with the organization. Get the `timezoneId` values with the API call `GET /enums/timezones`.
]: any -> record<organization: record<id: int, name: string, createdAt: string, serviceName: string, nextReset: string, lastReset: string, isPaused: bool, countryId: int, timezoneId: int, deleted: bool, license: record, zone: string, teams: list<record>, productName: string, ssoType: string, scenarios: int, activeScenarios: int, tfaEnforced: bool, featureControls: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)")
  let body = {name: $name, countryId: $countryId, timezoneId: $timezoneId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an organization
#
# DELETE /organizations/{organizationId}
export def "organizations delete" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # Set to `true` to confirm the organization deletion. Otherwise, if the organization has active scenarios, Make won't delete the organization and the API call returns an error. (e.g. true)
]: nothing -> record<organization: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of custom apps
#
# GET /organizations/{organizationId}/apps
export def "organizations-apps get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<installedApps: table<appName: string, appVersion: int, organizationId: int, installedAt: string, installedBy: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/apps")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get list of past payments
#
# GET /organizations/{organizationId}/payments
export def "organizations-payments get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pgsortBy: string # The value that will be used to sort returned entities by.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<payments: table<id: string, invoice_number: int, created: string, type_name: string, status_name: string, product_name: record, payment_method: record, amount_total: float, currency_code: string, invoice_url: string, hosted_invoice_url: string, period_from: string, period_to: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get detail of an active subscription
#
# GET /organizations/{organizationId}/subscription
export def "organizations-subscription get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<product: record<id: float, name: string, nextBill: string, price: record<id: float, price: float, currencyCode: string, period: string>, coupon: record<validFrom: string, validTo: string, price: float, currencyCode: string, productId: float, productName: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new subscription
#
# POST /organizations/{organizationId}/subscription
# --customer shape: {email: string, name: string, isBusiness: bool, companyName?: string, taxId?: string, countryId: float, city?: string, line1?: string, line2?: string, postalCode?: string, state?: string}
export def "organizations-subscription post" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  priceId: float
  --couponCode: string
  --customer: record # shape: {email: string, name: string, isBusiness: bool, companyName?: string, taxId?: string, countryId: float, city?: string, line1?: string, line2?: string, postalCode?: string, state?: string}
]: any -> record<sessionId: float, url: string, subscriptionId: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/subscription")
  let body = {priceId: $priceId, couponCode: $couponCode, customer: $customer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change subscription
#
# PATCH /organizations/{organizationId}/subscription
# --customer shape: {email: string, name: string, isBusiness: bool, companyName?: string, taxId?: string, countryId: float, city?: string, line1?: string, line2?: string, postalCode?: string, state?: string}
export def "organizations-subscription patch" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  priceId: float
  --customer: record # shape: {email: string, name: string, isBusiness: bool, companyName?: string, taxId?: string, countryId: float, city?: string, line1?: string, line2?: string, postalCode?: string, state?: string}
]: any -> record<ok: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/subscription")
  let body = {priceId: $priceId, customer: $customer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel the active subscription
#
# DELETE /organizations/{organizationId}/subscription
export def "organizations-subscription delete" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ok: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List payment method types
#
# GET /organizations/{organizationId}/subscription/payment-method-types
export def "organizations-subscription-payment-method-types get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<paymentMethodTypes: table<value: string, label: string, canBeDefaultForSubscription: bool, canBeDefaultForExtras: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/subscription/payment-method-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List payment methods
#
# GET /organizations/{organizationId}/subscription/payment-methods
export def "organizations-subscription-payment-methods get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<paymentMethods: table<id: string, type: string, valid: bool, customerDefaultMethod: bool, customerDefaultExtrasMethod: bool, isImmediate: bool, created: string, methodDetails: record>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/subscription/payment-methods")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a payment method
#
# DELETE /organizations/{organizationId}/subscription/payment-methods/{paymentMethodId}
export def "organizations-subscription-payment-methods delete" [
  organizationId: int
  paymentMethodId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ok: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/subscription/payment-methods/($paymentMethodId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set default payment method
#
# PATCH /organizations/{organizationId}/subscription/payment-methods/{paymentMethodId}/default
export def "organizations-subscription-payment-methods-default patch" [
  organizationId: int
  paymentMethodId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --target: string@target-completer # What to set as default. Defaults to 'both'. 'extras' and 'both' throw 400 if the payment method is not immediate. 'subscription' sets default for subscription only.
]: any -> record<paymentMethodId: string, paymentMethodType: string, isDefaultForSubscription: bool, isDefaultForExtras: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/subscription/payment-methods/($paymentMethodId)/default")
  let body = {target: $target} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sets Free plan subscription
#
# POST /organizations/{organizationId}/subscription-free
export def "organizations-subscription-free post" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer
]: nothing -> record<customerId: int, subscriptionId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/subscription-free" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get universal discount
#
# GET /organizations/{organizationId}/universal-discount
export def "organizations-universal-discount get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<universalDiscount: record<id: int, type: string, percentOff: float, validTo: string, rules: record<lost_on_cancel: bool, lost_on_price_downgrade: bool, lost_on_price_upgrade: bool, lost_on_product_downgrade: bool, lost_on_product_upgrade: bool, lost_on_other_discount: bool, applies_to_extras: bool, redeemable_by_admin: bool, redeemable_by_user: bool>, isActive: bool, bannerText: string, redeemUntil: string, canRedeemOnCurrentPlan: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/universal-discount")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Claim cancellation offer
#
# POST /organizations/{organizationId}/universal-discount/claim-cancellation-offer
export def "organizations-universal-discount-claim-cancellation-offer post" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ok: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/universal-discount/claim-cancellation-offer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Redeem universal discount on current plan
#
# POST /organizations/{organizationId}/universal-discount/redeem
export def "organizations-universal-discount-redeem post" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  universalDiscountId: int # The ID of the dormant universal discount to redeem (e.g. 42)
]: any -> record<ok: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/universal-discount/redeem")
  let body = {universalDiscountId: $universalDiscountId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Invite a user to the organization
#
# POST /organizations/{organizationId}/invite
export def "organizations-invite post" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --usersRoleId: int # The ID of the user organization role assigned to the invited user. Get list of user role IDs from the API call `GET /users/roles`.
  email: string # The user registration email. (format: email)
  name: string # The user name visible in the team and organization interface. The name may contain only letters, numbers, spaces, and the following special characters: `'`, `-`, `.`, `(`, `)`, `*`, `+`, `,`, `@`, `_`, `/`. The name must not start or end with a space.
  --note: string # Note added to the invitation.
  --teamsId: list # The list of team IDs to which the invited user will be assigned. The invited user will receive the team role **member**.
]: any -> record<user: record<id: int, name: string, email: string, language: string, timezoneId: int, localeId: int, countryId: int, features: record<allow_apps: bool>, avatar: string, lastLogin: string, tfaStatus: int, supportEligible: bool, userTeamIds: list<int>, privateSpace: record<id: int, name: string, globalAgentsEnabled: bool, type: string, operationsLimit: int, transferLimit: any, consumedOperations: int, consumedTransfer: any, isPaused: bool, consumedCenticredits: int>>, userOrganizationRole: record<userId: int, organizationId: int, usersRoleId: int, invitation: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/invite")
  let body = {usersRoleId: $usersRoleId, email: $email, name: $name, note: $note, teamsId: $teamsId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List user roles
#
# GET /organizations/{organizationId}/user-organization-roles
export def "organizations-user-organization-roles list" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
]: nothing -> record<userOrganizationRoles: table<userId: int, organizationId: int, usersRoleId: int, invitation: string, organizationTeamsCount: int, joinedTeamsCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/user-organization-roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user organization role details
#
# GET /organizations/{organizationId}/user-organization-roles/{userId}
export def "organizations-user-organization-roles get" [
  organizationId: int
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
]: nothing -> record<userOrganizationRole: record<userId: int, organizationId: int, usersRoleId: int, invitation: string, organizationTeamsCount: int, joinedTeamsCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/user-organization-roles/($userId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Transfer organization ownership
#
# POST /organizations/{organizationId}/user-organization-roles/transfer
export def "organizations-user-organization-roles-transfer post" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  userId: int # The ID of the user.
]: any -> record<userOrganizationRoles: table<userId: int, organizationId: int, usersRoleId: int, invitation: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/user-organization-roles/transfer")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get SSO certificates
#
# GET /organizations/{organizationId}/sso-certificates
export def "organizations-sso-certificates get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # Type of SSO certificate. (e.g. saml)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/sso-certificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a test clock (TEST ONLY)
#
# GET /organizations/{organizationId}/test-clock
export def "organizations-test-clock get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<testClock: record<id: string, object: string, created: int, deletes_after: int, frozen_time: int, livemode: bool, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/test-clock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Advance a test clock (TEST ONLY)
#
# POST /organizations/{organizationId}/test-clock/advance
export def "organizations-test-clock-advance post" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  timestampInSeconds: float
]: any -> record<ok: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/test-clock/advance")
  let body = {timestampInSeconds: $timestampInSeconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Trigger a pause/unpause task for an specific organization (TEST ONLY)
#
# POST /organizations/{organizationId}/test-pause-unpause
export def "organizations-test-pause-unpause post" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ok: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/test-pause-unpause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organization variables
#
# GET /organizations/{organizationId}/variables
export def "organizations-variables get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organizationVariables: record<typeId: int, name: string, value: any, isSystem: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/variables")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create organization variable
#
# POST /organizations/{organizationId}/variables
export def "organizations-variables post" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --typeId: float # Number representing the type of the custom variable. The mapping of `typeId` and variable types is as follows:  - 1: `number`,  - 2: `string`,  - 3: `boolean`,  - 4: `date`in ISO 8601 compliant format `YYYY-MM-DDTHH:mm:ss.sssZ`. For example: `1998-03-06T12:31:00.000Z`.
  --value: any # Value assigned to the custom variable.
  --name: string # The name of the variable. You can use letters, digits, `$` and `_` characters in the custom variable name.
]: any -> record<organizationVariable: record<typeId: int, name: string, value: any, isSystem: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/variables")
  let body = {typeId: $typeId, value: $value, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update organization variable
#
# PATCH /organizations/{organizationId}/variables/{variableName}
export def "organizations-variables patch" [
  organizationId: int
  variableName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --typeId: float # Number representing the type of the custom variable. The mapping of `typeId` and variable types is as follows:  - 1: `number`,  - 2: `string`,  - 3: `boolean`,  - 4: `date`in ISO 8601 compliant format `YYYY-MM-DDTHH:mm:ss.sssZ`. For example: `1998-03-06T12:31:00.000Z`.
  --value: any # Value assigned to the custom variable.
]: any -> record<organizationVariable: record<typeId: int, name: string, value: any, isSystem: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/variables/($variableName)")
  let body = {typeId: $typeId, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete organization variable
#
# DELETE /organizations/{organizationId}/variables/{variableName}
export def "organizations-variables delete" [
  organizationId: int
  variableName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # Set to `true` to confirm deleting the custom variable. Otherwise the API call fails with the error IM004 (406). (e.g. true)
]: nothing -> record<ok: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/variables/($variableName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# History of custom variable updates
#
# GET /organizations/{organizationId}/variables/{variableName}/history
export def "organizations-variables-history get" [
  organizationId: int
  variableName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organizationVariableHistory: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/variables/($variableName)/history")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Organization domain verification
#
# POST /organizations/{organizationId}/domains/{organizationDomainId}/verify
export def "organizations-domains-verify post" [
  organizationId: int
  organizationDomainId: int
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
  let full_url = (build-url $base $"/organizations/($organizationId)/domains/($organizationDomainId)/verify")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization usage
#
# GET /organizations/{organizationId}/usage
export def "organizations-usage get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationTimezone: string@bool-completer # When set to `true`, the endpoint will calculate and return usage data based on the organization's timezone instead of the user's local timezone. (e.g. true)
]: nothing -> record<data: table<date: string, operations: int, dataTransfer: int, centicredits: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationTimezone" $organizationTimezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/usage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search organization scenario execution logs
#
# POST /organizations/{organizationId}/scenarios/executions/search
export def "organizations-scenarios-executions-search post" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-from: int # Lower bound of the time window, as a millisecond Unix timestamp. Defaults to 7 days before `to` when omitted.  Applied at **UTC-day granularity**: the calendar day of this value is the earliest day searched, but executions earlier within that same day may still be returned.  (e.g. 1700000000000)
  --body-to: int # Upper bound of the time window, as a millisecond Unix timestamp. Defaults to the current time when omitted.  Applied at **UTC-day granularity**: the calendar day of this value is the latest day searched, but executions later within that same day may still be returned.  (e.g. 1700604800000)
  --teamId: int # Restrict the search to a single team within the organization. When omitted, all teams the authenticated user has access to are searched. (e.g. 27)
  --errorMessage: string # Substring matched against the execution's error message. Matching snippets are returned in the `highlight` field of each result. (e.g. timeout)
  --scenarioIds: list # Restrict the search to the specified scenario IDs. (e.g. [1229, 1230])
  --status: list # Filter executions by status. `1` is for success, `2` is for warning, and `3` is for error. (e.g. [3])
  --pageSize: int # The maximum number of executions to return. Capped at `500`. (default: 50, e.g. 50)
  --pageIndex: int # The zero-based index of the page to return. (default: 0, e.g. 0)
]: any -> record<results: table<imtId: string, id: string, kindId: int, scenarioId: int, scenarioName: string, timestamp: string, type: string, instant: bool, authorId: int, teamId: int, organizationId: int, duration: int, operations: int, centicredits: int, transfer: int, status: int, eventType: string, errorMessage: string, highlight: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/scenarios/executions/search")
  let body = {from: $body_from, to: $body_to, teamId: $teamId, errorMessage: $errorMessage, scenarioIds: $scenarioIds, status: $status, pageSize: $pageSize, pageIndex: $pageIndex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Full-text search scenario IO data
#
# POST /organizations/{organizationId}/scenarios/executions/io-data/search
export def "organizations-scenarios-executions-io-data-search post" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: string # The free-text expression to match against scenario module IO data. Supports quoted phrases. (e.g. "order_id":"12345")
  --teamId: int # Restrict the search to a single team within the organization. When omitted, all teams the authenticated user has access to are searched. (e.g. 27)
  --body-from: int # Lower bound of the time window, as a millisecond Unix timestamp.  Applied at **UTC-day granularity**: the calendar day of this value is the earliest day searched in the IO-data index, but records earlier within that same day may still be returned. Execution metadata joins use this same bound expanded by one day on each side.  (e.g. 1700000000000)
  --body-to: int # Upper bound of the time window, as a millisecond Unix timestamp.  Applied at **UTC-day granularity**: the calendar day of this value is the latest day searched in the IO-data index, but records later within that same day may still be returned. Execution metadata joins use this same bound expanded by one day on each side.  (e.g. 1700604800000)
  --scenarioIds: list # Restrict the search to the specified scenario IDs. (e.g. [1229])
  --appNames: list # Restrict the search to executions that used any of the listed apps (by app name). (e.g. [http, google-sheets])
  --moduleNames: list # Restrict the search to executions that used any of the listed module names. (e.g. [ActionSendData])
  --executionIds: list # Restrict the search to the specified execution IDs. (e.g. [da518adcd14b4b64ac6358823ccb80ca])
  --status: list # Which execution outcome's IO data to full-text search. `1` searches successful (`data`) records, `2` searches warning records, and `3` searches error (`err`) records. Multiple values may be combined. Defaults to `[1, 2, 3]` (all outcomes) when omitted.  (default: [1, 2, 3], e.g. [1, 2, 3])
  --pageSize: int # The maximum number of execution groups to return. Capped at `500`. (default: 20, e.g. 20)
  --pageIndex: int # The zero-based index of the page to return. (default: 0, e.g. 0)
]: any -> record<results: table<ioData: list, execution: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/scenarios/executions/io-data/search")
  let body = {query: $body_query, teamId: $teamId, from: $body_from, to: $body_to, scenarioIds: $scenarioIds, appNames: $appNames, moduleNames: $moduleNames, executionIds: $executionIds, status: $status, pageSize: $pageSize, pageIndex: $pageIndex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Count scenarios and executions matching a full-text query
#
# POST /organizations/{organizationId}/scenarios/executions/io-data/counts
export def "organizations-scenarios-executions-io-data-counts post" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: string # The free-text expression to match against scenario module IO data. Supports quoted phrases. (e.g. "order_id":"12345")
  --teamId: int # Restrict the search to a single team within the organization. When omitted, all teams the authenticated user has access to are searched. (e.g. 27)
  --body-from: int # Lower bound of the time window, as a millisecond Unix timestamp.  Applied at **UTC-day granularity**. When both `from` and `to` are omitted, the last 7 days are searched.  (e.g. 1700000000000)
  --body-to: int # Upper bound of the time window, as a millisecond Unix timestamp.  Applied at **UTC-day granularity**.  (e.g. 1700604800000)
  --scenarioIds: list # Restrict the search to the specified scenario IDs. (e.g. [1229])
  --status: list # Which execution outcome's IO data to full-text search. `1` searches successful (`data`) records, `2` searches warning records, and `3` searches error (`err`) records. Multiple values may be combined. Defaults to `[1, 2, 3]` (all outcomes) when omitted.  (default: [1, 2, 3], e.g. [1, 2, 3])
]: any -> record<totalScenarios: int, totalExecutions: int, scenarios: table<scenarioId: int, executionsCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/scenarios/executions/io-data/counts")
  let body = {query: $body_query, teamId: $teamId, from: $body_from, to: $body_to, scenarioIds: $scenarioIds, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Count executions by module for a full-text query within a scenario
#
# POST /organizations/{organizationId}/scenarios/executions/modules/io-data/counts
export def "organizations-scenarios-executions-modules-io-data-counts post" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: string # The free-text expression to match against scenario module IO data. Supports quoted phrases. (e.g. "order_id":"12345")
  scenarioId: int # The ID of the scenario to break down by module. (e.g. 1229)
  --teamId: int # Restrict the search to a single team within the organization. When omitted, all teams the authenticated user has access to are searched. (e.g. 27)
  --body-from: int # Lower bound of the time window, as a millisecond Unix timestamp.  Applied at **UTC-day granularity**. When both `from` and `to` are omitted, the last 7 days are searched.  (e.g. 1700000000000)
  --body-to: int # Upper bound of the time window, as a millisecond Unix timestamp.  Applied at **UTC-day granularity**.  (e.g. 1700604800000)
  --status: list # Which execution outcome's IO data to full-text search. `1` searches successful (`data`) records, `2` searches warning records, and `3` searches error (`err`) records. Multiple values may be combined. Defaults to `[1, 2, 3]` (all outcomes) when omitted.  (default: [1, 2, 3], e.g. [1, 2, 3])
]: any -> record<modules: table<module: string, executionsCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/scenarios/executions/modules/io-data/counts")
  let body = {query: $body_query, scenarioId: $scenarioId, teamId: $teamId, from: $body_from, to: $body_to, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get organization feature controls
#
# GET /organizations/{organizationId}/feature-controls
export def "organizations-feature-controls get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --featureControlName: string # The feature control name. (e.g. Make AI Tools)
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
]: nothing -> record<enableAllControlFeatures: bool, featureControls: table<id: int, name: string, label: record, description: record, tags: list, warning_message: record, enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "featureControlName" $featureControlName "scalar") (serialize-qp "cols" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/feature-controls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch organization feature controls
#
# PATCH /organizations/{organizationId}/feature-controls
export def "organizations-feature-controls patch" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # The ID of the feature control.
  --enabled: string@bool-completer # Indicates whether the feature control is enabled (true) or disabled (false).
]: any -> record<featureControls: record<id: int, enabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/feature-controls")
  let body = {id: $id, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set TFA enforcement for an organization
#
# PATCH /organizations/{organizationId}/tfa-enforcement
export def "organizations-tfa-enforcement patch" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable: string@bool-completer # Set to `true` to enable TFA enforcement for the organization, or `false` to disable it.
]: any -> record<organization: record<tfaEnforced: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/tfa-enforcement")
  let body = {enable: $enable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the organization's private-spaces settings
#
# GET /organizations/{organizationId}/private-spaces-settings
export def "organizations-private-spaces-settings get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<privateSpacesSettings: record<privateSpacesAutoCreationEnabled: bool, defaultOperationsLimit: int, addAdminsAsObservers: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/private-spaces-settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the organization's private-spaces settings
#
# PATCH /organizations/{organizationId}/private-spaces-settings
export def "organizations-private-spaces-settings patch" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # Required when enabling/disabling auto-creation, toggling admin observers, or bulk-updating existing limits. (e.g. true)
  --privateSpacesAutoCreationEnabled: string@bool-completer # When `true`, new members of the organization automatically get a private space.
  --defaultOperationsLimit: int # Default operations limit applied when a private space is auto-created. Pass `null` to set unlimited operations. (nullable)
  --bulkUpdateExistingLimits: string@bool-completer # When `true`, applies `defaultOperationsLimit` to every existing private-space team in the organization. Requires `defaultOperationsLimit` to be provided in the same request (rejected with `IM005` otherwise).
  --addAdminsAsObservers: string@bool-completer # When `true`, organization admins/owner are added as `Team Observer` to private spaces (and to all existing ones); when `false`, those implicit observers are removed. Enabling requires the `privateSpacesObservability` license (rejected with `SC402` otherwise).
]: any -> record<privateSpacesSettings: record<privateSpacesAutoCreationEnabled: bool, defaultOperationsLimit: int, addAdminsAsObservers: bool>, bulkCreatedTeamIds: list<int>, bulkUpdatedTeamIds: list<int>, bulkDeletedTeamIds: list<int>, observersAddedTeamIds: list<int>, observersRemovedTeamIds: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/private-spaces-settings" $qp)
  let body = {privateSpacesAutoCreationEnabled: $privateSpacesAutoCreationEnabled, defaultOperationsLimit: $defaultOperationsLimit, bulkUpdateExistingLimits: $bulkUpdateExistingLimits, addAdminsAsObservers: $addAdminsAsObservers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check team permission within organization
#
# GET /organizations/{organizationId}/check-team-permission
export def "organizations-check-team-permission get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamPermission: string # The name of the team permission to check. This should be a valid company/team permission name (e.g., 'scenario add', 'scenario view', 'team view', 'connection add').  (e.g. scenario add)
]: nothing -> record<hasPermission: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamPermission" $teamPermission "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/check-team-permission" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List of child organizations
#
# GET /organizations/{organizationId}/managed-organizations
export def "organizations-managed-organizations get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<managedOrganizations: table<organizationId: int, organizationName: string, operationsAllocated: int, countryId: int, timezoneId: int, zoneId: int, zoneDomain: string, zoneName: string>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/managed-organizations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create child organization
#
# POST /organizations/{organizationId}/managed-organizations
export def "organizations-managed-organizations post" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userEmail: string # format: email
  --userName: string
  --organizationName: string
  --regionId: int
  --countryId: int
  --operations: int
]: any -> record<userId: int, userEmail: string, userName: string, userLanguage: string, userExisted: int, childOrganizationId: int, newParentOperations: int, domain: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/managed-organizations")
  let body = {userEmail: $userEmail, userName: $userName, organizationName: $organizationName, regionId: $regionId, countryId: $countryId, operations: $operations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List of child organizations consumption
#
# GET /organizations/{organizationId}/managed-organizations-consumption
export def "organizations-managed-organizations-consumption get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<managedOrganizationsConsumption: table<organizationId: int, centicreditsConsumed: string, centicreditsExtra: string, operationsConsumed: float, operationsExtra: float, transferConsumed: float, transferExtra: float, lastReset: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/managed-organizations-consumption")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update allocation of a child organization operations
#
# PATCH /organizations/{organizationId}/managed-organizations/{childOrganizationId}
export def "organizations-managed-organizations patch" [
  organizationId: int
  childOrganizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --operations: int
]: any -> record<newParentOperations: int, newChildOperations: int, operationsDiff: int, limitIncreased: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/managed-organizations/($childOrganizationId)")
  let body = {operations: $operations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Call RPC
#
# POST /rpcs/{appName}/{appVersion}/{rpcName}
# --schema item shape: {name?: string, type?: string, required?: bool}
export def "rpcs post" [
  appName: string
  appVersion: string
  rpcName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --imt-remote-formula: int # e.g. 1
  --imt-ignore-required: string # e.g. yes
  --imt-validate-schema: string # e.g. yes
  --data: record
  --schema: list # item shape: {name?: string, type?: string, required?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rpcs/($appName)/($appVersion)/($rpcName)")
  let body = {data: $data, schema: $schema} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"imt-remote-formula": $imt_remote_formula, "imt-ignore-required": $imt_ignore_required, "imt-validate-schema": $imt_validate_schema} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Process action
#
# OPTIONS /rpcs/{appName}/{appVersion}/{rpcName}
export def "rpcs options" [
  appName: string
  appVersion: string
  rpcName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --imt-remote-formula: int # e.g. 1
  --imt-ignore-required: string # e.g. yes
  --imt-validate-schema: string # e.g. yes
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rpcs/($appName)/($appVersion)/($rpcName)")
  let extra_headers = {"imt-remote-formula": $imt_remote_formula, "imt-ignore-required": $imt_ignore_required, "imt-validate-schema": $imt_validate_schema} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List scenarios
#
# GET /scenarios
@deprecated --flag islinked
export def "scenarios list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The unique ID of the team whose scenarios will be retrieved. If this parameter is set, the `organizationId` parameter must be skipped. For each request either `teamId` or `organizationId` must be defined. (e.g. 1)
  --organizationId: int # The unique ID of the organization whose scenarios will be retrieved. If this parameter is set, the `teamId` parameter must be skipped. For each request either `teamId` or `organizationId` must be defined. (e.g. 11)
  --id: list # The array of IDs of scenarios to retrieve. (e.g. [1, 2, 3])
  --folderId: int # The unique ID of the folder containing scenarios you want to retrieve. (e.g. 1)
  --isActive: string@bool-completer # Set this parameter to `true` to get only active scenarios in the response.  (e.g. true)
  --islinked: string@bool-completer # This parameter is deprecated. Use the `isActive` parameter to filter for active scenarios instead.  (DEPRECATED, e.g. true)
  --concept: string@bool-completer # If set to `true`, the response contains only scenario concepts. (e.g. true)
  --type: string@type-completer-3 # Limits the type of scenarios to be retrieved. (e.g. false)
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
  --pgoffset: int # The number of entities you want to skip before getting entities you want.
  --pglimit: int # The maximum number of entities you want to get in the response.
  --pgsortBy: string@pgsortBy-completer-8 # The value that will be used to sort returned entities by.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
]: nothing -> record<scenarios: table<id: int, name: string, teamId: int, hookId: int, devices: list, deviceId: int, deviceScope: string, description: string, folderId: int, isinvalid: bool, islinked: bool, isActive: bool, islocked: bool, isPaused: bool, usedPackages: list, lastEdit: string, scheduling: record, iswaiting: bool, dlqCount: int, createdByUser: record, updatedByUser: record, nextExec: string, created: string, scenarioVersion: int, moduleSequenceId: int, type: string>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "organizationId" $organizationId "scalar") (serialize-qp "id[]" $id "multi") (serialize-qp "folderId" $folderId "scalar") (serialize-qp "isActive" $isActive "scalar") (serialize-qp "islinked" $islinked "scalar") (serialize-qp "concept" $concept "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "cols[]" $cols "multi") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[limit]" $pglimit "scalar") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scenarios" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create scenario
#
# POST /scenarios
export def "scenarios post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
  --confirmed: string@bool-completer # If set to `true` this parameter confirms the scenario creation when the scenario contains the app that is used in the organization for the first time and needs installation. If the parameter is missing or it is set to `false` an error code is returned and the scenario is not created. (e.g. true)
  blueprint: string # The scenario blueprint. To save resources, the blueprint is sent as a string, not as an object.
  teamId: int # The unique ID of the team in which the scenario will be created.
  scheduling: string # The scenario scheduling details. To save resources, the scheduling details are sent as a string, not as an object.
  --folderId: int # The unique ID of the folder in which you want to store created scenario.
  --basedon: int # Defines if the scenario is created based on a template. The value is the template ID.
]: any -> record<scenario: record<id: int, name: string, teamId: int, hookId: int, devices: list<record>, deviceId: int, deviceScope: string, description: string, folderId: int, isinvalid: bool, islinked: bool, isActive: bool, islocked: bool, isPaused: bool, usedPackages: list<string>, lastEdit: string, scheduling: record<type: string, interval: int>, iswaiting: bool, dlqCount: int, createdByUser: record<id: int, name: string, email: string>, updatedByUser: record<id: int, name: string, email: string>, nextExec: string, created: string, scenarioVersion: int, moduleSequenceId: int, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols[]" $cols "multi") (serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scenarios" $qp)
  let body = {blueprint: $blueprint, teamId: $teamId, scheduling: $scheduling, folderId: $folderId, basedon: $basedon} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get scenario details
#
# GET /scenarios/{scenarioId}
export def "scenarios get" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
]: nothing -> record<scenario: record<id: int, name: string, teamId: int, hookId: int, devices: list<record>, deviceId: int, deviceScope: string, description: string, folderId: int, isinvalid: bool, islinked: bool, isActive: bool, islocked: bool, isPaused: bool, usedPackages: list<string>, lastEdit: string, scheduling: record<type: string, interval: int>, iswaiting: bool, dlqCount: int, createdByUser: record<id: int, name: string, email: string>, updatedByUser: record<id: int, name: string, email: string>, nextExec: string, created: string, scenarioVersion: int, moduleSequenceId: int, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/($scenarioId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update scenario
#
# PATCH /scenarios/{scenarioId}
export def "scenarios patch" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
  --confirmed: string@bool-completer # If set to `true` this parameter confirms the scenario update when the scenario contains the app that is used in the organization for the first time and needs installation. If the parameter is missing or it is set to `false` an error code is returned and the scenario is not updated. (e.g. true)
  --blueprint: string # The scenario blueprint. To save resources, the blueprint is sent as a string, not as an object.
  --scheduling: string # The scenario scheduling details. To save resources, the scheduling details are sent as a string, not as an object.
  --folderId: int # The unique ID of the folder in which you want to store created scenario.
  --name: string # A new name of the scenario. The name does not need to be unique.
]: any -> record<scenario: record<id: int, name: string, teamId: int, hookId: int, devices: list<record>, deviceId: int, deviceScope: string, description: string, folderId: int, isinvalid: bool, islinked: bool, isActive: bool, islocked: bool, isPaused: bool, usedPackages: list<string>, lastEdit: string, scheduling: record<type: string, interval: int>, iswaiting: bool, dlqCount: int, createdByUser: record<id: int, name: string, email: string>, updatedByUser: record<id: int, name: string, email: string>, nextExec: string, created: string, scenarioVersion: int, moduleSequenceId: int, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols[]" $cols "multi") (serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/($scenarioId)" $qp)
  let body = {blueprint: $blueprint, scheduling: $scheduling, folderId: $folderId, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete scenario
#
# DELETE /scenarios/{scenarioId}
export def "scenarios delete" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<scenario: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get trigger details
#
# GET /scenarios/{scenarioId}/triggers
export def "scenarios-triggers get" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, udid: string, scope: string, queueCount: int, queueLimit: int, typeName: string, type: string, url: string, flags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/triggers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Clone scenario
#
# POST /scenarios/{scenarioId}/clone
export def "scenarios-clone post" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int # The ID of the organization. (e.g. 11)
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
  --confirmed: string@bool-completer # If the scenario contains a custom app or a custom function, that is not available in the team, you have to set the `confirmed` parameter to `true` to clone the scenario. Otherwise you get an error and the scenario is not cloned.
  --notAnalyze: string@bool-completer # If you are cloning a scenario to a different team, you have to map the scenario entities (connections, data stores, webhooks, ...) from the original to the clone. If you cannot map all of the scenario entities, set the `notAnalyze` parameter to `true` to suppress the scenario blueprint analysis.
  name: string # The name for the scenario clone. The maximum length of the name is 120 characters.
  teamId: int # The ID of the team to which you want to clone the scenario.
  --account: record # Specify pairs of original and clone connection IDs to map connections to the cloned scenario.
  --key: record # Specify pairs of original and clone key IDs to map keys to the cloned scenario.
  --hook: record # Specify pairs of original and clone hook IDs to map webhooks to the cloned scenario.
  --device: record # Specify pairs of original and clone device IDs to map devices to the cloned scenario.
  --udt: record # Specify pairs of original and clone data structure IDs to map data structures to the cloned scenario.
  --datastore: record # Specify pairs of original and clone data store IDs to map data stores to the cloned scenario.
  --states: string@bool-completer # Set to `true` to clone also states of the scenario modules, for example last scenario trigger execution. Setting to `false` resets the state information of the scenario modules in the scenario clone.
]: any -> record<scenario: record<id: int, name: string, teamId: int, hookId: int, devices: list<record>, deviceId: int, deviceScope: string, description: string, folderId: int, isinvalid: bool, islinked: bool, isActive: bool, islocked: bool, isPaused: bool, usedPackages: list<string>, lastEdit: string, scheduling: record<type: string, interval: int>, iswaiting: bool, dlqCount: int, createdByUser: record<id: int, name: string, email: string>, updatedByUser: record<id: int, name: string, email: string>, nextExec: string, created: string, scenarioVersion: int, moduleSequenceId: int, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar") (serialize-qp "cols[]" $cols "multi") (serialize-qp "confirmed" $confirmed "scalar") (serialize-qp "notAnalyze" $notAnalyze "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/($scenarioId)/clone" $qp)
  let body = {name: $name, teamId: $teamId, account: $account, key: $key, hook: $hook, device: $device, udt: $udt, datastore: $datastore, states: $states} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set module data
#
# PUT /scenarios/{scenarioId}/data
export def "scenarios-data put" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<updated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/data")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check module data
#
# GET /scenarios/{scenarioId}/data/{moduleId}
export def "scenarios-data get" [
  scenarioId: int
  moduleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<exists: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/data/($moduleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Activate scenario
#
# POST /scenarios/{scenarioId}/start
export def "scenarios-start post" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<scenario: record<id: int, isActive: bool, islinked: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deactivate scenario
#
# POST /scenarios/{scenarioId}/stop
export def "scenarios-stop post" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<scenario: record<id: int, isActive: bool, islinked: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Run a scenario
#
# POST /scenarios/{scenarioId}/run
export def "scenarios-run post" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # If your scenario has inputs specify the input parameters and values in the `data` object.
  --responsive: string@bool-completer # If set to `true` the Make API waits until the scenario finishes. The response contains the scenario `status` and `executionId`. If the scenario execution takes longer than 40 seconds, the API call returns the time out error, but the scenario is still executed.  If set to `false` the API call returns immediately without waiting. The response contains only the `executionId`. (default: false)
  --callbackUrl: string # Url that will be called once the scenario execution finishes. If the run is responsive and finishes within 40 seconds, the url is not called since the result is present in the response.   The `callbackUrl` will be called using a `POST` request with the following body:  {  "executionId": `executionId`,  "statusUrl": "url to retrieve execution status and outputs via GET"  }  
]: any -> record<executionId: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/run")
  let body = {data: $data, responsive: $responsive, callbackUrl: $callbackUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replay a scenario execution
#
# POST /scenarios/{scenarioId}/replay
export def "scenarios-replay post" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --executionIds: list # An array of executionIds. Currently only the first one will be replayed.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/replay")
  let body = {executionIds: $executionIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get replayable executions for scenarioId
#
# GET /scenarios/replayable-executions/{scenarioId}
export def "scenarios-replayable-executions get" [
  scenarioId: int
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
  let full_url = (build-url $base $"/scenarios/replayable-executions/($scenarioId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Publish scenario
#
# POST /scenarios/{scenarioId}/publish
export def "scenarios-publish post" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<scenario: record<id: int>, scenarioVersion: record<scenarioId: int, version: int, draft: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/publish")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get scenario interface
#
# GET /scenarios/{scenarioId}/interface
export def "scenarios-interface get" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<interface: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/interface")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update scenario interface
#
# PATCH /scenarios/{scenarioId}/interface
export def "scenarios-interface patch" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --interface: record # Contains the `input` array with specification of the scenario input parameters.
]: any -> record<interface: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/interface")
  let body = {interface: $interface} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get scenario usage
#
# GET /scenarios/{scenarioId}/usage
export def "scenarios-usage get" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationTimezone: string@bool-completer # When set to `true`, the endpoint will calculate and return usage data based on the organization's timezone instead of the user's local timezone. (e.g. true)
]: nothing -> record<data: table<date: string, operations: int, dataTransfer: int, centicredits: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationTimezone" $organizationTimezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/($scenarioId)/usage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a scenario recovery snapshot
#
# GET /scenarios/{scenarioId}/recovery
export def "scenarios-recovery get" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The ID of the team. Used for team-scoped draft isolation. (e.g. 11)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/($scenarioId)/recovery" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Save a scenario recovery snapshot
#
# PUT /scenarios/{scenarioId}/recovery
export def "scenarios-recovery put" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The ID of the team. Used for team-scoped draft isolation. (e.g. 11)
  blueprint: record # The scenario blueprint to save as a scenario recovery snapshot
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/($scenarioId)/recovery" $qp)
  let body = {blueprint: $blueprint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Discard a scenario recovery snapshot
#
# DELETE /scenarios/{scenarioId}/recovery
export def "scenarios-recovery delete" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The ID of the team. (e.g. 11)
]: nothing -> record<scenarioId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/($scenarioId)/recovery" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cross-scenario execution feed (Pointee integration, undocumented)
#
# GET /scenarios/logs
export def "scenarios-logs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # ISO8601 UTC timestamp. The server returns only executions whose completion time is **strictly greater than** this value. Store `max(timestamp)` from the last response as the next `since` cursor.  (format: date-time, e.g. 2026-05-25T10:00:00Z)
  --until: string # ISO8601 UTC timestamp upper bound (inclusive). Defaults to the current server time when omitted.  (format: date-time, e.g. 2026-05-25T11:00:00Z)
  --pglimit: int # Maximum number of execution summaries to return. Capped at 200. (default: 50)
]: nothing -> record<scenarioLogs: table<imtId: string, id: string, scenarioId: int, organizationId: int, teamId: int, timestamp: string, status: int, duration: int, operations: int, centicredits: int, transfer: int, eventType: string, type: string, instant: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scenarios/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List scenario logs
#
# GET /scenarios/{scenarioId}/logs
export def "scenarios-logs get-by-scenarioId" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: int # The timestamp in milliseconds that defines the starting point of time from which the logs should be retrieved. Older logs will not be returned. (e.g. 1632395547)
  --qp-to: int # The timestamp in milliseconds that defines the ending point of time to which the logs should be retrieved. Newer logs will not be returned. (e.g. 1632395548)
  --status: int@status-completer-1 # Filters logs by the execution status. `1` is for success, `2` is for warning, and `3` is for error. (e.g. 2)
  --durationFrom: int # Filters logs to only include executions with a duration greater than or equal to this value (in milliseconds). (e.g. 1000)
  --durationTo: int # Filters logs to only include executions with a duration less than or equal to this value (in milliseconds). (e.g. 5000)
  --operationsFrom: int # Filters logs to only include executions with an operations count greater than or equal to this value. (e.g. 0)
  --operationsTo: int # Filters logs to only include executions with an operations count less than or equal to this value. (e.g. 100)
  --transferFrom: int # Filters logs to only include executions with a data transfer greater than or equal to this value (in bytes). (e.g. 0)
  --transferTo: int # Filters logs to only include executions with a data transfer less than or equal to this value (in bytes). (e.g. 10000)
  --executionName: string # Filters logs by the execution name (partial match). (e.g. My run)
  --creditsFrom: int # Filters logs to only include executions with credits greater than or equal to this value (in centicredits). (e.g. 0)
  --creditsTo: int # Filters logs to only include executions with credits less than or equal to this value (in centicredits). (e.g. 1000)
  --showCheckRuns: string@bool-completer # If set to `true`, this parameter specifies that check runs should be hidden in the returned results. Check runs concern scenarios starting with a trigger in cases when the trigger does not find anything new. (e.g. true)
  --pgoffset: int # The number of entities you want to skip before getting entities you want.
  --pglimit: int # The maximum number of entities you want to get in the response.
  --pgshowLast: string@bool-completer # Include records with `last` value in the result set. Just in case of the `last` based paging. (e.g. true)
  --pglast: int # The last retrieved key. In response, you get only entries that follow after the key. (e.g. 10)
  --pgsortBy: string # The value that will be used to sort returned entities by.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
]: nothing -> record<scenarioLogs: table<imtId: string, duration: int, operations: int, transfer: int, centicredits: any, organizationId: int, teamId: int, id: int, type: string, authorId: int, authorName: string, instant: bool, timestamp: string, status: int>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "durationFrom" $durationFrom "scalar") (serialize-qp "durationTo" $durationTo "scalar") (serialize-qp "operationsFrom" $operationsFrom "scalar") (serialize-qp "operationsTo" $operationsTo "scalar") (serialize-qp "transferFrom" $transferFrom "scalar") (serialize-qp "transferTo" $transferTo "scalar") (serialize-qp "executionName" $executionName "scalar") (serialize-qp "creditsFrom" $creditsFrom "scalar") (serialize-qp "creditsTo" $creditsTo "scalar") (serialize-qp "showCheckRuns" $showCheckRuns "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[limit]" $pglimit "scalar") (serialize-qp "pg[showLast]" $pgshowLast "scalar") (serialize-qp "pg[last]" $pglast "scalar") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/($scenarioId)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get execution log
#
# GET /scenarios/{scenarioId}/logs/{executionId}
export def "scenarios-logs get-by-scenarioId-executionId" [
  scenarioId: int
  executionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<scenarioLog: record<imtId: string, duration: int, operations: int, transfer: int, centicredits: any, organizationId: int, teamId: int, id: int, type: string, authorId: int, authorName: string, instant: bool, timestamp: string, status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/logs/($executionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get execution detail
#
# GET /scenarios/{scenarioId}/logs/{executionId}/p
export def "scenarios-logs-p get" [
  scenarioId: int
  executionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Comma-separated list of optional data sections to include in the response. Supported values: `blueprint`, `events`, `bundles`. Unknown values are silently ignored.  (e.g. blueprint,events,bundles)
]: nothing -> record<id: string, scenarioId: int, timestamp: string, duration: int, status: int, operations: int, centicredits: int, blueprint: record<modules: list<record>>, events: table<kind: string, moduleId: int, at: string, status: string>, bundles: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/($scenarioId)/logs/($executionId)/p" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get scenario execution details
#
# GET /scenarios/{scenarioId}/executions/{executionId}
export def "scenarios-executions get" [
  scenarioId: int
  executionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, outputs: record, error: record<name: string, message: string, causeModule: record<name: string, appName: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/executions/($executionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop scenario execution
#
# POST /scenarios/{scenarioId}/executions/{executionId}/stop
export def "scenarios-executions-stop post" [
  scenarioId: int
  executionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: string@bool-completer # If set to `true`, the execution is terminated immediately. If set to `false` or omitted, the execution stops after the current module finishes. (default: false)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/executions/($executionId)/stop")
  let body = {force: $force} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Consumptions by Module
#
# POST /scenarios/modules/consumptions
export def "scenarios-modules-consumptions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int # e.g. 30
  --days: int # Days to summarize retrospectively. Default 1, must be between 1 and 30. (e.g. 1)
  --scenarioIds: list
]: any -> record<scenarios: table<scenarioId: int, modules: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar") (serialize-qp "days" $days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scenarios/modules/consumptions" $qp)
  let body = {scenarioIds: $scenarioIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Operations by Module
#
# GET /scenarios/{scenarioId}/modules/operations
# DEPRECATED
@deprecated
export def "scenarios-modules-operations get" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --days: int # Days to summarize retrospectively. Default 1, must be between 1 and 30. (e.g. 1)
]: nothing -> record<operations: table<moduleId: int, total: int, warnings: int, errors: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "days" $days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/($scenarioId)/modules/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List module logs
#
# GET /scenarios/{scenarioId}/modules/{moduleId}/logs
export def "scenarios-modules-logs get" [
  scenarioId: int
  moduleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pgoffset: int # The number of entities you want to skip before getting entities you want.
  --pglimit: int # The maximum number of entities you want to get in the response.
  --pgshowLast: string@bool-completer # Include records with `last` value in the result set. Just in case of the `last` based paging. (e.g. true)
  --pglast: int # The last retrieved key. In response, you get only entries that follow after the key. (e.g. 10)
  --pgsortBy: string # The value that will be used to sort returned entities by.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
]: nothing -> record<moduleLogs: table<imtId: string, executionId: string, organizationId: int, teamId: int, scenarioId: int, timestamp: string, status: int, bundles: int, size: int, warning: record, error: record>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[limit]" $pglimit "scalar") (serialize-qp "pg[showLast]" $pgshowLast "scalar") (serialize-qp "pg[last]" $pglast "scalar") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/($scenarioId)/modules/($moduleId)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List of scenario notes
#
# GET /scenarios/{scenarioId}/notes
export def "scenarios-notes list" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The unique ID of the team whose scenarios folders will be retrieved. (e.g. 1)
  --organizationId: int # e.g. 11
]: nothing -> record<notes: table<id: int, scenarioId: int, moduleIds: list, metadata: record, content: string, created: string, updated: string, scenariosTotal: int, isFilterNote: bool, createdByUser: record, updatedByUser: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "organizationId" $organizationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/($scenarioId)/notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create scenario note
#
# POST /scenarios/{scenarioId}/notes
export def "scenarios-notes post" [
  scenarioId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --moduleIds: list
  --metadata: record
  --content: string
  --isFilterNote: string@bool-completer
]: any -> record<note: record<id: int, scenarioId: int, moduleIds: list<int>, metadata: record, content: string, created: string, updated: string, scenariosTotal: int, isFilterNote: bool, createdByUser: record, updatedByUser: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/notes")
  let body = {moduleIds: $moduleIds, metadata: $metadata, content: $content, isFilterNote: $isFilterNote} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get scenario note details
#
# GET /scenarios/{scenarioId}/notes/{noteId}
export def "scenarios-notes get" [
  scenarioId: int
  noteId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The unique ID of the team whose scenarios folders will be retrieved. (e.g. 1)
  --organizationId: int # e.g. 11
]: nothing -> record<note: record<id: int, scenarioId: int, moduleIds: list<int>, metadata: record, content: string, created: string, updated: string, scenariosTotal: int, isFilterNote: bool, createdByUser: record, updatedByUser: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "organizationId" $organizationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/($scenarioId)/notes/($noteId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update scenario note
#
# PATCH /scenarios/{scenarioId}/notes/{noteId}
export def "scenarios-notes patch" [
  scenarioId: int
  noteId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The unique ID of the team whose scenarios folders will be retrieved. (e.g. 1)
  --organizationId: int # e.g. 11
  --moduleIds: list
  --metadata: record
  --content: string
  --isFilterNote: string@bool-completer
]: any -> record<note: record<id: int, scenarioId: int, moduleIds: list<int>, metadata: record, content: string, created: string, updated: string, scenariosTotal: int, isFilterNote: bool, createdByUser: record, updatedByUser: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "organizationId" $organizationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/($scenarioId)/notes/($noteId)" $qp)
  let body = {moduleIds: $moduleIds, metadata: $metadata, content: $content, isFilterNote: $isFilterNote} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete scenario note
#
# DELETE /scenarios/{scenarioId}/notes/{noteId}
export def "scenarios-notes delete" [
  scenarioId: int
  noteId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The unique ID of the team whose scenarios folders will be retrieved. (e.g. 1)
  --organizationId: int # e.g. 11
]: nothing -> record<id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "organizationId" $organizationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/($scenarioId)/notes/($noteId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get scenario consumption overview
#
# GET /scenarios/{scenarioId}/consumption-overview
export def "scenarios-consumption-overview get" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: int # The timestamp in milliseconds that defines the starting point of time from which the logs should be retrieved. Older logs will not be returned. (e.g. 1632395547)
  --qp-to: int # The timestamp in milliseconds that defines the ending point of time to which the logs should be retrieved. Newer logs will not be returned. (e.g. 1632395548)
  --showCheckRuns: string@bool-completer # If set to `true`, this parameter specifies that check runs should be hidden in the returned results. Check runs concern scenarios starting with a trigger in cases when the trigger does not find anything new. (e.g. true)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "showCheckRuns" $showCheckRuns "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/($scenarioId)/consumption-overview" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get scenario blueprint
#
# GET /scenarios/{scenarioId}/blueprint
export def "scenarios-blueprint get" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blueprintId: int # The unique ID of the blueprint version. It can be retrieved from the [Get blueprint versions](/api-reference/scenarios/blueprints/get--scenarios--scenarioid--blueprints.md) endpoint. This parameter can be useful when you want to retrieve the older version of the blueprint. (e.g. 12)
  --draft: string@bool-completer # If this parameter is set to `true`, the draft version of the scenario blueprint will be retrieved. If set to `false`, the live version of the blueprint will be retrieved. In case that the `blueprintId` parameter is set to the query as well, this parameter is ignored. (e.g. false)
]: nothing -> record<code: string, response: record<blueprint: record<flow: list, name: string, metadata: record>, scheduling: record<type: string, interval: int, date: string, between: list, time: string, days: list, months: list, restrict: list, maximum_runs_per_minute: int>, idSequence: int, created: string, last_edit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blueprintId" $blueprintId "scalar") (serialize-qp "draft" $draft "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/($scenarioId)/blueprint" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get blueprint versions
#
# GET /scenarios/{scenarioId}/blueprints
export def "scenarios-blueprints get" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<scenariosBlueprints: table<created: string, version: int, scenarioId: int, draft: bool, versionDescription: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/blueprints")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List buildtime variables
#
# GET /scenarios/{scenarioId}/build-variables
export def "scenarios-build-variables get" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<variables: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/build-variables")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add new buildtime variables to scenario metadata
#
# POST /scenarios/{scenarioId}/build-variables
# --input item shape: {name?: string, value?: string}
export def "scenarios-build-variables post" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --input: list # item shape: {name?: string, value?: string}
]: any -> record<ok: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/build-variables")
  let body = {input: $input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update buildtime variables in scenario metadata
#
# PUT /scenarios/{scenarioId}/build-variables
# --input item shape: {name?: string, value?: string}
export def "scenarios-build-variables put" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --input: list # item shape: {name?: string, value?: string}
]: any -> record<ok: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/build-variables")
  let body = {input: $input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete buildtime variable
#
# DELETE /scenarios/{scenarioId}/build-variables
export def "scenarios-build-variables delete" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --value: string # The value of the buildtime variable (e.g. PAC_123455551)
]: nothing -> record<ok: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/($scenarioId)/build-variables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List scenario consumptions
#
# GET /scenarios/consumptions
export def "scenarios-consumptions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The unique ID of the team whose scenarios folders will be retrieved. (e.g. 1)
  --organizationId: int # The ID of the organization. (e.g. 11)
]: nothing -> record<scenarioConsumptions: table<scenarioId: int, operations: int, transfer: int, centicredits: any>, lastReset: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "organizationId" $organizationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scenarios/consumptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create tool
#
# POST /scenarios/tools
export def "scenarios-tools post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
  name: string # The name of the tool.
  description: string # A description of the tool.
  --inputs: list
  teamId: int # The unique ID of the team in which the scenario will be created.
  --body-module: record # The module of the tool. The module is a JSON object that contains the module ID, version, mapper, parameters, and metadata.
]: any -> record<tool: record<id: int, name: string, description: string, inputs: list<any>, teamId: int, moduleType: string, module: record<module: string, version: int, mapper: record, parameters: record, metadata: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/scenarios/tools" $qp)
  let body = {name: $name, description: $description, inputs: $inputs, teamId: $teamId, module: $body_module} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get tool configuration
#
# GET /scenarios/tools/{scenarioId}
export def "scenarios-tools get" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tool: record<id: int, name: string, description: string, inputs: list<any>, teamId: int, moduleType: string, module: record<module: string, version: int, mapper: record, parameters: record, metadata: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/tools/($scenarioId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update tool configuration
#
# PATCH /scenarios/tools/{scenarioId}
export def "scenarios-tools patch" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
  --name: string # The name of the tool.
  --description: string # A description of the tool.
  --inputs: list
  --body-module: record # The module of the tool. The module is a JSON object that contains the module ID, version, mapper, parameters, and metadata.
]: any -> record<tool: record<id: int, name: string, description: string, inputs: list<any>, teamId: int, moduleType: string, module: record<module: string, version: int, mapper: record, parameters: record, metadata: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/tools/($scenarioId)" $qp)
  let body = {name: $name, description: $description, inputs: $inputs, module: $body_module} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List AI agent scenarios
#
# GET /scenarios/ai-agents
export def "scenarios-ai-agents get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The unique ID of the team whose scenarios folders will be retrieved. (e.g. 1)
  --pgoffset: int # The number of entities you want to skip before getting entities you want.
  --pglimit: int # The maximum number of entities you want to get in the response.
]: nothing -> record<scenarios: table<id: int, name: string, description: string, isActive: bool, teamId: int, created: string, lastEdit: string, scheduling: record, usedPackages: list, agentCount: int, createdByUser: record>, pg: record<limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scenarios/ai-agents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List scenario folders
#
# GET /scenarios-folders
export def "scenarios-folders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # Unique ID of the Team. (e.g. 1)
  --cols: list # Specifies the group of values to return. For example, you may want to receive in response only the names and IDs of folders.
]: nothing -> record<scenariosFolders: table<id: int, name: string, scenariosTotal: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/scenarios-folders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create scenario folder
#
# POST /scenarios-folders
export def "scenarios-folders post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the scenario folder. The name must be at most 100 characters long and does not need to be unique.
  teamId: int # The unique ID of the team in which the scenario folder will be created.
]: any -> record<scenarioFolder: record<id: int, name: string, scenariosTotal: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scenarios-folders")
  let body = {name: $name, teamId: $teamId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update scenario folder
#
# PATCH /scenarios-folders/{folderId}
export def "scenarios-folders patch" [
  folderId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies the group of values to return. For example, you may want to receive in response only the names and IDs of folders.
  --name: string # The name for the updated scenario folder. The name must be at most 100 characters long and does not need to be unique.
]: any -> record<scenarioFolder: record<id: int, name: string, scenariosTotal: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios-folders/($folderId)" $qp)
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete scenario folder
#
# DELETE /scenarios-folders/{folderId}
export def "scenarios-folders delete" [
  folderId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<scenarioFolder: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios-folders/($folderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get custom properties data
#
# GET /scenarios/{scenarioId}/custom-properties
export def "scenarios-custom-properties get" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<customProperties: record, scenarioId: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/custom-properties")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fill in custom properties data
#
# POST /scenarios/{scenarioId}/custom-properties
export def "scenarios-custom-properties post" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<customProperties: record, scenarioId: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/custom-properties")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update custom properties data
#
# PATCH /scenarios/{scenarioId}/custom-properties
export def "scenarios-custom-properties patch" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<customProperties: record, scenarioId: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/custom-properties")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set custom properties
#
# PUT /scenarios/{scenarioId}/custom-properties
export def "scenarios-custom-properties put" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<customProperties: record, scenarioId: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios/($scenarioId)/custom-properties")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete custom properties data
#
# DELETE /scenarios/{scenarioId}/custom-properties
export def "scenarios-custom-properties delete" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # e.g. true
]: nothing -> record<ok: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scenarios/($scenarioId)/custom-properties" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List shared scenarios
#
# GET /scenarios-shared
# operationId: getScenarioSharesList
export def "scenarios-shared get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int # The ID of the organization. Mutually exclusive with `teamId`. (e.g. 123)
  --teamId: int # The ID of the team. Mutually exclusive with `organizationId`. (e.g. 456)
  --folderId: int # Filter results by folder ID. (e.g. 789)
  --title: string # Filter results by shared scenario title (case-insensitive partial match). (e.g. My Workflow)
  --scenarioName: string # Filter results by the original scenario name (case-insensitive partial match). (e.g. Data Processing)
  --scenarioIds: list # Filter results by multiple scenario IDs. Accepts an array of scenario IDs to match. (e.g. [123, 456, 789])
  --pglimit: int # Number of results per page. (default: 20, e.g. 20)
  --pgoffset: int # Number of results to skip (for pagination). (default: 0, e.g. 0)
  --pgsortBy: string@pgsortBy-completer-9 # Column to sort results by. (default: id, e.g. title)
  --pgsortDir: string@pgsortDir-completer # Sort direction (ascending or descending). (default: desc, e.g. asc)
  --pgreturnTotalCount: string@bool-completer # Whether to return the total count of matching records. (default: false, e.g. false)
]: nothing -> record<scenariosShared: table<id: string, scenarioId: int, title: string, scenarioName: string, descriptionShort: string, scenarioUsedPackages: list, shareUrl: string, createdAt: string, updated: string>, pg: record<limit: int, offset: int, sortBy: string, sortDir: string, returnTotalCount: bool, totalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "folderId" $folderId "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "scenarioName" $scenarioName "scalar") (serialize-qp "scenarioIds" $scenarioIds "multi") (serialize-qp "pg[limit]" $pglimit "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[returnTotalCount]" $pgreturnTotalCount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scenarios-shared" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List shared scenarios for scenario
#
# GET /scenarios-shared/{scenarioId}
export def "scenarios-shared get-by-scenarioId" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<scenariosShared: table<id: string, scenarioId: int, title: string, titleOriginal: string, descriptionShort: string, descriptionLong: string, thumbnailUrl: string, shareUrl: string, shareUrlCardinal: string, isEnabled: bool, createdAt: string, updated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios-shared/($scenarioId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create scenario share
#
# POST /scenarios-shared/{scenarioId}
export def "scenarios-shared post" [
  scenarioId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string
  --descriptionShort: string # nullable
  --descriptionLong: string # nullable
  --isEnabled: string@bool-completer # default: false
]: any -> record<scenarioShared: record<id: string, scenarioId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios-shared/($scenarioId)")
  let body = {title: $title, descriptionShort: $descriptionShort, descriptionLong: $descriptionLong, isEnabled: $isEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get shared scenario
#
# GET /scenarios-shared/{scenarioId}/{sharedScenarioId}
export def "scenarios-shared get-by-scenarioId-sharedScenarioId" [
  scenarioId: int
  sharedScenarioId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<scenarioShared: record<id: string, scenarioId: int, authorId: int, isEnabled: bool, origin: string, titleOriginal: string, title: string, descriptionShort: string, descriptionLong: string, thumbnailUrl: string, shareUrl: string, shareUrlCardinal: string, createdAt: string, updated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios-shared/($scenarioId)/($sharedScenarioId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update shared scenario
#
# PATCH /scenarios-shared/{scenarioId}/{sharedScenarioId}
export def "scenarios-shared patch" [
  scenarioId: int
  sharedScenarioId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string
  --descriptionShort: string # nullable
  --descriptionLong: string # nullable
  --isEnabled: string@bool-completer
]: any -> record<scenarioShared: record<id: string, scenarioId: int, authorId: int, isEnabled: bool, origin: string, titleOriginal: string, title: string, descriptionShort: string, descriptionLong: string, thumbnailUrl: string, shareUrl: string, shareUrlCardinal: string, createdAt: string, updated: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios-shared/($scenarioId)/($sharedScenarioId)")
  let body = {title: $title, descriptionShort: $descriptionShort, descriptionLong: $descriptionLong, isEnabled: $isEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete shared scenario
#
# DELETE /scenarios-shared/{scenarioId}/{sharedScenarioId}
export def "scenarios-shared delete" [
  scenarioId: int
  sharedScenarioId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<scenarioShared: record<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scenarios-shared/($scenarioId)/($sharedScenarioId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Apps
#
# GET /sdk/apps
export def "sdk-apps get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opensource: string@bool-completer # If set to `true`, this parameter returns apps available to all users. If set to `false`, it retrieves the apps available to the authenticated user.
  --cols: list # Specifies the group of values to return. For example, you may want to retrieve only the names of the available apps. (e.g. name)
]: nothing -> record<apps: table<name: string, label: string, version: int, versionFull: string, beta: bool, description: string, theme: string, public: bool, approved: bool, in_review: bool, modules: list, opensource: bool, changes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opensource" $opensource "scalar") (serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/sdk/apps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create App
#
# POST /sdk/apps
# --app shape: {name?: string, label?: string, description?: string, version?: int, beta?: bool, theme?: string, language?: string, public?: bool, approved?: bool, global?: bool, countries?: list, created?: string, manifestVersion?: int}
export def "sdk-apps post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --app: record # shape: {name?: string, label?: string, description?: string, version?: int, beta?: bool, theme?: string, language?: string, public?: bool, approved?: bool, global?: bool, countries?: list, created?: string, manifestVersion?: int}
]: any -> record<app: record<name: string, label: string, version: int, theme: string, public: bool, approved: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sdk/apps")
  let body = {app: $app} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get App
#
# GET /sdk/apps/{SDK_appName}/{SDK_appVersion}
export def "sdk-apps get-by-SDK_appName-SDK_appVersion" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies the group of values to return.
]: nothing -> record<app: record<name: string, label: string, description: string, version: int, beta: bool, theme: string, language: string, public: bool, approved: bool, global: bool, countries: list<any>, created: string, manifestVersion: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch App
#
# PATCH /sdk/apps/{SDK_appName}/{SDK_appVersion}
export def "sdk-apps patch" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<app: record<name: string, label: string, description: string, version: int, theme: string, public: bool, approved: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete App
#
# DELETE /sdk/apps/{SDK_appName}/{SDK_appVersion}
export def "sdk-apps delete" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<app: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Clone App
#
# POST /sdk/apps/{SDK_appName}/{SDK_appVersion}/clone
export def "sdk-apps-clone post" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --newName: string
  --newVersion: int
]: any -> record<app: record<name: string, label: string, description: string, version: int, beta: bool, theme: string, language: string, public: bool, approved: bool, global: bool, countries: list<any>, created: string, manifestVersion: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/clone")
  let body = {newName: $newName, newVersion: $newVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clone App Major Version
#
# POST /sdk/apps/{SDK_appName}/{SDK_appVersion}/clone-major
export def "sdk-apps-clone-major post" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<app: record<name: string, label: string, description: string, version: int, beta: bool, theme: string, language: string, public: bool, approved: bool, global: bool, countries: list<any>, created: string, manifestVersion: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/clone-major")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get App Review
#
# GET /sdk/apps/{SDK_appName}/{SDK_appVersion}/review
export def "sdk-apps-review get" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<review: record<contactName: string, contactEmail: string, reviewerName: string, reviewerEmail: string, codeStatus: string, testStatus: string, docsStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/review")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request Review
#
# POST /sdk/apps/{SDK_appName}/{SDK_appVersion}/review
export def "sdk-apps-review post" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --all: string@bool-completer # e.g. true
  --Content-Type: string # e.g. application/json
]: nothing -> record<requested: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/review" $qp)
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit App Review Form
#
# PUT /sdk/apps/{SDK_appName}/{SDK_appVersion}/review/form
export def "sdk-apps-review-form put" [
  SDK_appName: string
  SDK_appVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --testingScenarios: record
]: any -> record<form: record<testingScenarios: record<hohoho: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/review/form")
  let body = {testingScenarios: $testingScenarios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get App Events Log
#
# GET /sdk/apps/{SDK_appName}/{SDK_appVersion}/events-log
export def "sdk-apps-events-log get" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list
]: nothing -> record<events: table<id: int, appName: string, appVersion: int, message: string, detail: record, authorId: int, createdAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/events-log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get App Common
#
# GET /sdk/apps/{SDK_appName}/{SDK_appVersion}/common
export def "sdk-apps-common get" [
  SDK_appName: string
  SDK_appVersion: int
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
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/common")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set app common data
#
# PUT /sdk/apps/{SDK_appName}/{SDK_appVersion}/common
export def "sdk-apps-common put" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<changed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/common")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get App Docs
#
# GET /sdk/apps/{SDK_appName}/{SDK_appVersion}/readme
export def "sdk-apps-readme get" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --all: string@bool-completer # e.g. true
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/readme" $qp)
  let accept_val = "text/markdown"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set App Docs
#
# PUT /sdk/apps/{SDK_appName}/{SDK_appVersion}/readme
export def "sdk-apps-readme put" [
  SDK_appName: string
  SDK_appVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --all: string@bool-completer # e.g. true
  --Content-Type: string # e.g. text/markdown
  --body: record
]: any -> record<changed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/readme" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/markdown" $body
}

# Set App Base
#
# POST /sdk/apps/{SDK_appName}/{SDK_appVersion}/base
# --aws shape: {key?: string, secret?: string, session?: string, bucket?: string, sign_version?: any}
# --log shape: {sanitize?: list}
# --oauth shape: {consumer_key?: string, consumer_secret?: string, private_key?: string, token?: string, token_secret?: string, verifier?: string, signature_method?: any, transport_method?: any, body_hash?: any}
# --pagination shape: {mergeWithParent?: bool, url?: string, method?: any, headers?: record, qs?: record, body?: any, condition?: any}
# --response shape: {type?: any, valid?: any, limit?: any, error?: any, iterate?: any, temp?: record, output?: any, trigger?: record, data?: record, metadata?: record, uid?: any, oauth?: record, wrapper?: any, expires?: string}
export def "sdk-apps-base post" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # e.g. application/jsonc
  --body-url: string # Request URL
  --baseUrl: string # Base URL for endpoints starting with /
  --encodeUrl: string@bool-completer # This directive controls the encoding of URLs. It is on by default, so if you have any special characters in your URL, they will be automatically encoded. But there might be situations where you don't want your URL to be encoded automatically, or you want to control what parts of the URL are encoded. To do this, set this flag to false. (default: true)
  --method: any # This directive specifies the HTTP method that will be used to issue the request.
  --headers: record # This directive specifies headers that will be sent with the request.
  --qs: record # This directive specifies the query string to use when making the request.
  --ca: string # Custom Certificate Authority
  --body-body: any # This directive specifies the request body.
  --type: any
  --temp: record # The temp directive specifies an object, which can be used to create custom temporary variables. It also creates a temp variable in IML, through which you then access your variables. The temp collection is not persisted and will be lost after the module is done executing.
  --condition: any # This directive specifies whether to execute the request or not. (default: true)
  --aws: record # Helper directive, that will simplify generating AWS signatures. — shape: {key?: string, secret?: string, session?: string, bucket?: string, sign_version?: any}
  --gzip: string@bool-completer # Add an Accept-Encoding header to request compressed content encodings from the server (if not already present) and decode supported content encodings in the response. (default: false)
  --followRedirects: string@bool-completer # This directive specifies whether to follow GET HTTP 3xx responses as redirects or never. (default: true)
  --followAllRedirects: string@bool-completer # This directive specifies whether to follow non-GET HTTP 3xx responses as redirects or never. (default: true)
  --log: record # This directive specifies logging options for both the request and the response. — shape: {sanitize?: list}
  --oauth: record # Helper directive, that will simplify generating an OAuth1 Authorization headers. — shape: {consumer_key?: string, consumer_secret?: string, private_key?: string, token?: string, token_secret?: string, verifier?: string, signature_method?: any, transport_method?: any, body_hash?: any}
  --pagination: record # Directive to specify how to process paginated responses. — shape: {mergeWithParent?: bool, url?: string, method?: any, headers?: record, qs?: record, body?: any, condition?: any}
  --response: record # Response parsing configuration — shape: {type?: any, valid?: any, limit?: any, error?: any, iterate?: any, temp?: record, output?: any, trigger?: record, data?: record, metadata?: record, uid?: any, oauth?: record, wrapper?: any, expires?: string}
]: any -> record<change: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/base")
  let body = {url: $body_url, baseUrl: $baseUrl, encodeUrl: $encodeUrl, method: $method, headers: $headers, qs: $qs, ca: $ca, body: $body_body, type: $type, temp: $temp, condition: $condition, aws: $aws, gzip: $gzip, followRedirects: $followRedirects, followAllRedirects: $followAllRedirects, log: $log, oauth: $oauth, pagination: $pagination, response: $response} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Patch App Base
#
# PATCH /sdk/apps/{SDK_appName}/{SDK_appVersion}/base
# --aws shape: {key?: string, secret?: string, session?: string, bucket?: string, sign_version?: any}
# --log shape: {sanitize?: list}
# --oauth shape: {consumer_key?: string, consumer_secret?: string, private_key?: string, token?: string, token_secret?: string, verifier?: string, signature_method?: any, transport_method?: any, body_hash?: any}
# --pagination shape: {mergeWithParent?: bool, url?: string, method?: any, headers?: record, qs?: record, body?: any, condition?: any}
# --response shape: {type?: any, valid?: any, limit?: any, error?: any, iterate?: any, temp?: record, output?: any, trigger?: record, data?: record, metadata?: record, uid?: any, oauth?: record, wrapper?: any, expires?: string}
export def "sdk-apps-base patch" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # e.g. application/jsonc
  --body-url: string # Request URL
  --baseUrl: string # Base URL for endpoints starting with /
  --encodeUrl: string@bool-completer # This directive controls the encoding of URLs. It is on by default, so if you have any special characters in your URL, they will be automatically encoded. But there might be situations where you don't want your URL to be encoded automatically, or you want to control what parts of the URL are encoded. To do this, set this flag to false. (default: true)
  --method: any # This directive specifies the HTTP method that will be used to issue the request.
  --headers: record # This directive specifies headers that will be sent with the request.
  --qs: record # This directive specifies the query string to use when making the request.
  --ca: string # Custom Certificate Authority
  --body-body: any # This directive specifies the request body.
  --type: any
  --temp: record # The temp directive specifies an object, which can be used to create custom temporary variables. It also creates a temp variable in IML, through which you then access your variables. The temp collection is not persisted and will be lost after the module is done executing.
  --condition: any # This directive specifies whether to execute the request or not. (default: true)
  --aws: record # Helper directive, that will simplify generating AWS signatures. — shape: {key?: string, secret?: string, session?: string, bucket?: string, sign_version?: any}
  --gzip: string@bool-completer # Add an Accept-Encoding header to request compressed content encodings from the server (if not already present) and decode supported content encodings in the response. (default: false)
  --followRedirects: string@bool-completer # This directive specifies whether to follow GET HTTP 3xx responses as redirects or never. (default: true)
  --followAllRedirects: string@bool-completer # This directive specifies whether to follow non-GET HTTP 3xx responses as redirects or never. (default: true)
  --log: record # This directive specifies logging options for both the request and the response. — shape: {sanitize?: list}
  --oauth: record # Helper directive, that will simplify generating an OAuth1 Authorization headers. — shape: {consumer_key?: string, consumer_secret?: string, private_key?: string, token?: string, token_secret?: string, verifier?: string, signature_method?: any, transport_method?: any, body_hash?: any}
  --pagination: record # Directive to specify how to process paginated responses. — shape: {mergeWithParent?: bool, url?: string, method?: any, headers?: record, qs?: record, body?: any, condition?: any}
  --response: record # Response parsing configuration — shape: {type?: any, valid?: any, limit?: any, error?: any, iterate?: any, temp?: record, output?: any, trigger?: record, data?: record, metadata?: record, uid?: any, oauth?: record, wrapper?: any, expires?: string}
]: any -> record<change: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/base")
  let body = {url: $body_url, baseUrl: $baseUrl, encodeUrl: $encodeUrl, method: $method, headers: $headers, qs: $qs, ca: $ca, body: $body_body, type: $type, temp: $temp, condition: $condition, aws: $aws, gzip: $gzip, followRedirects: $followRedirects, followAllRedirects: $followAllRedirects, log: $log, oauth: $oauth, pagination: $pagination, response: $response} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set App Section
#
# PUT /sdk/apps/{SDK_appName}/{SDK_appVersion}/groups
export def "sdk-apps-groups put" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<change: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/groups")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set App Section
#
# PUT /sdk/apps/{SDK_appName}/{SDK_appVersion}/install
export def "sdk-apps-install put" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<change: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/install")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set App Visibility
#
# POST /sdk/apps/{SDK_appName}/{SDK_appVersion}/{SDK_appVisibility}
export def "sdk-apps post-by-SDK_appName-SDK_appVersion-SDK_appVisibility" [
  SDK_appName: string
  SDK_appVersion: int
  SDK_appVisibility: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<public: bool, inviteToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/($SDK_appVisibility)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set App Opensource
#
# POST /sdk/apps/{SDK_appName}/{SDK_appVersion}/opensource
export def "sdk-apps-opensource post" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # e.g. text/plain
  --body: record
]: any -> record<changed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/opensource")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set App ClosedSource
#
# POST /sdk/apps/{SDK_appName}/{SDK_appVersion}/closedsource
export def "sdk-apps-closedsource post" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<changed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/closedsource")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Change
#
# GET /sdk/apps/{SDK_appName}/{SDK_appVersion}/changes/{SDK_changeId}
export def "sdk-apps-changes get" [
  SDK_appName: string
  SDK_appVersion: int
  SDK_changeId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<change: record<id: int, group: string, code: string, oldValue: string, newValue: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/changes/($SDK_changeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Commit Changes
#
# POST /sdk/apps/{SDK_appName}/{SDK_appVersion}/commit
export def "sdk-apps-commit post" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # e.g. application/json
  --message: string
  --notify: string@bool-completer
  --changeIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/commit")
  let body = {message: $message, notify: $notify, changeIds: $changeIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rollback Changes
#
# POST /sdk/apps/{SDK_appName}/{SDK_appVersion}/rollback
export def "sdk-apps-rollback post" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # e.g. application/json
  --changeIds: list
]: any -> record<rolledBack: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/rollback")
  let body = {changeIds: $changeIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get App Logo
#
# GET /sdk/apps/{SDK_appName}/{SDK_appVersion}/icon/{SDK_appIconSize}
export def "sdk-apps-icon get" [
  SDK_appName: string
  SDK_appVersion: int
  SDK_appIconSize: int
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
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/icon/($SDK_appIconSize)")
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set App Logo
#
# PUT /sdk/apps/{SDK_appName}/{SDK_appVersion}/icon
export def "sdk-apps-icon put" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<changed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/icon")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "image/png" $body
}

# Uninstall App from Organization
#
# POST /sdk/apps/{SDK_appName}/{SDK_appVersion}/uninstall
export def "sdk-apps-uninstall post" [
  SDK_appName: string
  SDK_appVersion: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int
]: any -> table<name: string, label: string, appVersion: int, organizationId: int, installedAt: string, userId: string, theme: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/uninstall")
  let body = {organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# All verified and custom apps returned with theme color.
#
# GET /sdk/apps/themes
export def "sdk-apps-themes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --names: string # Names of apps to return divided by commas - for example ?names=test-app-6astv7,custom-app-0b5p1w.  The names parameter may contain maximum 500 values.
]: nothing -> record<apps: table<name: string, label: string, theme: string, isCompiled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "names" $names "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sdk/apps/themes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get App Invite
#
# GET /sdk/apps/invites/{SDK_appInviteToken}
export def "sdk-apps-invites get" [
  SDK_appInviteToken: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appInvite: record<name: string, label: string, theme: string, created: string, access: bool, manifestBasic: record<icon: string, name: string, label: string, theme: string, groups: list, public: bool, actions: list, version: string, searches: list, triggers: list, description: string, supportsAgent: bool>, language: string, installable: list<int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/invites/($SDK_appInviteToken)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept App Invite
#
# POST /sdk/apps/invites/{SDK_appInviteToken}
export def "sdk-apps-invites post" [
  SDK_appInviteToken: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationIds: list
]: any -> record<appInvite: record<name: string, label: string, theme: string, created: string, access: bool, manifestBasic: record<icon: string, name: string, label: string, theme: string, groups: list, public: bool, actions: list, version: string, searches: list, triggers: list, description: string, supportsAgent: bool>, language: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/invites/($SDK_appInviteToken)")
  let body = {organizationIds: $organizationIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Module
#
# POST /sdk/apps/{SDK_appName}/{SDK_appVersion}/modules
export def "sdk-apps-modules post-by-SDK_appName-SDK_appVersion" [
  SDK_appName: string
  SDK_appVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  typeId: int@typeId-completer # Module type id. Allowed values:  - 1 = TRIGGER (Trigger - polling) Use if you wish to watch for any changes in your app/service. Examples are Watch a New Book, which will be triggered whenever a new book has been added to the library.  - 4 = ACTION Use if the API endpoint returns a single response. Examples are Create a book, Delete a book or Get a Book.  - 9 = SEARCH Use if the API endpoint returns multiple items. An example is List Books that will find specific books according to search criteria.  - 10 = CONVERGER (Instant Trigger / webhook) Use if the API endpoint has a webhook available (dedicated or shared). Example is Watch a New Event.  - 11 = HITL (Responder) Use if you need to send a processed data back to a webhook.  - 12 = RETURNER (Universal) Use if you want to enable users to perform an arbitrary API call to the service. Examples are Make an API Call and Execute a GraphQL Query.  (default: 4)
  --label: string
  --description: string
  --moduleInitMode: string@moduleInitMode-completer # Module init mode:  * `blank` -  Creates a new blank module (code is empty).  * `example` - Creates a module from a `model` app (which contains the example codes).  * `module` - Creates module from existing user's module.  (default: blank)
  --moduleInitSource: string # Required when `moduleInitMode` is `module`. Specifies the name of the source module to clone.
  --connection: string # The name of the connection to use. (nullable)
  --webhook: string # The name of the webhook to use. (nullable)
  --crud: string # The CRUD operation type. (nullable)
]: any -> record<appModule: record<name: string, label: string, description: string, typeId: int, crud: string, connection: string, webhook: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/modules")
  let body = {name: $name, typeId: $typeId, label: $label, description: $description, moduleInitMode: $moduleInitMode, moduleInitSource: $moduleInitSource, connection: $connection, webhook: $webhook, crud: $crud} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List App Modules
#
# GET /sdk/apps/{SDK_appName}/{SDK_appVersion}/modules
export def "sdk-apps-modules get-by-SDK_appName-SDK_appVersion" [
  SDK_appName: string
  SDK_appVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appModules: table<name: string, label: string, description: string, typeId: int, public: bool, approved: bool, archived: bool, crud: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/modules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Module
#
# GET /sdk/apps/{SDK_appName}/{SDK_appVersion}/modules/{SDK_moduleName}
export def "sdk-apps-modules get-by-SDK_appName-SDK_appVersion-SDK_moduleName" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_moduleName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appModule: record<name: string, label: string, description: string, typeId: int, public: bool, approved: bool, archived: bool, crud: string, connection: string, altConnection: string, webhook: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/modules/($SDK_moduleName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch Module
#
# PATCH /sdk/apps/{SDK_appName}/{SDK_appVersion}/modules/{SDK_moduleName}
export def "sdk-apps-modules patch" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_moduleName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --label: string
  --description: string
  --connection: string
]: any -> record<appModule: record<name: string, label: string, description: string, typeId: int, crud: string, connection: string, altConnection: string, webhook: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/modules/($SDK_moduleName)")
  let body = {label: $label, description: $description, connection: $connection} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Module
#
# DELETE /sdk/apps/{SDK_appName}/{SDK_appVersion}/modules/{SDK_moduleName}
export def "sdk-apps-modules delete" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_moduleName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appModule: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/modules/($SDK_moduleName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Module Section
#
# PUT /sdk/apps/{SDK_appName}/{SDK_appVersion}/modules/{SDK_moduleName}/api
# --aws shape: {key?: string, secret?: string, session?: string, bucket?: string, sign_version?: any}
# --log shape: {sanitize?: list}
# --oauth shape: {consumer_key?: string, consumer_secret?: string, private_key?: string, token?: string, token_secret?: string, verifier?: string, signature_method?: any, transport_method?: any, body_hash?: any}
# --pagination shape: {mergeWithParent?: bool, url?: string, method?: any, headers?: record, qs?: record, body?: any, condition?: any}
# --response shape: {type?: any, valid?: any, limit?: any, error?: any, iterate?: any, temp?: record, output?: any, trigger?: record, data?: record, metadata?: record, uid?: any, oauth?: record, wrapper?: any, expires?: string}
# --respond shape: {type?: any, status?: any, headers?: record, body?: any}
# --verification shape: {condition?: any, respond?: record}
# --repeat shape: {condition?: string, delay?: float, limit?: float}
export def "sdk-apps-modules put-by-SDK_appName-SDK_appVersion-SDK_moduleName" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_moduleName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # Request URL
  --baseUrl: string # Base URL for endpoints starting with /
  --encodeUrl: string@bool-completer # This directive controls the encoding of URLs. It is on by default, so if you have any special characters in your URL, they will be automatically encoded. But there might be situations where you don't want your URL to be encoded automatically, or you want to control what parts of the URL are encoded. To do this, set this flag to false. (default: true)
  --method: any # This directive specifies the HTTP method that will be used to issue the request.
  --headers: record # This directive specifies headers that will be sent with the request.
  --qs: record # This directive specifies the query string to use when making the request.
  --ca: string # Custom Certificate Authority
  --body-body: any # This directive specifies the request body.
  --type: any
  --temp: record # The temp directive specifies an object, which can be used to create custom temporary variables. It also creates a temp variable in IML, through which you then access your variables. The temp collection is not persisted and will be lost after the module is done executing.
  --condition: any # This directive specifies whether to execute the request or not. (default: true)
  --aws: record # Helper directive, that will simplify generating AWS signatures. — shape: {key?: string, secret?: string, session?: string, bucket?: string, sign_version?: any}
  --gzip: string@bool-completer # Add an Accept-Encoding header to request compressed content encodings from the server (if not already present) and decode supported content encodings in the response. (default: false)
  --followRedirects: string@bool-completer # This directive specifies whether to follow GET HTTP 3xx responses as redirects or never. (default: true)
  --followAllRedirects: string@bool-completer # This directive specifies whether to follow non-GET HTTP 3xx responses as redirects or never. (default: true)
  --log: record # This directive specifies logging options for both the request and the response. — shape: {sanitize?: list}
  --oauth: record # Helper directive, that will simplify generating an OAuth1 Authorization headers. — shape: {consumer_key?: string, consumer_secret?: string, private_key?: string, token?: string, token_secret?: string, verifier?: string, signature_method?: any, transport_method?: any, body_hash?: any}
  --pagination: record # Directive to specify how to process paginated responses. — shape: {mergeWithParent?: bool, url?: string, method?: any, headers?: record, qs?: record, body?: any, condition?: any}
  --response: record # Response parsing configuration — shape: {type?: any, valid?: any, limit?: any, error?: any, iterate?: any, temp?: record, output?: any, trigger?: record, data?: record, metadata?: record, uid?: any, oauth?: record, wrapper?: any, expires?: string}
  --output: any
  --iterate: any
  --respond: record # shape: {type?: any, status?: any, headers?: record, body?: any}
  --verification: record # shape: {condition?: any, respond?: record}
  --repeat: record # Repeats a request under a certain condition with a predefined delay in milliseconds. The maximum number of repeats can be bounded by the repeat.limit. — shape: {condition?: string, delay?: float, limit?: float}
]: any -> record<url: string, method: string, qs: record, body: record, headers: record, response: record<iterate: string, trigger: record<id: string, date: string, type: string, order: string>, output: string, limit: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/modules/($SDK_moduleName)/api")
  let body = {url: $body_url, baseUrl: $baseUrl, encodeUrl: $encodeUrl, method: $method, headers: $headers, qs: $qs, ca: $ca, body: $body_body, type: $type, temp: $temp, condition: $condition, aws: $aws, gzip: $gzip, followRedirects: $followRedirects, followAllRedirects: $followAllRedirects, log: $log, oauth: $oauth, pagination: $pagination, response: $response, output: $output, iterate: $iterate, respond: $respond, verification: $verification, repeat: $repeat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set Module Section
#
# PUT /sdk/apps/{SDK_appName}/{SDK_appVersion}/modules/{SDK_moduleName}/epoch
# --aws shape: {key?: string, secret?: string, session?: string, bucket?: string, sign_version?: any}
# --oauth shape: {consumer_key?: string, consumer_secret?: string, private_key?: string, token?: string, token_secret?: string, verifier?: string, signature_method?: any, transport_method?: any, body_hash?: any}
# --log shape: {sanitize?: list}
# --pagination shape: {mergeWithParent?: bool, url?: string, method?: any, headers?: record, qs?: record, body?: any, condition?: any}
# --repeat shape: {condition?: string, delay?: float, limit?: float}
# --response shape: {type?: any, valid?: any, limit?: any, error?: any, iterate?: any, temp?: record, output: record, oauth?: record}
export def "sdk-apps-modules-epoch put" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_moduleName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # Request URL
  --encodeUrl: string@bool-completer # This directive controls the encoding of URLs. It is on by default, so if you have any special characters in your URL, they will be automatically encoded. But there might be situations where you don't want your URL to be encoded automatically, or you want to control what parts of the URL are encoded. To do this, set this flag to false. (default: true)
  --method: any
  --headers: record # Request headers
  --qs: record # Query string parameters
  --ca: string # Custom Certificate Authority
  --body-body: any # Request body
  --type: any
  --temp: record # Temporary variables accessible during execution
  --condition: any # default: true
  --aws: record # Helper directive, that will simplify generating AWS signatures. — shape: {key?: string, secret?: string, session?: string, bucket?: string, sign_version?: any}
  --oauth: record # Helper directive, that will simplify generating an OAuth1 Authorization headers. — shape: {consumer_key?: string, consumer_secret?: string, private_key?: string, token?: string, token_secret?: string, verifier?: string, signature_method?: any, transport_method?: any, body_hash?: any}
  --gzip: string@bool-completer # Add an Accept-Encoding header to request compressed content encodings from the server (if not already present) and decode supported content encodings in the response. (default: false)
  --followRedirects: string@bool-completer # This directive specifies whether to follow GET HTTP 3xx responses as redirects or never. (default: true)
  --followAllRedirects: string@bool-completer # This directive specifies whether to follow non-GET HTTP 3xx responses as redirects or never. (default: true)
  --log: record # This directive specifies logging options for both the request and the response. — shape: {sanitize?: list}
  --pagination: record # Directive to specify how to process paginated responses. — shape: {mergeWithParent?: bool, url?: string, method?: any, headers?: record, qs?: record, body?: any, condition?: any}
  --repeat: record # Repeats a request under a certain condition with a predefined delay in milliseconds. The maximum number of repeats can be bounded by the repeat.limit. — shape: {condition?: string, delay?: float, limit?: float}
  response: record # shape: {type?: any, valid?: any, limit?: any, error?: any, iterate?: any, temp?: record, output: record, oauth?: record}
]: any -> record<url: string, method: string, qs: record, body: record, headers: record, response: record<iterate: string, trigger: record<id: string, date: string, type: string, order: string>, output: string, limit: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/modules/($SDK_moduleName)/epoch")
  let body = {url: $body_url, encodeUrl: $encodeUrl, method: $method, headers: $headers, qs: $qs, ca: $ca, body: $body_body, type: $type, temp: $temp, condition: $condition, aws: $aws, oauth: $oauth, gzip: $gzip, followRedirects: $followRedirects, followAllRedirects: $followAllRedirects, log: $log, pagination: $pagination, repeat: $repeat, response: $response} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set Module Section
#
# PUT /sdk/apps/{SDK_appName}/{SDK_appVersion}/modules/{SDK_moduleName}/interface
export def "sdk-apps-modules-interface put" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_moduleName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<url: string, method: string, qs: record, body: record, headers: record, response: record<iterate: string, trigger: record<id: string, date: string, type: string, order: string>, output: string, limit: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/modules/($SDK_moduleName)/interface")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set Module Section
#
# PUT /sdk/apps/{SDK_appName}/{SDK_appVersion}/modules/{SDK_moduleName}/parameters
export def "sdk-apps-modules-parameters put" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_moduleName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<url: string, method: string, qs: record, body: record, headers: record, response: record<iterate: string, trigger: record<id: string, date: string, type: string, order: string>, output: string, limit: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/modules/($SDK_moduleName)/parameters")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set Module Section
#
# PUT /sdk/apps/{SDK_appName}/{SDK_appVersion}/modules/{SDK_moduleName}/samples
export def "sdk-apps-modules-samples put" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_moduleName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<url: string, method: string, qs: record, body: record, headers: record, response: record<iterate: string, trigger: record<id: string, date: string, type: string, order: string>, output: string, limit: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/modules/($SDK_moduleName)/samples")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set Module Section
#
# PUT /sdk/apps/{SDK_appName}/{SDK_appVersion}/modules/{SDK_moduleName}/scope
export def "sdk-apps-modules-scope put" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_moduleName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<url: string, method: string, qs: record, body: record, headers: record, response: record<iterate: string, trigger: record<id: string, date: string, type: string, order: string>, output: string, limit: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/modules/($SDK_moduleName)/scope")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Module Section
#
# GET /sdk/apps/{SDK_appName}/{SDK_appVersion}/modules/{SDK_moduleName}/{SDK_moduleSection}
export def "sdk-apps-modules get-by-SDK_appName-SDK_appVersion-SDK_moduleName-SDK_moduleSection" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_moduleName: string
  SDK_moduleSection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<url: string, method: string, qs: record, body: record, headers: record, response: record<iterate: string, trigger: record<id: string, date: string, type: string, order: string>, output: string, limit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/modules/($SDK_moduleName)/($SDK_moduleSection)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Module Visibility
#
# POST /sdk/apps/{SDK_appName}/{SDK_appVersion}/modules/{SDK_moduleName}/{SDK_moduleVisibility}
export def "sdk-apps-modules post-by-SDK_appName-SDK_appVersion-SDK_moduleName-SDK_moduleVisibility" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_moduleName: string
  SDK_moduleVisibility: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<changed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/modules/($SDK_moduleName)/($SDK_moduleVisibility)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clone Module
#
# POST /sdk/apps/{SDK_appName}/{SDK_appVersion}/modules/{SDK_moduleName}/clone
export def "sdk-apps-modules-clone post" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_moduleName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --newName: string
  --label: string
]: any -> record<module: record<name: string, label: string, description: string, typeId: int, connection: string, webhook: string, crud: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/modules/($SDK_moduleName)/clone")
  let body = {newName: $newName, label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set Module Deprecation
#
# POST /sdk/apps/{SDK_appName}/{SDK_appVersion}/modules/{SDK_moduleName}/{SDK_moduleDeprecation}
export def "sdk-apps-modules post-by-SDK_appName-SDK_appVersion-SDK_moduleName-SDK_moduleDeprecation" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_moduleName: string
  SDK_moduleDeprecation: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<changed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/modules/($SDK_moduleName)/($SDK_moduleDeprecation)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set Module Archive Status
#
# POST /sdk/apps/{SDK_appName}/{SDK_appVersion}/modules/{SDK_moduleName}/{SDK_moduleArchiveStatus}
export def "sdk-apps-modules post-by-SDK_appName-SDK_appVersion-SDK_moduleName-SDK_moduleArchiveStatus" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_moduleName: string
  SDK_moduleArchiveStatus: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<changed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/modules/($SDK_moduleName)/($SDK_moduleArchiveStatus)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set Module Consumable
#
# PUT /sdk/apps/{SDK_appName}/{SDK_appVersion}/modules/{SDK_moduleName}/{SDK_moduleConsumable}
export def "sdk-apps-modules put-by-SDK_appName-SDK_appVersion-SDK_moduleName-SDK_moduleConsumable" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_moduleName: string
  SDK_moduleConsumable: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --centicreditsFormula: string
  --centicreditsFormulaDescription: string
  --centicreditsFormulaDocumentationUrl: string
  --centicreditsFormulaMeta: string
]: any -> record<name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/modules/($SDK_moduleName)/($SDK_moduleConsumable)")
  let body = {centicreditsFormula: $centicreditsFormula, centicreditsFormulaDescription: $centicreditsFormulaDescription, centicreditsFormulaDocumentationUrl: $centicreditsFormulaDocumentationUrl, centicreditsFormulaMeta: $centicreditsFormulaMeta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List App RPCs
#
# GET /sdk/apps/{SDK_appName}/{SDK_appVersion}/rpcs
export def "sdk-apps-rpcs get-by-SDK_appName-SDK_appVersion" [
  SDK_appName: string
  SDK_appVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<rpcs: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/rpcs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create RPC
#
# POST /sdk/apps/{SDK_appName}/{SDK_appVersion}/rpcs
export def "sdk-apps-rpcs post-by-SDK_appName-SDK_appVersion" [
  SDK_appName: string
  SDK_appVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --label: string
  --connection: string # nullable
]: any -> record<appRpc: record<name: string, label: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/rpcs")
  let body = {name: $name, label: $label, connection: $connection} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete RPC
#
# DELETE /sdk/apps/{SDK_appName}/{SDK_appVersion}/rpcs/{SDK_rpcName}
export def "sdk-apps-rpcs delete" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_rpcName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appRpc: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/rpcs/($SDK_rpcName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get RPC
#
# GET /sdk/apps/{SDK_appName}/{SDK_appVersion}/rpcs/{SDK_rpcName}
export def "sdk-apps-rpcs get-by-SDK_appName-SDK_appVersion-SDK_rpcName" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_rpcName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appRpc: record<name: string, label: string, connection: string, altConnection: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/rpcs/($SDK_rpcName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch RPC
#
# PATCH /sdk/apps/{SDK_appName}/{SDK_appVersion}/rpcs/{SDK_rpcName}
export def "sdk-apps-rpcs patch" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_rpcName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --label: string
  --connection: string # nullable
  --altConnection: string # nullable
]: any -> record<appRpc: record<name: string, label: string, connection: string, altConnection: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/rpcs/($SDK_rpcName)")
  let body = {label: $label, connection: $connection, altConnection: $altConnection} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test RPC
#
# POST /sdk/apps/{SDK_appName}/{SDK_appVersion}/rpcs/{SDK_rpcName}
# --data shape: {id?: string, jidlo?: string}
# --schema item shape: {name?: string, type?: string, required?: bool}
export def "sdk-apps-rpcs post-by-SDK_appName-SDK_appVersion-SDK_rpcName" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_rpcName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # shape: {id?: string, jidlo?: string}
  --schema: list # item shape: {name?: string, type?: string, required?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/rpcs/($SDK_rpcName)")
  let body = {data: $data, schema: $schema} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get RPC Section
#
# GET /sdk/apps/{SDK_appName}/{SDK_appVersion}/rpcs/{SDK_rpcName}/{SDK_rpcSection}
export def "sdk-apps-rpcs get-by-SDK_appName-SDK_appVersion-SDK_rpcName-SDK_rpcSection" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_rpcName: string
  SDK_rpcSection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<url: string, method: string, qs: record, body: record, headers: record, response: record<iterate: string, output: record<label: string, value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/rpcs/($SDK_rpcName)/($SDK_rpcSection)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set RPC Section
#
# PUT /sdk/apps/{SDK_appName}/{SDK_appVersion}/rpcs/{SDK_rpcName}/{SDK_rpcSection}
# --response shape: {iterate?: string, output?: record}
export def "sdk-apps-rpcs put" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_rpcName: string
  SDK_rpcSection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string
  --method: string
  --qs: record
  --body-body: record
  --headers: record
  --response: record # shape: {iterate?: string, output?: record}
]: any -> record<change: record<id: int, group: string, code: string, oldValue: record, newValue: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/rpcs/($SDK_rpcName)/($SDK_rpcSection)")
  let body = {url: $body_url, method: $method, qs: $qs, body: $body_body, headers: $headers, response: $response} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Function
#
# POST /sdk/apps/{SDK_appName}/{SDK_appVersion}/functions
export def "sdk-apps-functions post" [
  SDK_appName: string
  SDK_appVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
]: any -> record<appFunction: record<name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/functions")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List App Functions
#
# GET /sdk/apps/{SDK_appName}/{SDK_appVersion}/functions
export def "sdk-apps-functions list" [
  SDK_appName: string
  SDK_appVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --all: string@bool-completer # e.g. true
]: nothing -> record<appFunctions: table<name: string, args: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/functions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Function
#
# GET /sdk/apps/{SDK_appName}/{SDK_appVersion}/functions/{SDK_functionName}
export def "sdk-apps-functions get" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_functionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appFunction: record<name: string, code: string, changes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/functions/($SDK_functionName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Function
#
# DELETE /sdk/apps/{SDK_appName}/{SDK_appVersion}/functions/{SDK_functionName}
export def "sdk-apps-functions delete" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_functionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appFunction: record<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/functions/($SDK_functionName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Function Code
#
# GET /sdk/apps/{SDK_appName}/{SDK_appVersion}/functions/{SDK_functionName}/code
export def "sdk-apps-functions-code get" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_functionName: string
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
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/functions/($SDK_functionName)/code")
  let accept_val = "application/javascript"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Function Code
#
# PUT /sdk/apps/{SDK_appName}/{SDK_appVersion}/functions/{SDK_functionName}/code
export def "sdk-apps-functions-code put" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_functionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<change: record<id: int, group: string, item: string, code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/functions/($SDK_functionName)/code")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/javascript" $body
}

# Get Function Test
#
# GET /sdk/apps/{SDK_appName}/{SDK_appVersion}/functions/{SDK_functionName}/test
export def "sdk-apps-functions-test get" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_functionName: string
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
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/functions/($SDK_functionName)/test")
  let accept_val = "application/javascript"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Function Test
#
# PUT /sdk/apps/{SDK_appName}/{SDK_appVersion}/functions/{SDK_functionName}/test
export def "sdk-apps-functions-test put" [
  SDK_appName: string
  SDK_appVersion: string
  SDK_functionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<changed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/($SDK_appVersion)/functions/($SDK_functionName)/test")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/javascript" $body
}

# Create Connection
#
# POST /sdk/apps/{SDK_appName}/connections
export def "sdk-apps-connections post" [
  SDK_appName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4
  --label: string
]: any -> record<appConnection: record<name: string, label: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/connections")
  let body = {type: $type, label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List App Connections
#
# GET /sdk/apps/{SDK_appName}/connections
export def "sdk-apps-connections get-by-SDK_appName" [
  SDK_appName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appConnections: table<name: string, label: string, type: string, parameters: record, app_version: string, alias_to: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/connections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Connection
#
# GET /sdk/apps/connections/{SDK_connectionName}
export def "sdk-apps-connections get-by-SDK_connectionName" [
  SDK_connectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appConnection: record<name: string, label: string, type: string, connectedSystemName: string, appVersion: string, redirectUri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/connections/($SDK_connectionName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Connection
#
# PATCH /sdk/apps/connections/{SDK_connectionName}
export def "sdk-apps-connections patch" [
  SDK_connectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --label: string
  --connectedSystemName: string # nullable
]: any -> record<appConnection: record<name: string, label: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/connections/($SDK_connectionName)")
  let body = {label: $label, connectedSystemName: $connectedSystemName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Connection
#
# DELETE /sdk/apps/connections/{SDK_connectionName}
export def "sdk-apps-connections delete" [
  SDK_connectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appConnection: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/connections/($SDK_connectionName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Connection Section
#
# GET /sdk/apps/connections/{SDK_connectionName}/{SDK_connectionSection}
export def "sdk-apps-connections get-by-SDK_connectionName-SDK_connectionSection" [
  SDK_connectionName: string
  SDK_connectionSection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<authorize: record<qs: record<scope: string, client_id: string, redirect_uri: string, response_type: string>, url: string, response: record<temp: record>>, token: record<url: string, body: record<code: string, client_id: string, grant_type: string, redirect_uri: string, client_secret: string>, type: string, method: string, response: record<data: record>, log: record<sanitize: list>>, info: record<url: string, headers: record<authorization: string>, response: record<uid: string, metadata: record>, log: record<sanitize: list>>, invalidate: record<url: string, headers: record<authorization: string>, log: record<sanitize: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/connections/($SDK_connectionName)/($SDK_connectionSection)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Connection Section
#
# PUT /sdk/apps/connections/{SDK_connectionName}/{SDK_connectionSection}
export def "sdk-apps-connections put" [
  SDK_connectionName: string
  SDK_connectionSection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<change: record<id: int, group: string, item: string, code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/connections/($SDK_connectionName)/($SDK_connectionSection)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Connection Common
#
# GET /sdk/apps/connections/{SDK_connectionName}/common
export def "sdk-apps-connections-common get" [
  SDK_connectionName: string
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
  let full_url = (build-url $base $"/sdk/apps/connections/($SDK_connectionName)/common")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Connection Common
#
# PUT /sdk/apps/connections/{SDK_connectionName}/common
export def "sdk-apps-connections-common put" [
  SDK_connectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<changed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/connections/($SDK_connectionName)/common")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Webhook
#
# POST /sdk/apps/{SDK_appName}/webhooks
export def "sdk-apps-webhooks post" [
  SDK_appName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # e.g. application/json
  --type: string
  --label: string
  --connection: string
]: any -> record<appWebhook: record<name: string, label: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/webhooks")
  let body = {type: $type, label: $label, connection: $connection} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List App Webhooks
#
# GET /sdk/apps/{SDK_appName}/webhooks
export def "sdk-apps-webhooks get-by-SDK_appName" [
  SDK_appName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appWebhooks: table<name: string, label: string, type: string, parameters: record, app_version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/($SDK_appName)/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Webhook
#
# GET /sdk/apps/webhooks/{SDK_webhookName}
export def "sdk-apps-webhooks get-by-SDK_webhookName" [
  SDK_webhookName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appWebhook: record<appName: string, appVersion: int, name: string, label: string, type: string, connection: string, altConnection: string, api: record, parameters: record, attach: record, detach: record, update: record, scope: record, changes: record, aliasTo: string, endpoint: string, shieldEndpoint: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/webhooks/($SDK_webhookName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Webhook
#
# PATCH /sdk/apps/webhooks/{SDK_webhookName}
export def "sdk-apps-webhooks patch" [
  SDK_webhookName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # e.g. application/json
  --label: string
  --connection: string # nullable
  --altConnection: string # nullable
]: any -> record<appWebhook: record<name: string, label: string, type: string, connection: string, altConnection: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/webhooks/($SDK_webhookName)")
  let body = {label: $label, connection: $connection, altConnection: $altConnection} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Webhook
#
# DELETE /sdk/apps/webhooks/{SDK_webhookName}
export def "sdk-apps-webhooks delete" [
  SDK_webhookName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appWebhook: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/webhooks/($SDK_webhookName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Webhook Section
#
# GET /sdk/apps/webhooks/{SDK_webhookName}/{SDK_webhookSection}
export def "sdk-apps-webhooks get-by-SDK_webhookName-SDK_webhookSection" [
  SDK_webhookName: string
  SDK_webhookSection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<output: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/webhooks/($SDK_webhookName)/($SDK_webhookSection)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Webhook Section
#
# PUT /sdk/apps/webhooks/{SDK_webhookName}/{SDK_webhookSection}
export def "sdk-apps-webhooks put" [
  SDK_webhookName: string
  SDK_webhookSection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # e.g. application/jsonc
  --output: string
  --test: string@bool-completer
]: any -> record<change: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sdk/apps/webhooks/($SDK_webhookName)/($SDK_webhookSection)")
  let body = {output: $output, test: $test} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Recreate Connection
#
# POST /sdk/apps/connections/{SDK_connectionName}/recreate
export def "sdk-apps-connections-recreate post" [
  SDK_connectionName: string
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
  let full_url = (build-url $base $"/sdk/apps/connections/($SDK_connectionName)/recreate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List private spaces
#
# GET /private-spaces
export def "private-spaces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int # The ID of the organization. (e.g. 1)
  --externalId: string # Filter private spaces by external ID. (e.g. 42)
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
  --pgsortBy: string # The value that will be used to sort returned entities by.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<privateSpaces: table<id: int, name: string, organizationId: int, globalAgentsEnabled: bool, type: string, privateSpaceOwnerName: string, privateSpaceOwnerEmail: string, privateSpaceOwnerId: int, operationsLimit: int, transferLimit: string, consumedOperations: int, consumedTransfer: string, isPaused: bool, consumedCenticredits: int>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar") (serialize-qp "externalId" $externalId "scalar") (serialize-qp "cols" $cols "multi") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/private-spaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a private space
#
# POST /private-spaces
export def "private-spaces post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: int # The ID of the organization to create the private space in. (e.g. 1)
  userId: int # The ID of the user who will own the private space. (e.g. 42)
  --operationsLimit: int # The operations limit for the private space. Transfer limit is auto-calculated. Pass `null` for unlimited. (nullable, e.g. 10000)
]: any -> record<privateSpace: record<id: int, name: string, organizationId: int, deleted: bool, externalId: string, globalAgentsEnabled: bool, type: string, privateSpaceOwnerName: string, privateSpaceOwnerEmail: string, privateSpaceOwnerId: int, operationsLimit: int, transferLimit: string, consumedOperations: int, consumedTransfer: string, isPaused: bool, consumedCenticredits: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/private-spaces")
  let body = {organizationId: $organizationId, userId: $userId, operationsLimit: $operationsLimit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a private space
#
# DELETE /private-spaces/{privateSpaceId}
export def "private-spaces delete" [
  privateSpaceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # When `true`, confirms the deletion.
]: nothing -> record<privateSpaceId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/private-spaces/($privateSpaceId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a private space
#
# GET /private-spaces/{privateSpaceId}
export def "private-spaces get" [
  privateSpaceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
]: nothing -> record<privateSpace: record<id: int, name: string, organizationId: int, globalAgentsEnabled: bool, type: string, privateSpaceOwnerName: string, privateSpaceOwnerEmail: string, privateSpaceOwnerId: int, operationsLimit: int, transferLimit: string, consumedOperations: int, consumedTransfer: string, isPaused: bool, consumedCenticredits: int, operations: string, transfer: string, centicredits: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/private-spaces/($privateSpaceId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a private space
#
# PATCH /private-spaces/{privateSpaceId}
export def "private-spaces patch" [
  privateSpaceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # When `true`, confirms the operation even if the new limit is below the current consumption. This will pause the private space.
  --operationsLimit: int # Optional. The new operations limit for the private space. Transfer limit is auto-calculated. Set to `null` to remove limits, omit to leave unchanged. (nullable, e.g. 10000)
]: any -> record<privateSpace: record<id: int, name: string, organizationId: int, deleted: bool, externalId: string, globalAgentsEnabled: bool, type: string, privateSpaceOwnerName: string, privateSpaceOwnerEmail: string, privateSpaceOwnerId: int, operationsLimit: int, transferLimit: string, consumedOperations: int, consumedTransfer: string, isPaused: bool, consumedCenticredits: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/private-spaces/($privateSpaceId)" $qp)
  let body = {operationsLimit: $operationsLimit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the current user's pinned apps for an organization
#
# GET /users/me/pinned-apps
export def "users-me-pinned-apps get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int # e.g. 1
]: nothing -> record<pinnedApps: table<appName: string, isAppPinned: bool, pinnedModules: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/me/pinned-apps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pin an app for the current user in an organization
#
# POST /users/me/pinned-apps
export def "users-me-pinned-apps post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: int # Organization to scope the pin to. The current user must be a member. (e.g. 1)
  appName: string # App name. SDK apps are prefixed with `app#`; native apps are bare package names. (e.g. app#my-sdk-app)
]: any -> record<pinnedApp: record<appName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/pinned-apps")
  let body = {organizationId: $organizationId, appName: $appName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unpin an app for the current user in an organization
#
# DELETE /users/me/pinned-apps/{appName}
export def "users-me-pinned-apps delete" [
  appName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int # e.g. 1
]: nothing -> record<pinnedApp: record<appName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/me/pinned-apps/($appName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pin a module for the current user in an organization
#
# POST /users/me/pinned-apps/{appName}/modules
export def "users-me-pinned-apps-modules post" [
  appName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: int # Organization to scope the pin to. The current user must be a member. (e.g. 1)
  moduleName: string # Module name within the parent app (matches the `name` field in the app's module manifest). (e.g. send-message)
]: any -> record<pinnedModule: record<appName: string, moduleName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/me/pinned-apps/($appName)/modules")
  let body = {organizationId: $organizationId, moduleName: $moduleName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unpin a module for the current user in an organization
#
# DELETE /users/me/pinned-apps/{appName}/modules/{moduleName}
export def "users-me-pinned-apps-modules delete" [
  appName: string
  moduleName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int # e.g. 1
]: nothing -> record<pinnedModule: record<appName: string, moduleName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/me/pinned-apps/($appName)/modules/($moduleName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List teams
#
# GET /teams
export def "teams list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int # The ID of the organization. (e.g. 1)
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
  --pgsortBy: string # The value that will be used to sort returned entities by.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<teams: table<id: int, name: string, organizationId: int, operationsLimit: int, transferLimit: any>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar") (serialize-qp "cols" $cols "multi") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a team
#
# POST /teams
export def "teams post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the team.
  organizationId: int # The ID of the organization.
  --operationsLimit: int # The maximum number of operations allowed for the team.
]: any -> record<team: record<id: int, name: string, organizationId: int, operationsLimit: int, transferLimit: any>, userTeamRole: record<usersRoleId: int, userId: int, teamId: int, changeable: bool, ssoPending: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/teams")
  let body = {name: $name, organizationId: $organizationId, operationsLimit: $operationsLimit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get team details
#
# GET /teams/{teamId}
export def "teams get" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
]: nothing -> record<team: record<id: int, name: string, organizationId: int, operationsLimit: int, transferLimit: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($teamId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a team
#
# PATCH /teams/{teamId}
@deprecated --flag scenarioDrafts
export def "teams patch" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
  --name: string # The new name of the team. Maximum length is 128 characters.
  --operationsLimit: int # The maximum number of operations allowed for the team.
  --scenarioDrafts: string@bool-completer # This property is deprecated. It is only supported on private instances and ignored on Make's public cloud.  (DEPRECATED)
]: any -> record<team: record<id: int, name: string, organizationId: int, operationsLimit: int, transferLimit: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($teamId)" $qp)
  let body = {name: $name, operationsLimit: $operationsLimit, scenarioDrafts: $scenarioDrafts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a team
#
# DELETE /teams/{teamId}
export def "teams delete" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # Set this parameter to `true` to confirm the team deletion. Otherwise, the API call returns an error and the team is not deleted. (e.g. true)
]: nothing -> record<team: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($teamId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user roles in the team
#
# GET /teams/{teamId}/user-team-roles
export def "teams-user-team-roles list" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
  --pgsortBy: string # The value that will be used to sort returned entities by.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<userTeamRoles: table<usersRoleId: int, userId: int, teamId: int, changeable: bool, ssoPending: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols" $cols "multi") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($teamId)/user-team-roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user team role details
#
# GET /teams/{teamId}/user-team-roles/{userId}
export def "teams-user-team-roles get" [
  teamId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
  --pgsortBy: string # The value that will be used to sort returned entities by.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<userTeamRole: record<usersRoleId: int, userId: int, teamId: int, changeable: bool, ssoPending: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols" $cols "multi") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($teamId)/user-team-roles/($userId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List team variables
#
# GET /teams/{teamId}/variables
export def "teams-variables get" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<teamVariables: record<typeId: int, name: string, value: any, isSystem: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($teamId)/variables")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create team variable
#
# POST /teams/{teamId}/variables
export def "teams-variables post" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --typeId: float # Number representing the type of the custom variable. The mapping of `typeId` and variable types is as follows:  - 1: `number`,  - 2: `string`,  - 3: `boolean`,  - 4: `date`in ISO 8601 compliant format `YYYY-MM-DDTHH:mm:ss.sssZ`. For example: `1998-03-06T12:31:00.000Z`.
  --value: any # Value assigned to the custom variable.
  --name: string # The name of the variable. You can use letters, digits, `$` and `_` characters in the custom variable name.
]: any -> record<teamVariable: record<typeId: int, name: string, value: any, isSystem: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($teamId)/variables")
  let body = {typeId: $typeId, value: $value, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update team variable
#
# PATCH /teams/{teamId}/variables/{variableName}
export def "teams-variables patch" [
  teamId: int
  variableName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --typeId: float # Number representing the type of the custom variable. The mapping of `typeId` and variable types is as follows:  - 1: `number`,  - 2: `string`,  - 3: `boolean`,  - 4: `date`in ISO 8601 compliant format `YYYY-MM-DDTHH:mm:ss.sssZ`. For example: `1998-03-06T12:31:00.000Z`.
  --value: any # Value assigned to the custom variable.
]: any -> record<teamVariable: record<typeId: int, name: string, value: any, isSystem: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($teamId)/variables/($variableName)")
  let body = {typeId: $typeId, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete team variable
#
# DELETE /teams/{teamId}/variables/{variableName}
export def "teams-variables delete" [
  teamId: int
  variableName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # Set to `true` to confirm deleting the custom variable. Otherwise the API call fails with the error IM004 (406). (e.g. true)
]: nothing -> record<ok: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($teamId)/variables/($variableName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# History of custom variable updates
#
# GET /teams/{teamId}/variables/{variableName}/history
export def "teams-variables-history get" [
  teamId: int
  variableName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<teamVariableHistory: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($teamId)/variables/($variableName)/history")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if email is part of team
#
# POST /teams/{teamId}/check-email-is-member
export def "teams-check-email-is-member post" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # JWT token used for internal Authorization. (e.g. Internal eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhYWEiOjF9.PWCmjzr_lg9npxv5eUph5B937LXVspIKlRdByWRWKxs)
  recipients: list
]: any -> record<isMember: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($teamId)/check-email-is-member")
  let body = {recipients: $recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get team usage
#
# GET /teams/{teamId}/usage
export def "teams-usage get" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationTimezone: string@bool-completer # When set to `true`, the endpoint will calculate and return usage data based on the organization's timezone instead of the user's local timezone. (e.g. true)
]: nothing -> record<data: table<date: string, operations: int, dataTransfer: int, centicredits: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationTimezone" $organizationTimezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($teamId)/usage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get team LLM configuration
#
# GET /teams/{teamId}/llm-configuration
export def "teams-llm-configuration get" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<aiMappingAccountId: int, aiMappingModelName: string, aiMappingBuiltinTier: string, aiMappingBuiltinTierInfo: any, aiToolkitAccountId: int, aiToolkitModelName: string, aiToolkitBuiltinTier: string, aiToolkitBuiltinTierInfo: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($teamId)/llm-configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update team LLM configuration
#
# PATCH /teams/{teamId}/llm-configuration
export def "teams-llm-configuration patch" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --aiMappingAccountId: int # ID of the account used for AI mapping (nullable)
  --aiMappingModelName: string # Name of the AI model used for mapping (nullable)
  --aiMappingBuiltinTier: string@aiMappingBuiltinTier-completer # The builtin tier for AI mapping (small, medium, large) (nullable)
  --aiToolkitAccountId: int # ID of the account used for AI toolkit (nullable)
  --aiToolkitModelName: string # Name of the AI model used for toolkit (nullable)
  --aiToolkitBuiltinTier: string@aiToolkitBuiltinTier-completer # The builtin tier for AI toolkit (small, medium, large) (nullable)
]: any -> record<aiMappingAccountId: int, aiMappingModelName: string, aiMappingBuiltinTier: string, aiMappingBuiltinTierInfo: any, aiToolkitAccountId: int, aiToolkitModelName: string, aiToolkitBuiltinTier: string, aiToolkitBuiltinTierInfo: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($teamId)/llm-configuration")
  let body = {aiMappingAccountId: $aiMappingAccountId, aiMappingModelName: $aiMappingModelName, aiMappingBuiltinTier: $aiMappingBuiltinTier, aiToolkitAccountId: $aiToolkitAccountId, aiToolkitModelName: $aiToolkitModelName, aiToolkitBuiltinTier: $aiToolkitBuiltinTier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get feature controls of an organization which the team belongs to
#
# GET /teams/{teamId}/feature-controls
export def "teams-feature-controls get" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --featureControlName: string # The feature control name. (e.g. Make AI Tools)
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
]: nothing -> record<enableAllControlFeatures: bool, featureControls: table<id: int, name: string, label: record, description: record, tags: list, warning_message: record, enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "featureControlName" $featureControlName "scalar") (serialize-qp "cols" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($teamId)/feature-controls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List templates
#
# GET /templates
export def "templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: int # The unique ID of the team whose templates will be retrieved. (e.g. 1)
  --public: string@bool-completer # Indicates if the template is public which means that it was published and approved, and can be accessed by anyone. (e.g. true)
  --usedApps: list # The array with the text IDs of the apps used in the templates. This parameter allows you to get only the templates containing specific apps. (e.g. [http])
  --cols: list # Specifies the group of values to return. For example, you may want to retrieve only the names and IDs of the templates.
  --pgsortBy: string # The value that will be used to sort returned entities by.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<templates: table<id: int, name: string, teamId: int, teamName: string, organizationId: string, description: string, usedApps: list, public: bool, published: string, approved: string, approvedId: int, requestedApproval: bool, publishedId: int, publicUrl: string, approvedName: string, publishedName: string>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "public" $public "scalar") (serialize-qp "usedApps[]" $usedApps "multi") (serialize-qp "cols[]" $cols "multi") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create template
#
# POST /templates
# --blueprint shape: {flow?: list, name?: string, metadata?: record}
# --scheduling shape: {type?: "immediately"|"indefinitely"|"once"|"daily"|"weekly"|"monthly"|"yearly", interval?: int, date?: string, between?: list, time?: string, days?: list, months?: list, restrict?: list, maximum_runs_per_minute?: int}
# --controller shape: {name?: string, description?: string, idSequence?: int, modules?: record}
export def "templates post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies the group of values to return. For example, you may want to retrieve only names and IDs of the newly created template. (e.g. [id, name])
  --teamId: int # The unique numeric ID of the team in which the template will be created.
  --language: string # The language of the template determining in which language template details such as module names will be displayed. This property also impacts the visibility of the created template and cannot be changed later.
  --blueprint: record # The full blueprint of the scenario or template. It contains information about the general setup and all included apps and modules, and their settings. — shape: {flow?: list, name?: string, metadata?: record}
  --scheduling: record # The scheduling details of the template. — shape: {type?: "immediately"|"indefinitely"|"once"|"daily"|"weekly"|"monthly"|"yearly", interval?: int, date?: string, between?: list, time?: string, days?: list, months?: list, restrict?: list, maximum_runs_per_minute?: int}
  --controller: record # The controller of the template. This property refers to wizards that can be added to each module in the template from the Make interface. The wizards contain short instructions for other users explaining how to use the template step by step. — shape: {name?: string, description?: string, idSequence?: int, modules?: record}
]: any -> record<template: record<id: int, name: string, teamId: int, teamName: string, organizationId: string, description: string, usedApps: list<string>, public: bool, published: string, approved: string, approvedId: int, requestedApproval: bool, publishedId: int, publicUrl: string, approvedName: string, publishedName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/templates" $qp)
  let body = {teamId: $teamId, language: $language, blueprint: $blueprint, scheduling: $scheduling, controller: $controller} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get template details
#
# GET /templates/{templateId}
export def "templates get" [
  templateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies the group of values to return. For example, you may want to retrieve only the ID and name of the template.
]: nothing -> record<template: record<id: int, name: string, teamId: int, teamName: string, organizationId: string, description: string, usedApps: list<string>, public: bool, published: string, approved: string, approvedId: int, requestedApproval: bool, publishedId: int, publicUrl: string, approvedName: string, publishedName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/templates/($templateId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update template
#
# PATCH /templates/{templateId}
# --blueprint shape: {flow?: list, name?: string, metadata?: record}
# --scheduling shape: {type?: "immediately"|"indefinitely"|"once"|"daily"|"weekly"|"monthly"|"yearly", interval?: int, date?: string, between?: list, time?: string, days?: list, months?: list, restrict?: list, maximum_runs_per_minute?: int}
# --controller shape: {name?: string, description?: string, idSequence?: int, modules?: record}
export def "templates patch" [
  templateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --templatePublicId: int # The unique ID of the public version of the approved template. It can be retrieved from the [List templates](/api-reference/templates/get--templates.md) endpoint as one of the following IDs: `publishedId` for all published templates that are waiting for approval or not, or `approvedId` for approved templates. (e.g. 18)
  --cols: list # Specifies the group of values to return. For example, you may want to retrieve only the description of the template. (e.g. [description])
  --name: string # The new name of the template. The name does not need to be unique.
  --blueprint: record # The full blueprint of the template. It contains information about the general setup and all included apps and modules, and their settings. — shape: {flow?: list, name?: string, metadata?: record}
  --scheduling: record # The scheduling details of the template. — shape: {type?: "immediately"|"indefinitely"|"once"|"daily"|"weekly"|"monthly"|"yearly", interval?: int, date?: string, between?: list, time?: string, days?: list, months?: list, restrict?: list, maximum_runs_per_minute?: int}
  --controller: record # The controller of the template. This property refers to wizards that can be added to each module in the template from the Make interface. The wizards contain short instructions for other users explaining how to use the template step by step. — shape: {name?: string, description?: string, idSequence?: int, modules?: record}
]: any -> record<template: table<id: int, name: string, teamId: int, teamName: string, organizationId: string, description: string, usedApps: list, public: bool, published: string, approved: string, approvedId: int, requestedApproval: bool, publishedId: int, publicUrl: string, approvedName: string, publishedName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templatePublicId" $templatePublicId "scalar") (serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/templates/($templateId)" $qp)
  let body = {name: $name, blueprint: $blueprint, scheduling: $scheduling, controller: $controller} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete template
#
# DELETE /templates/{templateId}
export def "templates delete" [
  templateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # Confirms the deletion of the private or published template. If the parameter is missing or it is set to `false` an error code is returned and the resource is not deleted. The public (approved) templates can only be deleted by administrators. (e.g. true)
]: nothing -> record<template: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "confirmed" $confirmed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/templates/($templateId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get template blueprint
#
# GET /templates/{templateId}/blueprint
export def "templates-blueprint get" [
  templateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forUse: string@bool-completer # If this parameter is set to `true`, it means the blueprint should be used for creating a scenario from the template. (e.g. true)
  --templatePublicId: int # The unique ID of the public version of the approved template. It can be retrieved from the [List templates](/api-reference/templates/get--templates.md) endpoint as one of the following IDs: `publishedId` for all published templates that are waiting for approval or not, or `approvedId` for approved templates. (e.g. 18)
]: nothing -> record<blueprint: record<flow: list<record>, name: string, metadata: record<version: int, scenario: record>>, controller: record<name: string, modules: record, idSequence: int>, scheduling: record<type: string, interval: int>, language: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forUse" $forUse "scalar") (serialize-qp "templatePublicId" $templatePublicId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/templates/($templateId)/blueprint" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Publish template
#
# POST /templates/{templateId}/publish
export def "templates-publish post" [
  templateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies the group of values to return. For example, you may want to retrieve only the name and ID of the published template.
  --body: record
]: any -> record<template: record<id: int, name: string, teamId: int, teamName: string, organizationId: string, description: string, usedApps: list<string>, public: bool, published: string, approved: string, approvedId: int, requestedApproval: bool, publishedId: int, publicUrl: string, approvedName: string, publishedName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/templates/($templateId)/publish" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Request approval
#
# POST /templates/{templateId}/request-approval
export def "templates-request-approval post" [
  templateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --templatePublicId: int # The unique ID of the public version of the approved template. It can be retrieved from the [List templates](/api-reference/templates/get--templates.md) endpoint as one of the following IDs: `publishedId` for all published templates that are waiting for approval or not, or `approvedId` for approved templates. (e.g. 18)
  --cols: list # Specifies the group of values to return. For example, you may want to retrieve only the ID and name of the template you requested approval for.
]: nothing -> record<template: record<id: int, name: string, teamId: int, teamName: string, organizationId: string, description: string, usedApps: list<string>, public: bool, published: string, approved: string, approvedId: int, requestedApproval: bool, publishedId: int, publicUrl: string, approvedName: string, publishedName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templatePublicId" $templatePublicId "scalar") (serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/templates/($templateId)/request-approval" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List public (approved) templates
#
# GET /templates/public
export def "templates-public list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeEn: string@bool-completer # If this parameter is set to `true`, it means English templates should be included in the response. This is relevant only if the user's language is not English. (e.g. true)
  --name: string # The name of the template. This parameter allows limiting returned results to the template(s) with the given name. (e.g. my first template)
  --usedApps: list # The array with the text IDs of the apps used in the templates. This parameter allows you to get only the templates containing specific apps. (e.g. [http])
  --cols: list # Specifies the group of values to return. For example, you may want to retrieve only the names and IDs of the public templates.
  --pgsortBy: string # The value that will be used to sort returned entities by.
  --pgoffset: int # The value of entities you want to skip before getting entities you need.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pglimit: int # Sets the maximum number of results per page in the API call response. For example, `pg[limit]=100`. The default number varies with different API endpoints.
]: nothing -> record<templatesPublic: table<id: int, name: string, description: string, url: string, usedApps: list, usage: int>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeEn" $includeEn "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "usedApps[]" $usedApps "multi") (serialize-qp "cols[]" $cols "multi") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/templates/public" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get public (approved) template details
#
# GET /templates/public/{templateUrl}
export def "templates-public get" [
  templateUrl: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --templatePublicId: int # The unique ID of the public version of the approved template. It can be retrieved from the [List templates](/api-reference/templates/get--templates.md) endpoint as one of the following IDs: `publishedId` for all published templates that are waiting for approval or not, or `approvedId` for approved templates. (e.g. 18)
  --cols: list # Specifies the group of values to return. For example, you may want to retrieve only information about the apps used in the template.
]: nothing -> record<templatePublic: record<id: int, name: string, description: string, url: string, usedApps: list<string>, usage: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templatePublicId" $templatePublicId "scalar") (serialize-qp "cols[]" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/templates/public/($templateUrl)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get public (approved) template blueprint
#
# GET /templates/public/{templateUrl}/blueprint
export def "templates-public-blueprint get" [
  templateUrl: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --templatePublicId: int # The unique ID of the public version of the approved template. It can be retrieved from the [List templates](/api-reference/templates/get--templates.md) endpoint as one of the following IDs: `publishedId` for all published templates that are waiting for approval or not, or `approvedId` for approved templates. (e.g. 18)
]: nothing -> record<blueprint: record<flow: list<record>, name: string, metadata: record<version: int, scenario: record>>, controller: record<name: string, modules: record, idSequence: int>, scheduling: record<type: string, interval: int>, language: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templatePublicId" $templatePublicId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/templates/public/($templateUrl)/blueprint" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List users
#
# GET /users
export def "users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationId: int # The unique ID of the organization whose users will be retrieved. If this parameter is set, the `teamId` parameter must be skipped. For each request either `teamId` or `organizationId` must be defined.
  --teamId: int # The unique ID of the team whose users will be retrieved. If this parameter is set, the `organizationId` parameter must be skipped. For each request either `teamId` or `organizationId` must be defined. (e.g. 1)
  --name: string # Optional filter parameter.
  --email: string # Optional filter parameter.
  --teamRoleId: int # Optional filter parameter. If this parameter is set, the `teamId` parameter must be set as well.
  --organizationRoleId: int # Optional filter parameter. If this parameter is set, the `organizationId` parameter must be set as well.
  --filterByTeamId: int # Filter by team ID. Use 0 to find users not assigned to any team. Requires organizationId.
  --ids: list # Optional filter parameter. Restricts the result to users whose ID is in the given list. (e.g. [1, 2])
  --tfaStatus: int@tfaStatus-completer # The user's two-factor authentication (TFA) status. This field is available only on plans that have the TFA enforcement enabled.
  --cols: list # An array of columns that should be returned from the API. Can be used to save bandwidth when not all properties are needed.
  --pgsortBy: string@pgsortBy-completer-10 # The value that will be used to sort returned entities by. Users can be sorted by name, id and email.
  --pgsortDir: string@pgsortDir-completer # The sorting order. It accepts the ascending and descending direction specifiers.
  --pgoffset: int # The number of entities you want to skip before getting entities you want.
  --pglimit: int # The maximum number of entities you want to get in the response.
]: nothing -> record<users: table<id: int, name: string, email: string, language: string, timezoneId: int, localeId: int, countryId: int, features: record, avatar: string, lastLogin: string, tfaStatus: int, supportEligible: bool, userTeamIds: list, privateSpace: record>, pg: record<last: string, showLast: bool, sortBy: string, sortDir: string, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organizationId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "teamRoleId" $teamRoleId "scalar") (serialize-qp "organizationRoleId" $organizationRoleId "scalar") (serialize-qp "filterByTeamId" $filterByTeamId "scalar") (serialize-qp "ids" $ids "multi") (serialize-qp "tfaStatus" $tfaStatus "scalar") (serialize-qp "cols[]" $cols "multi") (serialize-qp "pg[sortBy]" $pgsortBy "scalar") (serialize-qp "pg[sortDir]" $pgsortDir "scalar") (serialize-qp "pg[offset]" $pgoffset "scalar") (serialize-qp "pg[limit]" $pglimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete current user
#
# DELETE /users
export def "users delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deleteConnections: string@bool-completer # Whether to delete all user connections (accounts, webhooks, etc). (default: false)
  --currentPassword: string # User's current password (required if user has a password set).
  --tfaCode: string # Two-factor authentication code (required if 2FA is enabled).
]: any -> record<user: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let body = {deleteConnections: $deleteConnections, currentPassword: $currentPassword, tfaCode: $tfaCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update user
#
# PATCH /users/{userId}
export def "users patch" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the user. The name must be at most 250 characters long and does not need to be unique. The name may contain only letters, numbers, spaces, and the following special characters: `'`, `-`, `.`, `(`, `)`, `*`, `+`, `,`, `@`, `_`, `/`. The name must not start or end with a space.
  --language: string # The standardized language code. It sets the Make environment language.
  --timezoneId: int # The timezone ID corresponding to the local time. The list of all timezones can be retrieved from the `GET /enums/timezones` endpoint.
  --localeId: int # The location ID. It sets the Make environment date formats, hour formats, decimal separators, etc. The list of all locales can be retrieved from the `GET /enums/locales` endpoint.
  --countryId: int # The country ID. It sets the region of use.
]: any -> record<user: record<id: int, name: string, email: string, language: string, timezoneId: int, localeId: int, countryId: int, features: record<allow_apps: bool>, avatar: string, lastLogin: string, tfaStatus: int, supportEligible: bool, userTeamIds: list<int>, privateSpace: record<id: int, name: string, globalAgentsEnabled: bool, type: string, operationsLimit: int, transferLimit: any, consumedOperations: int, consumedTransfer: any, isPaused: bool, consumedCenticredits: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)")
  let body = {name: $name, language: $language, timezoneId: $timezoneId, localeId: $localeId, countryId: $countryId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update user email
#
# PUT /users/{userId}/attributes/email
export def "users-attributes-email put" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  currentEmailAddress: string # User's current email address. (format: email)
  newEmailAddress: string # User's new email address. (format: email)
  currentPassword: string # User's current password. (format: password)
]: any -> record<changed: bool, emailSent: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)/attributes/email")
  let body = {currentEmailAddress: $currentEmailAddress, newEmailAddress: $newEmailAddress, currentPassword: $currentPassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update user password
#
# PUT /users/{userId}/attributes/password
export def "users-attributes-password put" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  currentPassword: string # The current user password. (format: password)
  newPassword1: string # The new user password. The password must be at least 9 characters long and must contain at least one uppercase letter, at least one number, and at least one special character. (format: password)
  newPassword2: string # The new user password for confirmation. This password must be the same as the password in the `newPassword1` property. (format: password)
]: any -> record<changed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)/attributes/password")
  let body = {currentPassword: $currentPassword, newPassword1: $newPassword1, newPassword2: $newPassword2} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send password reset demand
#
# POST /users/password-reset-demand
export def "users-password-reset-demand post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email of the user for who the password should be reset. (format: email)
]: any -> record<ok: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/password-reset-demand")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set session for resetting lost password
#
# GET /users/password-reset
export def "users-password-reset get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hash: string # The unique hash of the password reset session. (e.g. fab680b60044adb766128e713e44e15b)
]: nothing -> record<ok: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hash" $hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/password-reset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset lost password
#
# POST /users/password-reset
export def "users-password-reset post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  newPassword1: string # The new user password.
  newPassword2: string # This password must be the same as the password in the `newPassword1` property.
]: any -> record<ok: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/password-reset")
  let body = {newPassword1: $newPassword1, newPassword2: $newPassword2} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Current user data
#
# GET /users/me
export def "users-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeInvitedOrg: string@bool-completer # Set this parameter to `true` if you want to get also the user roles in organizations with pending invitation. The default value is `false`.
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
]: nothing -> record<authUser: record<id: int, name: string, email: string, language: string, timezoneId: int, localeId: int, countryId: int, features: record<allow_apps: bool>, avatar: string, lastLogin: string, tfaStatus: int, supportEligible: bool, userTeamIds: list<int>, privateSpace: record<id: int, name: string, globalAgentsEnabled: bool, type: string, operationsLimit: int, transferLimit: any, consumedOperations: int, consumedTransfer: any, isPaused: bool, consumedCenticredits: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeInvitedOrg" $includeInvitedOrg "scalar") (serialize-qp "cols" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/users/me" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Current user authorization
#
# GET /users/me/current-authorization
export def "users-me-current-authorization get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<authorization: record<scope: list<string>, authUsed: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/current-authorization")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get onboarding survey status
#
# GET /users/me/onboarding-survey
export def "users-me-onboarding-survey get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pending: bool, response: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/onboarding-survey")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit onboarding survey
#
# POST /users/me/onboarding-survey
# --team_invite shape: {emails?: list, sso?: list}
export def "users-me-onboarding-survey post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  survey_type: string # The type of survey being submitted (e.g., `self_serve`, `enterprise`).
  schema_version: float # Version of the survey schema. Allows consumers to interpret the answers.
  answers: record # The user's answers to the survey questions, keyed by question name.
  --preferred-apps: list # Optional list of native app package names to pin for the user. Apps that do not exist are reported as failed without blocking the submission.
  --team-invite: record # Optional team members to invite during onboarding. Invites are best-effort and do not block the submission. — shape: {emails?: list, sso?: list}
]: any -> record<success: bool, result: record<ok: float>, pinnedApps: table<app: string, success: bool, error: string>, invitedUsers: table<email: string, success: bool, error: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/onboarding-survey")
  let body = {survey_type: $survey_type, schema_version: $schema_version, answers: $answers, preferred_apps: $preferred_apps, team_invite: $team_invite} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# User Organization invitations
#
# GET /users/me/organization-invitations
export def "users-me-organization-invitations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<userOrganizationInvitations: table<hash: string, invitation: string, usersRoleId: int, organizationId: int, organizationName: string, zone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/organization-invitations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List users API tokens
#
# GET /users/me/api-tokens
export def "users-me-api-tokens get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<apiTokens: table<token: string, scope: list, created: string, label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/api-tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new API token
#
# POST /users/me/api-tokens
export def "users-me-api-tokens post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  label: string # The API token label visible in the Make user profile.
  scope: list # The API scopes provided to the API token. The API scopes determine the scope of operations that you can do with the API token.  Check the list of all existing Make API scopes with the API call `GET /enums/user-api-tokes-scopes`.
]: any -> record<apiToken: record<token: string, scope: list<string>, created: string, label: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/api-tokens")
  let body = {label: $label, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List OAuth connections
#
# GET /users/me/oauth-connections
export def "users-me-oauth-connections get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<connections: table<id: int, clientName: string, lastUsedAt: string, scopes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/oauth-connections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete OAuth connection
#
# DELETE /users/me/oauth-connections/{clientId}
export def "users-me-oauth-connections delete" [
  clientId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<client: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/me/oauth-connections/($clientId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete API token
#
# DELETE /users/me/api-tokens/{timestamp}
export def "users-me-api-tokens delete" [
  timestamp: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<apiToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/me/api-tokens/($timestamp)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user roles
#
# GET /users/{userId}/user-team-roles
export def "users-user-team-roles list" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<userTeamRoles: table<usersRoleId: int, userId: int, teamId: int, changeable: bool, ssoPending: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)/user-team-roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user team role detail
#
# GET /users/{userId}/user-team-roles/{teamId}
export def "users-user-team-roles get" [
  userId: string
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<userTeamRole: record<usersRoleId: int, userId: int, teamId: int, changeable: bool, ssoPending: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)/user-team-roles/($teamId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user role
#
# POST /users/{userId}/user-team-roles/{teamId}
export def "users-user-team-roles post" [
  userId: int
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --usersRoleId: int # The ID of the user role. Check the `GET /users/roles` API call for the available `usersRoleId` values.
]: any -> record<userTeamRole: record<usersRoleId: int, userId: int, teamId: int, changeable: bool, ssoPending: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)/user-team-roles/($teamId)")
  let body = {usersRoleId: $usersRoleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List user team notification settings
#
# GET /users/{userId}/user-team-notifications/{teamId}
export def "users-user-team-notifications list" [
  userId: int
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<userTeamNotifications: table<userId: int, teamId: int, notificationId: int, enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)/user-team-notifications/($teamId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check user's notification settings
#
# GET /users/{userId}/user-team-notifications/{teamId}/{notificationId}
export def "users-user-team-notifications get" [
  userId: int
  teamId: int
  notificationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<userTeamNotification: record<userId: int, teamId: int, notificationId: int, enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)/user-team-notifications/($teamId)/($notificationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user's notification settings
#
# PUT /users/{userId}/user-team-notifications/{teamId}/{notificationId}
export def "users-user-team-notifications put" [
  userId: string
  teamId: string
  notificationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Enables or disables team notification type for the user.
]: any -> record<userTeamNotification: record<userId: int, teamId: int, notificationId: int, enabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)/user-team-notifications/($teamId)/($notificationId)")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List users by permission
#
# GET /users/by-permission
export def "users-by-permission get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-5 # Whether to filter by an organization-level or team-level (company) permission. When `organization`, supply `organizationId`. When `company`, supply `teamId`.  (e.g. organization)
  --permission: string # The permission string to filter by. Must be a valid permission for the given `type`. For example `organization users view` (organization type) or `team view` (company type).  (e.g. organization users view)
  --organizationId: int # Required when `type` is `organization`. The organization to scope the query to. (e.g. 1)
  --teamId: int # Required when `type` is `company`. The team to scope the query to. (e.g. 2)
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
]: nothing -> record<users: table<id: int, name: string, email: string, privateSpaceId: int, language: string, timezoneId: int, localeId: int, countryId: int, avatar: string, lastLogin: string, invitationStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "permission" $permission "scalar") (serialize-qp "organizationId" $organizationId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "cols" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/users/by-permission" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a custom role
#
# POST /users/custom-roles
export def "users-custom-roles post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the custom role. (e.g. Custom Viewer)
  permissionType: string@permissionType-completer # Whether the role applies to the organization or a team. (e.g. organization)
  organizationId: int # The ID of the organization to create the custom role in. (e.g. 1)
  --description: string # An optional description of the custom role. (nullable, e.g. Read-only access to organization resources.)
  --permissions: list # List of permission IDs to assign to the custom role. (e.g. [101, 102])
]: any -> record<role: record<id: int, name: string, category: string, managementType: string, description: string, permissions: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/custom-roles")
  let body = {name: $name, permissionType: $permissionType, organizationId: $organizationId, description: $description, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a custom role
#
# PATCH /users/custom-roles
export def "users-custom-roles patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: int # The ID of the custom role to update. (e.g. 42)
  organizationId: int # The ID of the organization the custom role belongs to. (e.g. 1)
  --name: string # New name for the custom role. (e.g. Updated Viewer)
  --description: string # New description for the custom role. Pass `null` to clear it. (nullable, e.g. Updated description.)
  --permissions: list # Full list of permission IDs to assign to the role. Replaces existing permissions. (e.g. [101])
]: any -> record<role: record<id: int, name: string, category: string, managementType: string, description: string, permissions: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/custom-roles")
  let body = {id: $id, organizationId: $organizationId, name: $name, description: $description, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a custom role
#
# DELETE /users/custom-roles
export def "users-custom-roles delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: int # The ID of the custom role to delete. (e.g. 42)
  organizationId: int # The ID of the organization the custom role belongs to. (e.g. 1)
]: any -> record<roleId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/custom-roles")
  let body = {id: $id, organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# User role definitions
#
# GET /users/roles
export def "users-roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
  --category: string@category-completer-1 # Set this parameter to `organization` or `team` to get user roles in an organization or in a team. (e.g. team)
  --organizationId: int # Include custom roles belonging to this organization. Cannot be used together with `teamId`. If the organization does not have the `customRoles` license, custom roles are silently excluded from the response. (e.g. 1)
  --teamId: int # Include custom roles belonging to the organization that owns this team. Cannot be used together with `organizationId`. If the organization does not have the `customRoles` license, custom roles are silently excluded from the response. (e.g. 1)
  --roleId: int # Filter the response to a single role by its ID. (e.g. 42)
  --excludeRole: list # Exclude roles with these IDs from the response. (e.g. [1, 3])
]: nothing -> record<usersRoles: table<id: int, name: string, identifier: string, subsidiary: bool, category: string, permissions: list, managementType: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols" $cols "multi") (serialize-qp "category" $category "scalar") (serialize-qp "organizationId" $organizationId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "roleId" $roleId "scalar") (serialize-qp "excludeRole[]" $excludeRole "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/users/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get role detail
#
# GET /users/roles/{roleId}
export def "users-roles get" [
  roleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<usersRole: record<id: int, name: string, identifier: string, category: string, subsidiary: bool, managementType: string, description: string, organizationId: int, permissions: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# User role permission definitions
#
# GET /users/roles/permissions
export def "users-roles-permissions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --roleCategory: string@roleCategory-completer # Filter permissions by role category. Use `team` for team role permissions or `organization` for organization role permissions. (e.g. team)
]: nothing -> record<usersRolesPermissions: table<id: int, name: string, note: string, category: string, roleCategory: string, label: string, customRolesHidden: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "roleCategory" $roleCategory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/roles/permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user roles in an organization
#
# GET /users/{userId}/user-organization-roles
export def "users-user-organization-roles list" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
]: nothing -> record<userOrganizationRoles: table<userId: int, organizationId: int, usersRoleId: int, invitation: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)/user-organization-roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user organization role details
#
# GET /users/{userId}/user-organization-roles/{organizationId}
export def "users-user-organization-roles get" [
  userId: string
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
]: nothing -> record<userOrganizationRole: record<userId: int, organizationId: int, usersRoleId: int, invitation: string, organizationTeamsCount: int, joinedTeamsCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols" $cols "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)/user-organization-roles/($organizationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user role
#
# POST /users/{userId}/user-organization-roles/{organizationId}
export def "users-user-organization-roles post" [
  userId: int
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cols: list # Specifies columns that are returned in the response. Use the `cols[]` parameter for every column that you want to return in the response. For example `GET /endpoint?cols[]=key1&cols[]=key2` to get both `key1` and `key2` columns in the response.  [Check the "Filtering" section for a full example.](/api-documentation/pagination-sorting-filtering/filtering)
  --confirmed: string@bool-completer # Use this parameter when you are removing a user from an organization. Set this parameter to `true` is you want to delete the user's connections from the organization with the parameter `deleteConnections`.
  --deleteConnections: string@bool-completer # Set this parameter to `true` if you are removing a user from an organization to delete also the user's connections. If you set this parameter to `false`, the API call won't delete the user's connections.
  --usersRoleId: int # The ID of the user role. Check the `GET /users/roles` API call for the available `usersRoleId` values.
]: any -> record<userOrganizationRole: record<userId: int, organizationId: int, usersRoleId: int, invitation: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cols" $cols "multi") (serialize-qp "confirmed" $confirmed "scalar") (serialize-qp "deleteConnections" $deleteConnections "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)/user-organization-roles/($organizationId)" $qp)
  let body = {usersRoleId: $usersRoleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Transfer organization ownership
#
# POST /users/{userId}/user-organization-roles/{organizationId}/transfer
export def "users-user-organization-roles-transfer post" [
  userId: int
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<userOrganizationRoles: table<userId: int, organizationId: int, usersRoleId: int, invitation: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)/user-organization-roles/($organizationId)/transfer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unread notifications
#
# GET /users/unread-notifications
export def "users-unread-notifications get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<userUnreadNotifications: int, userZoneUnreadNotifications: table<zoneId: int, unreadNotifications: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/unread-notifications")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user redirect action
#
# GET /users/redirect-action
export def "users-redirect-action get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orgId: int # e.g. 1
]: nothing -> record<redirect: string, redirectAction: record<action: string, data: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgId" $orgId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/redirect-action" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the UI settings of the user.
#
# POST /users/set-ui-settings
export def "users-set-ui-settings post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  uiSettings: record # The diff of the new UI settings.
]: any -> record<ok: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/set-ui-settings")
  let body = {uiSettings: $uiSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get preferences
#
# GET /mailhub/users/{userId}/preferences
export def "mailhub-users-preferences get" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<preferences: record<id: int, uuid: string, email: string, is_email_verified: bool, global: record<isEmailVerified: bool, preferences: list>, zones: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mailhub/users/($userId)/preferences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update global preferences
#
# PATCH /mailhub/users/{userId}/preferences
export def "mailhub-users-preferences patch" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string
  --enabled: string@bool-completer
]: any -> record<preferences: record<global: record<preferences: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mailhub/users/($userId)/preferences")
  let body = {id: $id, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get team preferences
#
# GET /mailhub/users/{userId}/organizations/{organizationId}/teams/{teamId}/preferences
export def "mailhub-users-organizations-teams-preferences get" [
  userId: string
  organizationId: string
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, uuid: string, email: string, is_email_verified: bool, team: record<teamId: int, teamName: string, preferences: record<native: list, marketing: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mailhub/users/($userId)/organizations/($organizationId)/teams/($teamId)/preferences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update team preferences
#
# PATCH /mailhub/users/{userId}/organizations/{organizationId}/teams/{teamId}/preferences
export def "mailhub-users-organizations-teams-preferences patch" [
  userId: string
  organizationId: string
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string
  --enabled: string@bool-completer
]: any -> record<team: record<preferences: record<id: string, enabled: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mailhub/users/($userId)/organizations/($organizationId)/teams/($teamId)/preferences")
  let body = {id: $id, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update team native preferences
#
# PATCH /mailhub/users/{userId}/organizations/{organizationId}/teams/{teamId}/native-preferences
export def "mailhub-users-organizations-teams-native-preferences patch" [
  userId: string
  organizationId: string
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # format: utc-millisec
  --enabled: string@bool-completer
]: any -> record<team: record<preferences: record<id: string, enabled: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mailhub/users/($userId)/organizations/($organizationId)/teams/($teamId)/native-preferences")
  let body = {id: $id, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get config of current zone
#
# GET /debug/hq/zone
export def "debug-hq-zone get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<state: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/debug/hq/zone")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get sanity check
#
# GET /hq/sanity-check
export def "hq-sanity-check get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<userSessionExpiresAt: string, authUser: record<id: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hq/sanity-check")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get LLM Usage Statistics
#
# GET /llm-usage/{organizationId}
export def "llm-usage get" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<usedInputTokens: int, usedOutputTokens: int, remainingInputTokens: int, remainingOutputTokens: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/llm-usage/($organizationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get consumption list
#
# GET /consumptions/reports/{organizationId}/{teamId}?
export def "consumptions-reports get" [
  organizationId: any
  teamId: any
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
  let full_url = (build-url $base $"/consumptions/reports/($organizationId)/($teamId)?")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List outbound webhooks for an organization
#
# GET /outbound-webhooks/organizations/{organizationId}/webhooks
export def "outbound-webhooks-organizations-webhooks list" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of webhooks to return. (default: 20)
  --offset: int # Number of webhooks to skip for pagination. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/outbound-webhooks/organizations/($organizationId)/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an outbound webhook
#
# POST /outbound-webhooks/organizations/{organizationId}/webhooks
export def "outbound-webhooks-organizations-webhooks post" [
  organizationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Human-readable name of the webhook.
  --body-url: string # HTTPS URL that will receive webhook deliveries. (format: uri)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/outbound-webhooks/organizations/($organizationId)/webhooks")
  let body = {name: $name, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an outbound webhook
#
# GET /outbound-webhooks/organizations/{organizationId}/webhooks/{webhookId}
export def "outbound-webhooks-organizations-webhooks get" [
  organizationId: int
  webhookId: string
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
  let full_url = (build-url $base $"/outbound-webhooks/organizations/($organizationId)/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an outbound webhook
#
# PATCH /outbound-webhooks/organizations/{organizationId}/webhooks/{webhookId}
export def "outbound-webhooks-organizations-webhooks patch" [
  organizationId: int
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Human-readable name of the webhook.
  --body-url: string # HTTPS URL that will receive webhook deliveries. (format: uri)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/outbound-webhooks/organizations/($organizationId)/webhooks/($webhookId)")
  let body = {name: $name, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an outbound webhook
#
# DELETE /outbound-webhooks/organizations/{organizationId}/webhooks/{webhookId}
export def "outbound-webhooks-organizations-webhooks delete" [
  organizationId: int
  webhookId: string
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
  let full_url = (build-url $base $"/outbound-webhooks/organizations/($organizationId)/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Activate an outbound webhook
#
# PATCH /outbound-webhooks/organizations/{organizationId}/webhooks/{webhookId}/activate
export def "outbound-webhooks-organizations-webhooks-activate patch" [
  organizationId: int
  webhookId: string
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
  let full_url = (build-url $base $"/outbound-webhooks/organizations/($organizationId)/webhooks/($webhookId)/activate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deactivate an outbound webhook
#
# PATCH /outbound-webhooks/organizations/{organizationId}/webhooks/{webhookId}/deactivate
export def "outbound-webhooks-organizations-webhooks-deactivate patch" [
  organizationId: int
  webhookId: string
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
  let full_url = (build-url $base $"/outbound-webhooks/organizations/($organizationId)/webhooks/($webhookId)/deactivate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
