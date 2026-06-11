# Auto-generated client for ISAM v3.5
# Source: https://api.apps.us.bluescape.com/v3/openapi.json
# Auth: --token flag or $env.ISAM_TOKEN

const BASE_URL = "http://localhost/api/v3"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ISAM_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "cookie-idToken" => { {headers: {Cookie: $"idToken=($token_val)"}, query: ""} }
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
def base-url-completer [] { ["http://localhost/api/v3"] }
def auth-scheme-completer [] { ["bearer" "cookie-idToken"] }

# Completers for enum parameters
def type-completer [] { ["adfs" "cac" "f5" "okta" "onelogin" "pingfederate"] }
def copyCollaborators-completer [] { ["all" "owner"] }
def type-completer-1 [] { ["admin" "guest" "user"] }
def resourceType-completer [] { ["organization" "workspace"] }
def status-completer [] { ["ACTIVE" "INACTIVE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "users list" } } | get name | first)
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

# List users
#
# GET /users
# operationId: UserController_getAllUsers
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageSize: float # Maximum number of results to return in a single page. (e.g. 25)
  --includeCount: string@bool-completer # When `true`, the response includes the total number of matching items in `totalItems`. This may add query overhead. (e.g. false)
  --omitPrevCursor: string@bool-completer # When `true`, the response omits the previous-page cursor by returning `prev` as `null`. Use this when paging forward only to reduce query overhead. (default: false, e.g. false)
  --filterBy: string # Supported fields: firstName,lastName,email,avatarUrl,lastLoggedInAt,invitationStatus,searchText (e.g. lastName eq 'admin')
  --orderBy: string # Supported fields: firstName,lastName,email,lastLoggedInAt. Supported orders: asc,desc. (e.g. firstName asc)
  --cursor: string # e.g. jSlTIsVnUjRhbVQotSou.lBHvkfp-Rqiwdub8UM
]: nothing -> record<prev: string, next: string, totalItems: float, users: table<id: string, email: string, firstName: string, lastName: string, avatarUrl: string, isArchived: bool, createdAt: string, updatedAt: string, lastLoggedInAt: string, invitationStatus: string, emailVerifiedAt: string, isScimManaged: bool, isScimActive: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "includeCount" $includeCount "scalar") (serialize-qp "omitPrevCursor" $omitPrevCursor "scalar") (serialize-qp "filterBy" $filterBy "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the current user
#
# GET /users/me
# operationId: UserController_getSessionUser
export def "users-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, email: string, firstName: string, lastName: string, avatarUrl: string, isArchived: bool, createdAt: string, updatedAt: string, lastLoggedInAt: string, invitationStatus: string, emailVerifiedAt: string, isScimManaged: bool, isScimActive: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the current user
#
# PATCH /users/me
# operationId: UserController_patchCurrentUser
export def "users-me patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --firstName: string # e.g. John
  --lastName: string # e.g. Kwon
  --email: string # e.g. instance@bluescape.com
]: any -> record<id: string, email: string, firstName: string, lastName: string, avatarUrl: string, isArchived: bool, createdAt: string, updatedAt: string, lastLoggedInAt: string, invitationStatus: string, emailVerifiedAt: string, isScimManaged: bool, isScimActive: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me")
  let body = {firstName: $firstName, lastName: $lastName, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a user
#
# GET /users/{userId}
# operationId: UserController_getUser
export def "users get" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, email: string, firstName: string, lastName: string, avatarUrl: string, isArchived: bool, createdAt: string, updatedAt: string, lastLoggedInAt: string, invitationStatus: string, emailVerifiedAt: string, isScimManaged: bool, isScimActive: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a user
#
# DELETE /users/{userId}
# operationId: UserController_deleteUser
export def "users delete" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permanent: string@bool-completer
  --newWorkspaceOwnerId: string # All workspaces owned by 'userId' will be re-assigned to this user.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permanent" $permanent "scalar") (serialize-qp "newWorkspaceOwnerId" $newWorkspaceOwnerId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user
#
# PATCH /users/{userId}
# operationId: UserController_patchUser
export def "users patch" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --firstName: string # e.g. John
  --lastName: string # e.g. Kwon
  --email: string # e.g. instance@bluescape.com
]: any -> record<id: string, email: string, firstName: string, lastName: string, avatarUrl: string, isArchived: bool, createdAt: string, updatedAt: string, lastLoggedInAt: string, invitationStatus: string, emailVerifiedAt: string, isScimManaged: bool, isScimActive: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)")
  let body = {firstName: $firstName, lastName: $lastName, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get current user application role
#
# GET /users/me/role
# operationId: UserController_getCurrentUserApplicationRole
export def "users-me-role get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, type: string, resourceType: string, organizationId: string, isCustom: bool, permissions: list<string>, category: string, level: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/role")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user application role
#
# GET /users/{userId}/role
# operationId: UserController_getUserApplicationRole
export def "users-role get" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, type: string, resourceType: string, organizationId: string, isCustom: bool, permissions: list<string>, category: string, level: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)/role")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user application role
#
# PUT /users/{userId}/role
# operationId: UserController_updateUserApplicationRole
export def "users-role updateUserApplicationRole" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationRoleId: string # Id of user's application role (e.g. 6NbsqVRv7WiYEgfudedw)
]: any -> record<id: string, email: string, firstName: string, lastName: string, avatarUrl: string, isArchived: bool, createdAt: string, updatedAt: string, lastLoggedInAt: string, invitationStatus: string, emailVerifiedAt: string, isScimManaged: bool, isScimActive: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)/role")
  let body = {applicationRoleId: $applicationRoleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the current user avatar
#
# PUT /users/me/avatar
# operationId: UserAvatarMeController_updateAvatar
export def "users-me-avatar updateAvatar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  avatar: string # format: binary
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/avatar")
  let body = {avatar: $avatar} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete the current user avatar
#
# DELETE /users/me/avatar
# operationId: UserAvatarMeController_deleteAvatar
export def "users-me-avatar delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/avatar")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user avatar URL
#
# GET /users/{userId}/avatar
# operationId: UserAvatarUserIdController_getAvatar
export def "users-avatar get" [
  userId: string
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
  let full_url = (build-url $base $"/users/($userId)/avatar")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the current user's favorite workspaces
#
# GET /users/me/favorites/workspaces
# operationId: UserFavoritesController_getUserFavoriteWorkspaces
export def "users-me-favorites-workspaces get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageSize: float # Maximum number of results to return in a single page. (e.g. 25)
  --includeCount: string@bool-completer # When `true`, the response includes the total number of matching items in `totalItems`. This may add query overhead. (e.g. false)
  --omitPrevCursor: string@bool-completer # When `true`, the response omits the previous-page cursor by returning `prev` as `null`. Use this when paging forward only to reduce query overhead. (default: false, e.g. false)
  --filterBy: string # Supported fields: id,createdAt,isPublic,name,updatedAt,organizationId (e.g. name eq 'My favorite workspace')
  --orderBy: string # Supported fields: workspace.name,workspace.description,workspace.createdAt,workspace.updatedAt. Supported orders: asc,desc. (e.g. workspace.name asc)
  --cursor: string # e.g. jSlTIsVnUjRhbVQotSou.lBHvkfp-Rqiwdub8UM
]: nothing -> record<prev: string, next: string, totalItems: float, workspaces: table<id: string, name: string, description: string, isPublic: bool, defaultRoleId: string, organizationId: string, contentUpdatedAt: string, ownerId: string, classification: string, version: string, createdAt: string, updatedAt: string, archivedAt: string, storageUsed: float, pendingReassignmentFrom: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "includeCount" $includeCount "scalar") (serialize-qp "omitPrevCursor" $omitPrevCursor "scalar") (serialize-qp "filterBy" $filterBy "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/me/favorites/workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Favorite a workspace
#
# PUT /users/me/favorites/workspaces/{workspaceId}
# operationId: UserFavoritesController_addFavoriteWorkspace
export def "users-me-favorites-workspaces addFavoriteWorkspace" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/me/favorites/workspaces/($workspaceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a Favourite workspace
#
# DELETE /users/me/favorites/workspaces/{workspaceId}
# operationId: UserFavoritesController_deleteFavoriteWorkspace
export def "users-me-favorites-workspaces delete" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/me/favorites/workspaces/($workspaceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the current user's organizations
#
# GET /users/me/organizations
# operationId: UserOrganizationsMeController_getSessionUserOrganizations
export def "users-me-organizations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageSize: float # Maximum number of results to return in a single page. (e.g. 25)
  --includeCount: string@bool-completer # When `true`, the response includes the total number of matching items in `totalItems`. This may add query overhead. (e.g. false)
  --omitPrevCursor: string@bool-completer # When `true`, the response omits the previous-page cursor by returning `prev` as `null`. Use this when paging forward only to reduce query overhead. (default: false, e.g. false)
  --filterBy: string # Supported fields: name,secondaryName,mode,canHaveGuests,isGuestInviteApprovalRequired,isCustomRolesEnabled (e.g. name eq 'Billy Jean')
  --orderBy: string # Supported fields: name,mode,updatedAt,createdAt. Supported orders: asc,desc. (e.g. name asc)
  --cursor: string # e.g. jSlTIsVnUjRhbVQotSou.lBHvkfp-Rqiwdub8UM
]: nothing -> record<prev: string, next: string, totalItems: float, organizations: table<id: string, name: string, secondaryName: string, isGuestInviteApprovalRequired: bool, canHaveGuests: bool, defaultPublicWorkspaceRoleId: string, defaultOrganizationUserRoleId: string, isCustomRolesEnabled: bool, hasCamConfig: bool, isCamEnabled: bool, denyOnNoCamData: bool, autoAssociateIdentityProviderUser: bool, accountId: string, ownerId: string, mfaEnabled: bool, updatedAt: string, createdAt: string, storageUsed: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "includeCount" $includeCount "scalar") (serialize-qp "omitPrevCursor" $omitPrevCursor "scalar") (serialize-qp "filterBy" $filterBy "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/me/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a user's organizations
#
# GET /users/{userId}/organizations
# operationId: UserOrganizationsController_getUserOrganizations
export def "users-organizations get" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageSize: float # Maximum number of results to return in a single page. (e.g. 25)
  --includeCount: string@bool-completer # When `true`, the response includes the total number of matching items in `totalItems`. This may add query overhead. (e.g. false)
  --omitPrevCursor: string@bool-completer # When `true`, the response omits the previous-page cursor by returning `prev` as `null`. Use this when paging forward only to reduce query overhead. (default: false, e.g. false)
  --filterBy: string # Supported fields: name,secondaryName,mode,canHaveGuests,isGuestInviteApprovalRequired,isCustomRolesEnabled (e.g. name eq 'Billy Jean')
  --orderBy: string # Supported fields: name,mode,updatedAt,createdAt. Supported orders: asc,desc. (e.g. name asc)
  --cursor: string # e.g. jSlTIsVnUjRhbVQotSou.lBHvkfp-Rqiwdub8UM
]: nothing -> record<prev: string, next: string, totalItems: float, organizations: table<id: string, name: string, secondaryName: string, isGuestInviteApprovalRequired: bool, canHaveGuests: bool, defaultPublicWorkspaceRoleId: string, defaultOrganizationUserRoleId: string, isCustomRolesEnabled: bool, hasCamConfig: bool, isCamEnabled: bool, denyOnNoCamData: bool, autoAssociateIdentityProviderUser: bool, accountId: string, ownerId: string, mfaEnabled: bool, updatedAt: string, createdAt: string, storageUsed: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "includeCount" $includeCount "scalar") (serialize-qp "omitPrevCursor" $omitPrevCursor "scalar") (serialize-qp "filterBy" $filterBy "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the current user's workspaces
#
# GET /users/me/workspaces
# operationId: UserWorkspacesMeController_getSessionUserWorkspaces
export def "users-me-workspaces get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageSize: float # Maximum number of results to return in a single page. (e.g. 25)
  --includeCount: string@bool-completer # When `true`, the response includes the total number of matching items in `totalItems`. This may add query overhead. (e.g. false)
  --omitPrevCursor: string@bool-completer # When `true`, the response omits the previous-page cursor by returning `prev` as `null`. Use this when paging forward only to reduce query overhead. (default: false, e.g. false)
  --filterBy: string # Supported fields: organizationId,ownedBy,isPublic,createdAt,updatedAt,name,associatedWorkspaces,isFavorite,ownerId,isPendingReassignment,isPendingReassignmentFrom,includeArchived (e.g. name contains "test")
  --orderBy: string # Supported fields: name,contentUpdatedAt,updatedAt,createdAt,isFavorite. Supported orders: asc,desc. (e.g. name asc)
  --cursor: string # e.g. jSlTIsVnUjRhbVQotSou.lBHvkfp-Rqiwdub8UM
]: nothing -> record<prev: string, next: string, totalItems: float, workspaces: table<id: string, name: string, description: string, isPublic: bool, defaultRoleId: string, organizationId: string, contentUpdatedAt: string, ownerId: string, classification: string, version: string, createdAt: string, updatedAt: string, archivedAt: string, storageUsed: float, pendingReassignmentFrom: string, isFavorite: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "includeCount" $includeCount "scalar") (serialize-qp "omitPrevCursor" $omitPrevCursor "scalar") (serialize-qp "filterBy" $filterBy "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/me/workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a user's workspaces
#
# GET /users/{userId}/workspaces
# operationId: UserWorkspacesUserIdController_getUserWorkspaces
export def "users-workspaces get" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageSize: float # Maximum number of results to return in a single page. (e.g. 25)
  --includeCount: string@bool-completer # When `true`, the response includes the total number of matching items in `totalItems`. This may add query overhead. (e.g. false)
  --omitPrevCursor: string@bool-completer # When `true`, the response omits the previous-page cursor by returning `prev` as `null`. Use this when paging forward only to reduce query overhead. (default: false, e.g. false)
  --filterBy: string # Supported fields: organizationId,ownedBy,isPublic,createdAt,updatedAt,name,associatedWorkspaces,isFavorite,ownerId,includeArchived (e.g. name contains "test")
  --orderBy: string # Supported fields: name,contentUpdatedAt,updatedAt,createdAt,isFavorite. Supported orders: asc,desc. (e.g. name asc)
  --cursor: string # e.g. jSlTIsVnUjRhbVQotSou.lBHvkfp-Rqiwdub8UM
]: nothing -> record<prev: string, next: string, totalItems: float, workspaces: table<id: string, name: string, description: string, isPublic: bool, defaultRoleId: string, organizationId: string, contentUpdatedAt: string, ownerId: string, classification: string, version: string, createdAt: string, updatedAt: string, archivedAt: string, storageUsed: float, pendingReassignmentFrom: string, isFavorite: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "includeCount" $includeCount "scalar") (serialize-qp "omitPrevCursor" $omitPrevCursor "scalar") (serialize-qp "filterBy" $filterBy "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($userId)/workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the current user's groups
#
# GET /users/me/groups
# operationId: UserGroupsController_getUserGroups
export def "users-me-groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageSize: float # Maximum number of results to return in a single page. (e.g. 25)
  --includeCount: string@bool-completer # When `true`, the response includes the total number of matching items in `totalItems`. This may add query overhead. (e.g. false)
  --omitPrevCursor: string@bool-completer # When `true`, the response omits the previous-page cursor by returning `prev` as `null`. Use this when paging forward only to reduce query overhead. (default: false, e.g. false)
  --filterBy: string # Supported fields: organizationId,name,type,description (e.g. name eq 'Billy Jean')
  --orderBy: string # Supported fields: name,createdAt,updatedAt. Supported orders: asc,desc. (e.g. name asc)
  --cursor: string # e.g. jSlTIsVnUjRhbVQotSou.lBHvkfp-Rqiwdub8UM
]: nothing -> record<prev: string, next: string, totalItems: float, groups: table<id: string, name: string, type: string, bluescapeGroupJoinType: string, description: string, organizationId: string, organizationIds: list, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "includeCount" $includeCount "scalar") (serialize-qp "omitPrevCursor" $omitPrevCursor "scalar") (serialize-qp "filterBy" $filterBy "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/me/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organizations
#
# GET /organizations
# operationId: OrganizationController_getOrganizations
export def "organizations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageSize: float # Maximum number of results to return in a single page. (e.g. 25)
  --includeCount: string@bool-completer # When `true`, the response includes the total number of matching items in `totalItems`. This may add query overhead. (e.g. false)
  --omitPrevCursor: string@bool-completer # When `true`, the response omits the previous-page cursor by returning `prev` as `null`. Use this when paging forward only to reduce query overhead. (default: false, e.g. false)
  --filterBy: string # Supported fields: canHaveGuests,isCustomRolesEnabled,isGuestInviteApprovalRequired,name,secondaryName,mode (e.g. canHaveGuests eq true)
  --orderBy: string # Supported fields: name,secondaryName,mode,createdAt,updatedAt. Supported orders: asc,desc. (e.g. name asc)
  --cursor: string # e.g. jSlTIsVnUjRhbVQotSou.lBHvkfp-Rqiwdub8UM
]: nothing -> record<prev: string, next: string, totalItems: float, organizations: table<id: string, name: string, secondaryName: string, isGuestInviteApprovalRequired: bool, canHaveGuests: bool, defaultPublicWorkspaceRoleId: string, defaultOrganizationUserRoleId: string, isCustomRolesEnabled: bool, hasCamConfig: bool, isCamEnabled: bool, denyOnNoCamData: bool, autoAssociateIdentityProviderUser: bool, accountId: string, ownerId: string, mfaEnabled: bool, updatedAt: string, createdAt: string, storageUsed: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "includeCount" $includeCount "scalar") (serialize-qp "omitPrevCursor" $omitPrevCursor "scalar") (serialize-qp "filterBy" $filterBy "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an organization member
#
# DELETE /organizations/{organizationId}/members/{memberId}
# operationId: OrganizationController_deleteOrganizationMember
export def "organizations-members delete" [
  organizationId: string
  memberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --newWorkspaceOwnerId: string # All workspaces owned by 'memberId' will be re-assigned to this user.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "newWorkspaceOwnerId" $newWorkspaceOwnerId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/members/($memberId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organization members
#
# GET /organizations/{organizationId}/members
# operationId: OrganizationController_getMembers
export def "organizations-members get" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageSize: float # Maximum number of results to return in a single page. (e.g. 25)
  --includeCount: string@bool-completer # When `true`, the response includes the total number of matching items in `totalItems`. This may add query overhead. (e.g. false)
  --omitPrevCursor: string@bool-completer # When `true`, the response omits the previous-page cursor by returning `prev` as `null`. Use this when paging forward only to reduce query overhead. (default: false, e.g. false)
  --filterBy: string # Supported fields: user.id,user.email,user.firstName,user.lastName,user.avatarUrl,group.id,group.name,group.description,group.type,group.bluescapeGroupJoinType,role.id,role.name,role.description,role.type,role.resourceType,role.isCustom,user.invitationStatus,user.searchText (e.g. name eq 'Billy Jean')
  --orderBy: string # Supported fields: user.email,user.firstName,group.name,group.description,role.name,licenseLevel. Supported orders: asc,desc. (e.g. user.email asc)
  --cursor: string # e.g. jSlTIsVnUjRhbVQotSou.lBHvkfp-Rqiwdub8UM
]: nothing -> record<prev: string, next: string, totalItems: float, members: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "includeCount" $includeCount "scalar") (serialize-qp "omitPrevCursor" $omitPrevCursor "scalar") (serialize-qp "filterBy" $filterBy "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an organization member
#
# POST /organizations/{organizationId}/members
# operationId: OrganizationAddMemberController_addMember
export def "organizations-members addMember" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # The Id of the user or group to be added to this organization (e.g. i6QcPYZwG6IH252MUfAn)
  --organizationRoleId: string # The Id of the role the user or group will have in the organization (e.g. 6NbsqVRv7WiYEgfudedw)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/members")
  let body = {id: $id, organizationRoleId: $organizationRoleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an organization
#
# GET /organizations/{organizationId}
# operationId: OrganizationController_getOrganizationById
export def "organizations get" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, secondaryName: string, isGuestInviteApprovalRequired: bool, canHaveGuests: bool, defaultPublicWorkspaceRoleId: string, defaultOrganizationUserRoleId: string, isCustomRolesEnabled: bool, hasCamConfig: bool, isCamEnabled: bool, denyOnNoCamData: bool, autoAssociateIdentityProviderUser: bool, accountId: string, ownerId: string, mfaEnabled: bool, updatedAt: string, createdAt: string, storageUsed: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an organization
#
# DELETE /organizations/{organizationId}
# operationId: OrganizationController_deleteOrganization
export def "organizations delete" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isPermanentDelete: string@bool-completer # When <i>isPermanentDelete</i> is true,<br />     * A request to Collab to Delete Workspaces of the Organization is initiated.<br />     * The Organization and its relationships are Hard Deleted.<br />     When <i>isPermanentDelete</i> is false,<br />     * Users who belong to only this organization are archived.<br />     * User Organization relationship is Soft deleted.<br />     * Organization is Soft Deleted.<br />     * When <i>isPermanentDelete</i> parameter is not provided, it will be treated as false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isPermanentDelete" $isPermanentDelete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an organization
#
# PATCH /organizations/{organizationId}
# operationId: OrganizationController_patchOrganization
export def "organizations patch" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the organization or company. It must be unique (e.g. My organization)
  --secondaryName: string # The name of the team or organizational unit (nullable, e.g. Team A)
  --isGuestInviteApprovalRequired: string@bool-completer # True if the organization admin is required to approve the invitation of a guest (e.g. false)
  --canHaveGuests: string@bool-completer # True if guests are allowed to be added as workspace collaborators (e.g. false)
  --defaultPublicWorkspaceRoleId: string # The Id of the role to apply when a user accesses a public workspace, but has no role specified for that workspace
  --defaultOrganizationUserRoleId: string # The Id of the role to apply when a user is added to an organization, but has no role has been assigned
  --isCustomRolesEnabled: string@bool-completer # True if custom roles are enabled (e.g. false)
  --autoAssociateIdentityProviderUser: string@bool-completer # True if sso users are auto-associated to the organization (e.g. true)
  --ownerId: string # The id of the member who will own this organization
  --mfaEnabled: string@bool-completer # Enable/disable Multi-factor authentication for the organization
]: any -> record<id: string, name: string, secondaryName: string, isGuestInviteApprovalRequired: bool, canHaveGuests: bool, defaultPublicWorkspaceRoleId: string, defaultOrganizationUserRoleId: string, isCustomRolesEnabled: bool, hasCamConfig: bool, isCamEnabled: bool, denyOnNoCamData: bool, autoAssociateIdentityProviderUser: bool, accountId: string, ownerId: string, mfaEnabled: bool, updatedAt: string, createdAt: string, storageUsed: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)")
  let body = {name: $name, secondaryName: $secondaryName, isGuestInviteApprovalRequired: $isGuestInviteApprovalRequired, canHaveGuests: $canHaveGuests, defaultPublicWorkspaceRoleId: $defaultPublicWorkspaceRoleId, defaultOrganizationUserRoleId: $defaultOrganizationUserRoleId, isCustomRolesEnabled: $isCustomRolesEnabled, autoAssociateIdentityProviderUser: $autoAssociateIdentityProviderUser, ownerId: $ownerId, mfaEnabled: $mfaEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete organization visitors
#
# DELETE /organizations/{organizationId}/removeGuests
# operationId: OrganizationController_deleteOrganizationGuests
export def "organizations-remove-guests delete" [
  organizationId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/removeGuests")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an organization identity provider
#
# GET /organizations/{organizationId}/identityProvider
# operationId: OrganizationController_getOrganizationIdentityProvider
export def "organizations-identity-provider get" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, type: string, adminEmail: string, metadataUrl: string, primaryOrgId: string, userGuidAttributeName: string, isSamlSpSloEnabled: bool, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/identityProvider")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an organization member's role
#
# PATCH /organizations/{organizationId}/members/{memberId}/role
# operationId: OrganizationController_updateMemberRole
export def "organizations-members-role updateMemberRole" [
  organizationId: string
  memberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --newWorkspaceOwnerId: string # When changing an organization member to be a "visitor", sets the workspaces owned by that member to a new workspace owner.
  organizationRoleId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "newWorkspaceOwnerId" $newWorkspaceOwnerId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/members/($memberId)/role" $qp)
  let body = {organizationRoleId: $organizationRoleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an organization avatar
#
# PUT /organizations/{organizationId}/avatar
# operationId: OrganizationController_updateAvatar
export def "organizations-avatar updateAvatar" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  avatar: string # format: binary
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/avatar")
  let body = {avatar: $avatar} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get an organization avatar URL
#
# GET /organizations/{organizationId}/avatar
# operationId: OrganizationController_getOrganizationAvatar
export def "organizations-avatar get" [
  organizationId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/avatar")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an organization avatar
#
# DELETE /organizations/{organizationId}/avatar
# operationId: OrganizationController_deleteOrganizationAvatar
export def "organizations-avatar delete" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/avatar")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List identity providers
#
# GET /identityProviders
# operationId: IdentityProviderController_getIDPs
export def "identity-providers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  --redirectUrl: string
  --name: string
  --pageSize: float # Maximum number of results to return in a single page. (e.g. 25)
  --includeCount: string@bool-completer # When `true`, the response includes the total number of matching items in `totalItems`. This may add query overhead. (e.g. false)
  --omitPrevCursor: string@bool-completer # When `true`, the response omits the previous-page cursor by returning `prev` as `null`. Use this when paging forward only to reduce query overhead. (default: false, e.g. false)
  --filterBy: string # Supported fields: adminEmail,createdAt,metadataUrl,name,type,updatedAt (e.g. adminEmail eq "admin@test.com" )
  --orderBy: string # Supported fields: name,type,createdAt,updatedAt. Supported orders: asc,desc. (e.g. name asc)
  --cursor: string # e.g. jSlTIsVnUjRhbVQotSou.lBHvkfp-Rqiwdub8UM
]: nothing -> record<prev: string, next: string, totalItems: float, identityProviders: table<id: string, name: string, type: string, adminEmail: string, metadataUrl: string, primaryOrgId: string, userGuidAttributeName: string, isSamlSpSloEnabled: bool, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "redirectUrl" $redirectUrl "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "includeCount" $includeCount "scalar") (serialize-qp "omitPrevCursor" $omitPrevCursor "scalar") (serialize-qp "filterBy" $filterBy "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/identityProviders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an identity provider
#
# POST /identityProviders
# operationId: IdentityProviderController_createIDP
export def "identity-providers createIDP" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # e.g. My IDP
  type: string@type-completer # e.g. okta
  --adminEmail: string # Email address of the identity provider administrator. (default: default@test.com, e.g. admin@example.com)
  --metadataUrl: string # URL of the SAML metadata document. Required when the identity provider type uses SAML. (e.g. https://dev-175540.myidp.com/app/exknw03rmmGKP3slF0h7/sso/saml/metadata)
  --userGuidAttributeName: string # Name of the SAML assertion attribute that contains the user GUID.
  --isSamlSpSloEnabled: string@bool-completer # Whether SP-initiated SAML single logout is enabled. Defaults to `false`.
]: any -> record<id: string, name: string, type: string, adminEmail: string, metadataUrl: string, primaryOrgId: string, userGuidAttributeName: string, isSamlSpSloEnabled: bool, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/identityProviders")
  let body = {name: $name, type: $type, adminEmail: $adminEmail, metadataUrl: $metadataUrl, userGuidAttributeName: $userGuidAttributeName, isSamlSpSloEnabled: $isSamlSpSloEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an identity provider
#
# GET /identityProviders/{identityProviderId}
# operationId: IdentityProviderController_getIDP
export def "identity-providers get" [
  identityProviderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, type: string, adminEmail: string, metadataUrl: string, primaryOrgId: string, userGuidAttributeName: string, isSamlSpSloEnabled: bool, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/identityProviders/($identityProviderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an identity provider
#
# DELETE /identityProviders/{identityProviderId}
# operationId: IdentityProviderController_deleteIDP
export def "identity-providers delete" [
  identityProviderId: string
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
  let full_url = (build-url $base $"/identityProviders/($identityProviderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an identity provider
#
# PATCH /identityProviders/{identityProviderId}
# operationId: IdentityProviderController_updateIDP
export def "identity-providers updateIDP" [
  identityProviderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # e.g. My IDP
  --type: string@type-completer # e.g. okta
  --adminEmail: string # Email address of the identity provider administrator. (e.g. admin@example.com)
  --metadataUrl: string # URL of the SAML metadata document. (e.g. https://dev-175540.myidp.com/app/exknw03rmmGKP3slF0h7/sso/saml/metadata)
  --userGuidAttributeName: string # Name of the SAML assertion attribute that contains the user GUID. Use `null` to clear the value.
  --isSamlSpSloEnabled: string@bool-completer # Whether SP-initiated SAML single logout is enabled.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/identityProviders/($identityProviderId)")
  let body = {name: $name, type: $type, adminEmail: $adminEmail, metadataUrl: $metadataUrl, userGuidAttributeName: $userGuidAttributeName, isSamlSpSloEnabled: $isSamlSpSloEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List organizations for an identity provider
#
# GET /identityProviders/{identityProviderId}/organizations
# operationId: IdentityProviderController_getIDPOrganizations
export def "identity-providers-organizations get" [
  identityProviderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageSize: float # Maximum number of results to return in a single page. (e.g. 25)
  --includeCount: string@bool-completer # When `true`, the response includes the total number of matching items in `totalItems`. This may add query overhead. (e.g. false)
  --omitPrevCursor: string@bool-completer # When `true`, the response omits the previous-page cursor by returning `prev` as `null`. Use this when paging forward only to reduce query overhead. (default: false, e.g. false)
  --filterBy: string # Supported fields: autoAssociateIdentityProviderUser,canHaveGuests,isCustomRolesEnabled,isGuestInviteApprovalRequired,name,mode (e.g. name eq 'Billy Jean')
  --orderBy: string # Supported fields: mode. Supported orders: asc,desc. (e.g. mode asc)
  --cursor: string # e.g. jSlTIsVnUjRhbVQotSou.lBHvkfp-Rqiwdub8UM
]: nothing -> record<prev: string, next: string, totalItems: float, organizations: table<id: string, name: string, secondaryName: string, isGuestInviteApprovalRequired: bool, canHaveGuests: bool, defaultPublicWorkspaceRoleId: string, defaultOrganizationUserRoleId: string, isCustomRolesEnabled: bool, hasCamConfig: bool, isCamEnabled: bool, denyOnNoCamData: bool, autoAssociateIdentityProviderUser: bool, accountId: string, ownerId: string, mfaEnabled: bool, updatedAt: string, createdAt: string, storageUsed: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "includeCount" $includeCount "scalar") (serialize-qp "omitPrevCursor" $omitPrevCursor "scalar") (serialize-qp "filterBy" $filterBy "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/identityProviders/($identityProviderId)/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a workspace
#
# POST /workspaces
# operationId: WorkspaceController_createWorkspace
export def "workspaces createWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --copyFrom: string # <i>copyFrom</i> is the Workspace Id from which a copy of the Workspace is created.<br/>     A Duplicate Workspace Request to Collab will be initiated. (e.g. Fj4DvpLXFKNdhsPeu1jW)
  --when: string # <h3>Beta</h3>     <i>when</i> is a time in the past. If the new workspace is a copy of another workspace, only the history up to this time will be copied.<br/>     A Rollback Workspace Request to Collab will be initiated.     <p>This is a Beta feature that is still in development, the documentation and features are subject to change before their GA release. We welcome any feedback you may have that we can use to improve the final version. While we will do our best to communicate breaking changes, think careful about where you deploy integrations using them.</p> (format: date-time, e.g. 2021-07-28T00:09:30.104Z)
  --copyCollaborators: string@copyCollaborators-completer # If the value is <b>owner<b> only the owner will be copied, if the value is <b>all</b> all the collborators in the workspace will be copied.
  --name: string # e.g. Workspace 1
  --description: string # e.g. Description of the workspace
  --isPublic: string@bool-completer # true: this workspace can be accessed by any member of the organization, false: this workspace can only be accessed by the workspace's collaborators (e.g. true)
  --defaultRoleId: string # The default workspace role for a public workspace (e.g. 6NbsqVRv7WiYEgfudedw)
  organizationId: string # The id of the organization this workspace will belong to (e.g. i6QcPYZwG6IH252MUfAn)
  --ownerId: string # The id of the member who will own this workspace (e.g. 6NbsqVRv7WiYEgfudedw)
]: any -> record<id: string, name: string, description: string, isPublic: bool, defaultRoleId: string, organizationId: string, contentUpdatedAt: string, ownerId: string, classification: string, version: string, createdAt: string, updatedAt: string, archivedAt: string, storageUsed: float, pendingReassignmentFrom: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "copyFrom" $copyFrom "scalar") (serialize-qp "when" $when "scalar") (serialize-qp "copyCollaborators" $copyCollaborators "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workspaces" $qp)
  let body = {name: $name, description: $description, isPublic: $isPublic, defaultRoleId: $defaultRoleId, organizationId: $organizationId, ownerId: $ownerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a workspace
#
# GET /workspaces/{workspaceId}
# operationId: WorkspaceController_getWorkspace
export def "workspaces get" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeArchived: string@bool-completer # Whether to return archived workspace (Default is false).
]: nothing -> record<id: string, name: string, description: string, isPublic: bool, defaultRoleId: string, organizationId: string, contentUpdatedAt: string, ownerId: string, classification: string, version: string, createdAt: string, updatedAt: string, archivedAt: string, storageUsed: float, pendingReassignmentFrom: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeArchived" $includeArchived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspaceId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a workspace
#
# PATCH /workspaces/{workspaceId}
# operationId: WorkspaceController_patchWorkspace
export def "workspaces patch" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # e.g. Workspace 1
  --description: string # e.g. Description of the workspace
  --isPublic: string@bool-completer # true: this workspace can be accessed by any member of the organization, false: this workspace can only be accessed by the workspace's collaborators (e.g. true)
  --defaultRoleId: string # The default workspace role for a public workspace (e.g. 6NbsqVRv7WiYEgfudedw)
]: any -> record<id: string, name: string, description: string, isPublic: bool, defaultRoleId: string, organizationId: string, contentUpdatedAt: string, ownerId: string, classification: string, version: string, createdAt: string, updatedAt: string, archivedAt: string, storageUsed: float, pendingReassignmentFrom: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspaceId)")
  let body = {name: $name, description: $description, isPublic: $isPublic, defaultRoleId: $defaultRoleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a workspace
#
# DELETE /workspaces/{workspaceId}
# operationId: WorkspaceController_deleteWorkspace
export def "workspaces delete" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isPermanentDelete: string@bool-completer # e.g. true
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspaceId)")
  let body = {isPermanentDelete: $isPermanentDelete} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a workspace collaborator
#
# POST /workspaces/{workspaceId}/collaborators
# operationId: WorkspaceController_addCollaboratorToWorkspace
export def "workspaces-collaborators addCollaboratorToWorkspace" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # The Id of the User or Group to be added to this workspace (e.g. i6QcPYZwG6IH252MUfAn)
  workspaceRoleId: string # The Id of the role the User or Group will have in the workspace (e.g. i6QcPYZwG6IH252MUfAn)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspaceId)/collaborators")
  let body = {id: $id, workspaceRoleId: $workspaceRoleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List workspace collaborators
#
# GET /workspaces/{workspaceId}/collaborators
# operationId: WorkspaceController_getWorkspaceCollaborators
export def "workspaces-collaborators get" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageSize: float # Maximum number of results to return in a single page. (e.g. 25)
  --includeCount: string@bool-completer # When `true`, the response includes the total number of matching items in `totalItems`. This may add query overhead. (e.g. false)
  --omitPrevCursor: string@bool-completer # When `true`, the response omits the previous-page cursor by returning `prev` as `null`. Use this when paging forward only to reduce query overhead. (default: false, e.g. false)
  --filterBy: string # Supported fields: user.id,user.email,user.firstName,user.lastName,user.avatarUrl,user.searchText,group.id,group.name,group.description,group.type,group.bluescapeGroupJoinType,role.id,role.name,role.description,role.type,role.resourceType,role.isCustom (e.g. role.id eq 'gQ2DA6mMC4Op-_EHuR6S')
  --orderBy: string # Supported fields: user.email,group.name,group.description,role.name. Supported orders: asc,desc. (e.g. user.email asc)
  --cursor: string # e.g. jSlTIsVnUjRhbVQotSou.lBHvkfp-Rqiwdub8UM
]: nothing -> record<prev: string, next: string, totalItems: float, collaborators: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "includeCount" $includeCount "scalar") (serialize-qp "omitPrevCursor" $omitPrevCursor "scalar") (serialize-qp "filterBy" $filterBy "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspaceId)/collaborators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unarchive a workspace
#
# PATCH /workspaces/{workspaceId}/unarchive
# operationId: WorkspaceController_unarchiveWorkspace
export def "workspaces-unarchive unarchiveWorkspace" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, isPublic: bool, defaultRoleId: string, organizationId: string, contentUpdatedAt: string, ownerId: string, classification: string, version: string, createdAt: string, updatedAt: string, archivedAt: string, storageUsed: float, pendingReassignmentFrom: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspaceId)/unarchive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a collaborator from a workspace
#
# DELETE /workspaces/{workspaceId}/collaborators/{collaboratorId}
# operationId: WorkspaceController_deleteWorkspaceCollaborator
export def "workspaces-collaborators delete" [
  workspaceId: string
  collaboratorId: string
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
  let full_url = (build-url $base $"/workspaces/($workspaceId)/collaborators/($collaboratorId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a workspace collaborator's role
#
# PATCH /workspaces/{workspaceId}/collaborators/{collaboratorId}/role
# operationId: WorkspaceController_updateCollaborator
export def "workspaces-collaborators-role updateCollaborator" [
  workspaceId: string
  collaboratorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspaceRoleId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspaceId)/collaborators/($collaboratorId)/role")
  let body = {workspaceRoleId: $workspaceRoleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mute a workspace access request
#
# PATCH /workspaces/{workspaceId}/accessRequests/{requestId}/muteAccessRequest
# operationId: WorkspaceController_muteWorkspaceAccessRequest
export def "workspaces-access-requests-mute-access-request muteWorkspaceAccessRequest" [
  workspaceId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, user: record<id: string, email: string, firstName: string, lastName: string, avatarUrl: string, isArchived: bool, createdAt: string, updatedAt: string, lastLoggedInAt: string, invitationStatus: string, emailVerifiedAt: string, isScimManaged: bool, isScimActive: bool>, requestedWorkspaceRoleLevel: string, anonymousUser: record<id: string, email: string, displayName: string, createdAt: string, updatedAt: string>, status: string, requestedAt: string, createdAt: string, updatedAt: string, expiredAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspaceId)/accessRequests/($requestId)/muteAccessRequest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept a workspace access request
#
# POST /workspaces/{workspaceId}/accessRequests/{requestId}/acceptAccessRequest
# operationId: WorkspaceController_acceptWorkspaceAccessRequest
export def "workspaces-access-requests-accept-access-request acceptWorkspaceAccessRequest" [
  workspaceId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, user: record<id: string, email: string, firstName: string, lastName: string, avatarUrl: string, isArchived: bool, createdAt: string, updatedAt: string, lastLoggedInAt: string, invitationStatus: string, emailVerifiedAt: string, isScimManaged: bool, isScimActive: bool>, requestedWorkspaceRoleLevel: string, anonymousUser: record<id: string, email: string, displayName: string, createdAt: string, updatedAt: string>, status: string, requestedAt: string, createdAt: string, updatedAt: string, expiredAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspaceId)/accessRequests/($requestId)/acceptAccessRequest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List roles
#
# GET /roles
# operationId: RoleController_getAllRoles
export def "roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageSize: float # Maximum number of results to return in a single page. (e.g. 25)
  --includeCount: string@bool-completer # When `true`, the response includes the total number of matching items in `totalItems`. This may add query overhead. (e.g. false)
  --omitPrevCursor: string@bool-completer # When `true`, the response omits the previous-page cursor by returning `prev` as `null`. Use this when paging forward only to reduce query overhead. (default: false, e.g. false)
  --filterBy: string # Supported fields: name,resourceType,type,isCustom,category,level,organizationId (e.g. name contains "Viewer")
  --orderBy: string # Supported fields: name,type,isCustom. Supported orders: asc,desc. (e.g. name asc)
  --cursor: string # e.g. jSlTIsVnUjRhbVQotSou.lBHvkfp-Rqiwdub8UM
]: nothing -> record<prev: string, next: string, totalItems: float, roles: table<id: string, name: string, description: string, type: string, resourceType: string, organizationId: string, isCustom: bool, permissions: list, category: string, level: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "includeCount" $includeCount "scalar") (serialize-qp "omitPrevCursor" $omitPrevCursor "scalar") (serialize-qp "filterBy" $filterBy "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a custom organization or workspace role
#
# POST /roles
# operationId: RoleController_createRole
export def "roles createRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # e.g. Editor
  --description: string # e.g. Editor can view workspace settings, can view, comment and edit workspaces content, and can view collaborators.
  type: string@type-completer-1 # e.g. user
  resourceType: string@resourceType-completer # e.g. workspace
  organizationId: string # Id of organization that this role belongs to (e.g. i6QcPYZwG6IH252MUfAn)
  --permissionGroupIds: list # All permission groups listed must have the **same** resourceType as the role. (e.g. [Fj4DvpLXFKNdhsPeu1jW])
]: any -> record<id: string, name: string, description: string, type: string, resourceType: string, organizationId: string, isCustom: bool, permissions: list<string>, category: string, level: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles")
  let body = {name: $name, description: $description, type: $type, resourceType: $resourceType, organizationId: $organizationId, permissionGroupIds: $permissionGroupIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a role
#
# GET /roles/{roleId}
# operationId: RoleController_getRoleById
export def "roles get" [
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, type: string, resourceType: string, organizationId: string, isCustom: bool, permissions: list<string>, category: string, level: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a custom organization or workspace role
#
# PATCH /roles/{roleId}
# operationId: RoleController_updateRole
export def "roles updateRole" [
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # e.g. Editor
  --description: string # e.g. Editor can view workspace settings, can view, comment and edit workspaces content, and can view collaborators.
  --type: string@type-completer-1 # e.g. user
  --permissionGroupIds: list # All permission groups listed must have the **same** resourceType as the role. (e.g. [Fj4DvpLXFKNdhsPeu1jW])
]: any -> record<id: string, name: string, description: string, type: string, resourceType: string, organizationId: string, isCustom: bool, permissions: list<string>, category: string, level: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/roles/($roleId)")
  let body = {name: $name, description: $description, type: $type, permissionGroupIds: $permissionGroupIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a custom organization or workspace role
#
# DELETE /roles/{roleId}
# operationId: RoleController_deleteRole
export def "roles delete" [
  roleId: string
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
  let full_url = (build-url $base $"/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a scratch workspace
#
# POST /scratchWorkspaces
# operationId: ScratchWorkspaceController_createScratchWorkspace
export def "scratch-workspaces createScratchWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Scratch workspace name
]: any -> record<id: string, name: string, email: string, actorId: string, createdAt: string, updatedAt: string, storageUsed: float, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scratchWorkspaces")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List scratch workspaces
#
# GET /scratchWorkspaces
# operationId: ScratchWorkspaceController_getScratchWorkspaces
export def "scratch-workspaces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageSize: float # Maximum number of results to return in a single page. (e.g. 25)
  --includeCount: string@bool-completer # When `true`, the response includes the total number of matching items in `totalItems`. This may add query overhead. (e.g. false)
  --omitPrevCursor: string@bool-completer # When `true`, the response omits the previous-page cursor by returning `prev` as `null`. Use this when paging forward only to reduce query overhead. (default: false, e.g. false)
  --orderBy: string # Supported fields: name,updatedAt. Supported orders: asc,desc. (e.g. name asc)
  --cursor: string # e.g. jSlTIsVnUjRhbVQotSou.lBHvkfp-Rqiwdub8UM
]: nothing -> record<prev: string, next: string, totalItems: float, scratchWorkspaces: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "includeCount" $includeCount "scalar") (serialize-qp "omitPrevCursor" $omitPrevCursor "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scratchWorkspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a scratch workspace
#
# PATCH /scratchWorkspaces/{scratchWorkspaceId}
# operationId: ScratchWorkspaceController_updateScratchWorkspace
export def "scratch-workspaces updateScratchWorkspace" [
  scratchWorkspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Scratch workspace name
  email: string # Email of user workspace belongs to (e.g. email@company.com)
]: any -> record<id: string, name: string, email: string, actorId: string, createdAt: string, updatedAt: string, storageUsed: float, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scratchWorkspaces/($scratchWorkspaceId)")
  let body = {name: $name, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a scratch workspace
#
# DELETE /scratchWorkspaces/{scratchWorkspaceId}
# operationId: ScratchWorkspaceController_deleteScratchWorkspace
export def "scratch-workspaces delete" [
  scratchWorkspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isPermanentDelete: string@bool-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isPermanentDelete" $isPermanentDelete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scratchWorkspaces/($scratchWorkspaceId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a scratch workspace
#
# GET /scratchWorkspaces/{scratchWorkspaceId}
# operationId: ScratchWorkspaceController_getScratchWorkspaceById
export def "scratch-workspaces get" [
  scratchWorkspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, email: string, actorId: string, createdAt: string, updatedAt: string, storageUsed: float, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scratchWorkspaces/($scratchWorkspaceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Claim scratch workspace
#
# POST /scratchWorkspaces/{scratchWorkspaceId}/claim
# operationId: ScratchWorkspaceController_claimScratchWorkspace
export def "scratch-workspaces-claim claimScratchWorkspace" [
  scratchWorkspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # Organization to associate the scratch workspace with (e.g. i6QcPYZwG6IH252MUfAn)
]: any -> record<id: string, name: string, description: string, isPublic: bool, defaultRoleId: string, organizationId: string, contentUpdatedAt: string, ownerId: string, classification: string, version: string, createdAt: string, updatedAt: string, archivedAt: string, storageUsed: float, pendingReassignmentFrom: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scratchWorkspaces/($scratchWorkspaceId)/claim")
  let body = {organizationId: $organizationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Claim scratch workspace using claim code
#
# POST /scratchWorkspaces/claimByCode
# operationId: ScratchWorkspaceController_claimScratchWorkspaceByCode
export def "scratch-workspaces-claim-by-code claimScratchWorkspaceByCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationId: string # Organization to associate the scratch workspace with (e.g. i6QcPYZwG6IH252MUfAn)
  claimCode: string # Code to claim scratch workspace, it will be four words long and alphabetically sorted
]: any -> record<id: string, name: string, description: string, isPublic: bool, defaultRoleId: string, organizationId: string, contentUpdatedAt: string, ownerId: string, classification: string, version: string, createdAt: string, updatedAt: string, archivedAt: string, storageUsed: float, pendingReassignmentFrom: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scratchWorkspaces/claimByCode")
  let body = {organizationId: $organizationId, claimCode: $claimCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a scratch-workspace claim code
#
# POST /scratchWorkspaces/{scratchWorkspaceId}/generateClaimCode
# operationId: ScratchWorkspaceController_generateClaimCode
export def "scratch-workspaces-generate-claim-code generateClaimCode" [
  scratchWorkspaceId: string
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
  let full_url = (build-url $base $"/scratchWorkspaces/($scratchWorkspaceId)/generateClaimCode")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download an admin job asset
#
# GET /adminJobs/{adminJobId}/asset
# operationId: AdminJobController_downloadAdminJobAssetById
export def "admin-jobs-asset downloadAdminJobAssetById" [
  adminJobId: string
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
  let full_url = (build-url $base $"/adminJobs/($adminJobId)/asset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a webhook
#
# GET /webhooks/{webhookId}
# operationId: WebhookController_getWebhook
export def "webhooks get" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, workspaceId: string, creatorId: string, elementId: string, elementType: list<string>, callbackUrl: string, callbackSigningKey: string, status: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PATCH /webhooks/{webhookId}
# operationId: WebhookController_patchWebhook
export def "webhooks patch" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --elementId: string # Optional workspace element Id filter. If set, it takes precedence over `elementType`. (e.g. afc3c59195db38927995b15d)
  --elementType: list # Optional list of workspace element types to receive events for. (e.g. [Canvas, Document, Text])
  --callbackUrl: string # URL that will receive webhook callbacks, each with a workspace event payload. (e.g. https://example.org/webhook)
  --callbackSigningKey: string # Optional secret used to sign webhook callbacks in the 'webhook-signature' header. Use a random value that is not reused elsewhere.
  --status: string@status-completer # Webhook status. Only webhooks with `ACTIVE` status receive callbacks. (e.g. ACTIVE)
]: any -> record<id: string, workspaceId: string, creatorId: string, elementId: string, elementType: list<string>, callbackUrl: string, callbackSigningKey: string, status: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhookId)")
  let body = {elementId: $elementId, elementType: $elementType, callbackUrl: $callbackUrl, callbackSigningKey: $callbackSigningKey, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace a webhook
#
# PUT /webhooks/{webhookId}
# operationId: WebhookController_putWebhook
export def "webhooks put" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --elementId: string # Optional workspace element Id filter. If set, it takes precedence over `elementType`. (e.g. afc3c59195db38927995b15d)
  --elementType: list # Optional list of workspace element types to receive events for. (e.g. [Canvas, Document, Text])
  callbackUrl: string # URL that will receive webhook callbacks, each with a workspace event payload. (e.g. https://example.org/webhook)
  --callbackSigningKey: string # Optional secret used to sign webhook callbacks in the 'webhook-signature' header. Use a random value that is not reused elsewhere.
  --status: string@status-completer # Webhook status. Only webhooks with `ACTIVE` status receive callbacks. (e.g. ACTIVE)
]: any -> record<id: string, workspaceId: string, creatorId: string, elementId: string, elementType: list<string>, callbackUrl: string, callbackSigningKey: string, status: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhookId)")
  let body = {elementId: $elementId, elementType: $elementType, callbackUrl: $callbackUrl, callbackSigningKey: $callbackSigningKey, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a webhook
#
# DELETE /webhooks/{webhookId}
# operationId: WebhookController_deleteWebhook
export def "webhooks delete" [
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
  let full_url = (build-url $base $"/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a webhook
#
# POST /webhooks/workspace/{workspaceId}
# operationId: WebhookController_createWebhook
export def "webhooks-workspace createWebhook" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --elementId: string # Optional workspace element Id filter. If set, it takes precedence over `elementType`. (e.g. afc3c59195db38927995b15d)
  --elementType: list # Optional list of workspace element types to receive events for. (e.g. [Canvas, Document, Text])
  callbackUrl: string # URL that will receive webhook callbacks, each with a workspace event payload. (e.g. https://example.org/webhook)
  --callbackSigningKey: string # Optional secret used to sign webhook callbacks in the 'webhook-signature' header. Use a random value that is not reused elsewhere.
  --status: string@status-completer # Webhook status. Only webhooks with `ACTIVE` status receive callbacks. (e.g. ACTIVE)
]: any -> record<id: string, workspaceId: string, creatorId: string, elementId: string, elementType: list<string>, callbackUrl: string, callbackSigningKey: string, status: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/workspace/($workspaceId)")
  let body = {elementId: $elementId, elementType: $elementType, callbackUrl: $callbackUrl, callbackSigningKey: $callbackSigningKey, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List workspace webhooks
#
# GET /webhooks/workspace/{workspaceId}
# operationId: WebhookController_getWorkspaceWebhooks
export def "webhooks-workspace get" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageSize: float # Maximum number of results to return in a single page. (e.g. 25)
  --includeCount: string@bool-completer # When `true`, the response includes the total number of matching items in `totalItems`. This may add query overhead. (e.g. false)
  --omitPrevCursor: string@bool-completer # When `true`, the response omits the previous-page cursor by returning `prev` as `null`. Use this when paging forward only to reduce query overhead. (default: false, e.g. false)
  --filterBy: string # Supported fields: callbackUrl,status,createdAt,updatedAt (e.g. status eq 'ACTIVE')
  --orderBy: string # Supported fields: callbackUrl,updatedAt,createdAt. Supported orders: asc,desc. (e.g. callbackUrl asc)
  --cursor: string # e.g. jSlTIsVnUjRhbVQotSou.lBHvkfp-Rqiwdub8UM
]: nothing -> record<prev: string, next: string, totalItems: float, webhooks: table<id: string, workspaceId: string, creatorId: string, elementId: string, elementType: list, callbackUrl: string, callbackSigningKey: string, status: string, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "includeCount" $includeCount "scalar") (serialize-qp "omitPrevCursor" $omitPrevCursor "scalar") (serialize-qp "filterBy" $filterBy "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/workspace/($workspaceId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
