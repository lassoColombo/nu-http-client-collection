# Auto-generated client for Bitbucket Data Center v10.3
# Source: https://dac-static.atlassian.com/server/bitbucket/10.3.swagger.v3.json
# Auth: --token flag or $env.BITBUCKET_DATA_CENTER_TOKEN

const BASE_URL = "http://example.com:7990/rest"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BITBUCKET_DATA_CENTER_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["http://example.com:7990/rest"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def state-completer [] { ["CANCELLED" "FAILED" "INPROGRESS" "SUCCESSFUL" "UNKNOWN"] }
def strictness-completer [] { ["DEFAULT" "REPORT_ONLY" "STRICT"] }
def type-completer [] { ["ANNOTATED" "LIGHTWEIGHT"] }
def mode-completer [] { ["ALL_PROJECTS" "SELECTED_PROJECTS"] }
def action-completer [] { ["DISCARD" "MERGE" "REBASE"] }
def type-completer-1 [] { ["SYNCHRONIZATION_FAILED" "SYNCHRONIZED"] }
def includeDefaultBranch-completer [] { ["false" "true"] }
def state-completer-1 [] { ["ACCEPTED" "PENDING" "REJECTED"] }
def mirrorType-completer [] { ["FARM" "SINGLE"] }
def permission-completer [] { ["ADMIN" "PROJECT_ADMIN" "REPO_ADMIN" "SYS_ADMIN"] }
def matcherType-completer [] { ["BRANCH" "MODEL_BRANCH" "MODEL_CATEGORY" "PATTERN"] }
def type-completer-2 [] { ["fast-forward-only" "no-creates" "no-deletes" "pull-request-only" "read-only"] }
def idp-type-completer [] { ["CROWD" "GENERIC"] }
def name-id-policy-completer [] { ["EMAIL_ADDRESS" "ENCRYPTED" "ENTITY" "KERBEROS" "NONE" "PERSISTENT" "TRANSIENT" "UNSPECIFIED" "WINDOWS_DOMAIN_QUALIFIED_NAME" "X509_SUBJECT_NAME"] }
def signature-algorithm-completer [] { ["RSA_SHA256" "RSA_SHA384" "RSA_SHA512"] }
def sso-type-completer [] { ["NONE" "OIDC" "SAML"] }
def actionType-completer [] { ["unlock-user-2sv-settings"] }
def permission-completer-1 [] { ["ADMIN" "LICENSED_USER" "PROJECT_ADMIN" "PROJECT_CREATE" "PROJECT_READ" "PROJECT_VIEW" "PROJECT_WRITE" "REPO_ADMIN" "REPO_CREATE" "REPO_READ" "REPO_WRITE" "SYS_ADMIN" "USER_ADMIN"] }
def audience-completer [] { ["ALL" "AUTHENTICATED"] }
def state-completer-2 [] { ["AVAILABLE" "DELETING" "DISABLED" "DRAINING" "OFFLINE"] }
def authType-completer [] { ["BASIC" "OAUTH2"] }
def protocol-completer [] { ["SMTP" "SMTPS"] }
def permission-completer-2 [] { ["ADMIN" "LICENSED_USER" "PROJECT_CREATE" "SYS_ADMIN"] }
def order-completer [] { ["FREQUENCY" "NEWEST"] }
def accept-completer [] { ["application/octet-stream" "text/plain;charset=UTF-8"] }
def accept-completer-1 [] { ["application/json" "application/json;charset=UTF-8"] }
def accept-completer-2 [] { ["application/octet-stream" "application/x-tar"] }
def orderBy-completer [] { ["ALPHABETICAL" "MODIFICATION"] }
def permission-completer-3 [] { ["REPO_ADMIN" "REPO_READ" "REPO_WRITE"] }
def state-completer-3 [] { ["DECLINED" "MERGED" "OPEN"] }
def role-completer [] { ["AUTHOR" "PARTICIPANT" "REVIEWER"] }
def status-completer [] { ["APPROVED" "NEEDS_WORK" "UNAPPROVED"] }
def order-completer-1 [] { ["NAME_ASC" "NAME_DESC"] }
def type-completer-3 [] { ["POST_RECEIVE" "PRE_RECEIVE"] }
def restrictionAction-completer [] { ["CREATE" "DELETE" "NONE"] }
def visibility-completer [] { ["private" "public"] }
def state-completer-4 [] { ["AVAILABLE" "INITIALISATION_FAILED" "INITIALISING"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "access-tokens-latest-projects list" } } | get name | first)
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

# Get project HTTP tokens
#
# GET /access-tokens/latest/projects/{projectKey}
# operationId: getAllAccessTokens
export def "access-tokens-latest-projects list" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/access-tokens/latest/projects/($projectKey)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create project HTTP token
#
# PUT /access-tokens/latest/projects/{projectKey}
# operationId: createAccessToken
export def "access-tokens-latest-projects createAccessToken" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiryDays: int # format: int32
  --name: string # e.g. My access token
  permissions: list # e.g. [REPO_ADMIN, PROJECT_READ]
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-tokens/latest/projects/($projectKey)")
  let body = {expiryDays: $expiryDays, name: $name, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get repository HTTP tokens
#
# GET /access-tokens/latest/projects/{projectKey}/repos/{repositorySlug}
# operationId: getAllAccessTokens_1
export def "access-tokens-latest-projects-repos get-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/access-tokens/latest/projects/($projectKey)/repos/($repositorySlug)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create repository HTTP token
#
# PUT /access-tokens/latest/projects/{projectKey}/repos/{repositorySlug}
# operationId: createAccessToken_1
export def "access-tokens-latest-projects-repos createAccessToken-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiryDays: int # format: int32
  --name: string # e.g. My access token
  permissions: list # e.g. [REPO_ADMIN, PROJECT_READ]
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-tokens/latest/projects/($projectKey)/repos/($repositorySlug)")
  let body = {expiryDays: $expiryDays, name: $name, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a HTTP token
#
# DELETE /access-tokens/latest/projects/{projectKey}/repos/{repositorySlug}/{tokenId}
# operationId: deleteById_1
export def "access-tokens-latest-projects-repos delete-by-projectKey-tokenId-repositorySlug" [
  projectKey: string
  tokenId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-tokens/latest/projects/($projectKey)/repos/($repositorySlug)/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get HTTP token by ID
#
# GET /access-tokens/latest/projects/{projectKey}/repos/{repositorySlug}/{tokenId}
# operationId: getById_1
export def "access-tokens-latest-projects-repos get-by-projectKey-tokenId-repositorySlug" [
  projectKey: string
  tokenId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-tokens/latest/projects/($projectKey)/repos/($repositorySlug)/($tokenId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update HTTP token
#
# POST /access-tokens/latest/projects/{projectKey}/repos/{repositorySlug}/{tokenId}
# operationId: updateAccessToken_1
export def "access-tokens-latest-projects-repos updateAccessToken-by-projectKey-tokenId-repositorySlug" [
  projectKey: string
  tokenId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiryDays: int # format: int32
  --name: string # e.g. My access token
  permissions: list # e.g. [REPO_ADMIN, PROJECT_READ]
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-tokens/latest/projects/($projectKey)/repos/($repositorySlug)/($tokenId)")
  let body = {expiryDays: $expiryDays, name: $name, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a HTTP token
#
# DELETE /access-tokens/latest/projects/{projectKey}/{tokenId}
# operationId: deleteById
export def "access-tokens-latest-projects delete" [
  projectKey: string
  tokenId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-tokens/latest/projects/($projectKey)/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get HTTP token by ID
#
# GET /access-tokens/latest/projects/{projectKey}/{tokenId}
# operationId: getById
export def "access-tokens-latest-projects get" [
  projectKey: string
  tokenId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-tokens/latest/projects/($projectKey)/($tokenId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update HTTP token
#
# POST /access-tokens/latest/projects/{projectKey}/{tokenId}
# operationId: updateAccessToken
export def "access-tokens-latest-projects updateAccessToken" [
  projectKey: string
  tokenId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiryDays: int # format: int32
  --name: string # e.g. My access token
  permissions: list # e.g. [REPO_ADMIN, PROJECT_READ]
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-tokens/latest/projects/($projectKey)/($tokenId)")
  let body = {expiryDays: $expiryDays, name: $name, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get personal HTTP tokens
#
# GET /access-tokens/latest/users/{userSlug}
# operationId: getAllAccessTokens_2
export def "access-tokens-latest-users get-by-userSlug" [
  userSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/access-tokens/latest/users/($userSlug)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create personal HTTP token
#
# PUT /access-tokens/latest/users/{userSlug}
# operationId: createAccessToken_2
export def "access-tokens-latest-users createAccessToken-by-userSlug" [
  userSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiryDays: int # format: int32
  --name: string # e.g. My access token
  permissions: list # e.g. [REPO_ADMIN, PROJECT_READ]
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-tokens/latest/users/($userSlug)")
  let body = {expiryDays: $expiryDays, name: $name, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a HTTP token
#
# DELETE /access-tokens/latest/users/{userSlug}/{tokenId}
# operationId: deleteById_2
export def "access-tokens-latest-users delete-by-tokenId-userSlug" [
  tokenId: string
  userSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-tokens/latest/users/($userSlug)/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get HTTP token by ID
#
# GET /access-tokens/latest/users/{userSlug}/{tokenId}
# operationId: getById_2
export def "access-tokens-latest-users get-by-tokenId-userSlug" [
  tokenId: string
  userSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-tokens/latest/users/($userSlug)/($tokenId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update HTTP token
#
# POST /access-tokens/latest/users/{userSlug}/{tokenId}
# operationId: updateAccessToken_2
export def "access-tokens-latest-users updateAccessToken-by-tokenId-userSlug" [
  tokenId: string
  userSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiryDays: int # format: int32
  --name: string # e.g. My access token
  permissions: list # e.g. [REPO_ADMIN, PROJECT_READ]
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-tokens/latest/users/($userSlug)/($tokenId)")
  let body = {expiryDays: $expiryDays, name: $name, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Dismiss retention config notification
#
# DELETE /audit/latest/notification-settings/retention-config-review
# operationId: dismissRetentionConfigReviewNotification
export def "audit-latest-notification-settings-retention-config-review dismissRetentionConfigReviewNotification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/audit/latest/notification-settings/retention-config-review")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete branch
#
# DELETE /branch-utils/latest/projects/{projectKey}/repos/{repositorySlug}/branches
# operationId: deleteBranch
export def "branch-utils-latest-projects-repos-branches delete" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dryRun: oneof<nothing, bool> # Don't actually delete the ref name, just do a dry run
  --endPoint: string # Commit ID that the provided ref name is expected to point to
  --name: string # Name of the ref to be deleted
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/branch-utils/latest/projects/($projectKey)/repos/($repositorySlug)/branches")
  let body = {dryRun: $dryRun, endPoint: $endPoint, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create branch
#
# POST /branch-utils/latest/projects/{projectKey}/repos/{repositorySlug}/branches
# operationId: createBranch
export def "branch-utils-latest-projects-repos-branches createBranch" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the branch to be created
  --startPoint: string # Commit ID from which the branch is created
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/branch-utils/latest/projects/($projectKey)/repos/($repositorySlug)/branches")
  let body = {name: $name, startPoint: $startPoint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get branch
#
# GET /branch-utils/latest/projects/{projectKey}/repos/{repositorySlug}/branches/info/{commitId}
# operationId: findByCommit
export def "branch-utils-latest-projects-repos-branches-info findByCommit" [
  projectKey: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/branch-utils/latest/projects/($projectKey)/repos/($repositorySlug)/branches/info/($commitId)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get build status statistics for multiple commits
#
# POST /build-status/latest/commits/stats
# operationId: getMultipleBuildStatusStats
export def "build-status-latest-commits-stats post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/build-status/latest/commits/stats")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get build status statistics for commit
#
# GET /build-status/latest/commits/stats/{commitId}
# operationId: getBuildStatusStats
export def "build-status-latest-commits-stats get" [
  commitId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeUnique: oneof<nothing, bool> # include a unique build result if there is either only one failed build, only one in-progress build or only one successful build
]: nothing -> record<cancelled: int, failed: int, inProgress: int, successful: int, unknown: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeUnique" $includeUnique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/build-status/latest/commits/stats/($commitId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get build statuses for commit
#
# GET /build-status/latest/commits/{commitId}
# DEPRECATED
# operationId: getBuildStatus
@deprecated
export def "build-status-latest-commits get" [
  commitId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --orderBy: string # How the results should be ordered. Options are NEWEST, OLDEST, STATUS (e.g. newest, oldest, or status)
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> record<isLastPage: bool, limit: float, nextPageStart: int, size: float, start: int, values: table<buildNumber: string, createdDate: int, description: string, duration: int, key: string, name: string, parent: string, projectKey: string, ref: string, repositorySlug: string, state: string, testResults: record, updatedDate: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/build-status/latest/commits/($commitId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create build status for commit
#
# POST /build-status/latest/commits/{commitId}
# DEPRECATED
# operationId: addBuildStatus
# --testResults shape: {failed?: int, skipped?: int, successful?: int}
@deprecated
export def "build-status-latest-commits addBuildStatus" [
  commitId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --buildNumber: string # e.g. 3
  --createdDate: int # format: int64, e.g. 1587533099278
  --description: string # e.g. A description of the build goes here
  --duration: int # format: int64
  --key: string # e.g. TEST-REP3
  --name: string # e.g. Database Matrix Tests
  --parent: string # e.g. TEST-REP
  --projectKey: string # e.g. PRJ
  --ref: string # e.g. refs/heads/master
  --repositorySlug: string # e.g. my-repo
  --state: string@state-completer
  --testResults: record # shape: {failed?: int, skipped?: int, successful?: int}
  --updatedDate: int # format: int64, e.g. 1587533699278
  --body-url: string # e.g. https://bamboo.example.com/browse/TEST-REP3
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/build-status/latest/commits/($commitId)")
  let body = {buildNumber: $buildNumber, createdDate: $createdDate, description: $description, duration: $duration, key: $key, name: $name, parent: $parent, projectKey: $projectKey, ref: $ref, repositorySlug: $repositorySlug, state: $state, testResults: $testResults, updatedDate: $updatedDate, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a required builds merge check
#
# POST /required-builds/latest/projects/{projectKey}/repos/{repositorySlug}/condition
# operationId: createRequiredBuildsMergeCheck
export def "required-builds-latest-projects-repos-condition createRequiredBuildsMergeCheck" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/required-builds/latest/projects/($projectKey)/repos/($repositorySlug)/condition")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $body
}

# Delete a required builds merge check
#
# DELETE /required-builds/latest/projects/{projectKey}/repos/{repositorySlug}/condition/{id}
# operationId: deleteRequiredBuildsMergeCheck
export def "required-builds-latest-projects-repos-condition delete" [
  projectKey: string
  id: int
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/required-builds/latest/projects/($projectKey)/repos/($repositorySlug)/condition/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a required builds merge check
#
# PUT /required-builds/latest/projects/{projectKey}/repos/{repositorySlug}/condition/{id}
# operationId: updateRequiredBuildsMergeCheck
export def "required-builds-latest-projects-repos-condition updateRequiredBuildsMergeCheck" [
  projectKey: string
  id: int
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/required-builds/latest/projects/($projectKey)/repos/($repositorySlug)/condition/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $body
}

# Get required builds merge checks
#
# GET /required-builds/latest/projects/{projectKey}/repos/{repositorySlug}/conditions
# operationId: getPageOfRequiredBuildsMergeChecks
export def "required-builds-latest-projects-repos-conditions get" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/required-builds/latest/projects/($projectKey)/repos/($repositorySlug)/conditions" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Code Insights annotations for a commit
#
# GET /insights/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/annotations
# operationId: getAnnotations_1
export def "insights-latest-projects-repos-commits-annotations get-by-projectKey-commitId-repositorySlug" [
  projectKey: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --severity: string # Return only annotations that have one of the given severities. Can be specified more than once to filter by more than one severity. Valid severities are <code>LOW</code>, <code>MEDIUM</code> and <code>HIGH</code>.
  --path: string # Return only annotations that appear on one of the provided paths. Can be specified more than once to filter by more than one path.
  --externalId: string # Return only annotations that have one of the provided external IDs. Can be specified more than once to filter by more than one external ID.
  --type: string # Return only annotations that have one of the given types. Can be specified more than once to filter by multiple types. Valid types are <code>BUG</code>, <code>CODE_SMELL</code>, and <code>VULNERABILITY</code>.
  --key: string # Return only annotations that belong to one of the provided report keys. Can be specified more than once to filter by more than one report
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "severity" $severity "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "externalId" $externalId "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/insights/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/annotations" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all Code Insights reports for a commit
#
# GET /insights/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/reports
# operationId: getReports
export def "insights-latest-projects-repos-commits-reports list" [
  projectKey: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/insights/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/reports" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Code Insights report
#
# DELETE /insights/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/reports/{key}
# operationId: deleteACodeInsightsReport
export def "insights-latest-projects-repos-commits-reports delete" [
  projectKey: string
  commitId: string
  repositorySlug: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/insights/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/reports/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Code Insights report
#
# GET /insights/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/reports/{key}
# operationId: getACodeInsightsReport
export def "insights-latest-projects-repos-commits-reports get" [
  projectKey: string
  commitId: string
  repositorySlug: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/insights/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/reports/($key)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Code Insights report
#
# PUT /insights/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/reports/{key}
# Docs: https://developer.atlassian.com/server/bitbucket/tutorials-and-examples/code-insights-tutorial/ — Tutorial adding Code Insights to your CI system
# operationId: setACodeInsightsReport
# --data item shape: {title?: string, type?: string, value?: record}
export def "insights-latest-projects-repos-commits-reports setACodeInsightsReport" [
  projectKey: string
  commitId: string
  repositorySlug: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --coverageProviderKey: string
  --createdDate: int # format: int64, e.g. 1630041546433
  data: list # item shape: {title?: string, type?: string, value?: record}
  --details: string # e.g. This is the details of the report, it can be a longer string describing the report.
  --link: string # e.g. http://insight.example.com
  --logoUrl: string # e.g. http://insight.example.com/logo
  --reporter: string # e.g. Reporter/tool that produced this report
  --body-result: string # e.g. PASS
  title: string # e.g. report.title
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/insights/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/reports/($key)")
  let body = {coverageProviderKey: $coverageProviderKey, createdDate: $createdDate, data: $data, details: $details, link: $link, logoUrl: $logoUrl, reporter: $reporter, result: $body_result, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Code Insights annotations
#
# DELETE /insights/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/reports/{key}/annotations
# operationId: deleteAnnotations
export def "insights-latest-projects-repos-commits-reports-annotations delete" [
  projectKey: string
  commitId: string
  repositorySlug: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --externalId: string # The external IDs for the annotations that are to be deleted. Can be specified more than once to delete by more than one external ID, or can be unspecified to delete all annotations.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalId" $externalId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/insights/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/reports/($key)/annotations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Code Insights annotations for a report
#
# GET /insights/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/reports/{key}/annotations
# operationId: getAnnotations
export def "insights-latest-projects-repos-commits-reports-annotations get" [
  projectKey: string
  commitId: string
  repositorySlug: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/insights/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/reports/($key)/annotations")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Code Insights annotations
#
# POST /insights/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/reports/{key}/annotations
# operationId: addAnnotations
# --annotations item shape: {externalId?: string, line?: int, link?: string, message: string, path?: string, severity: string, type?: string}
export def "insights-latest-projects-repos-commits-reports-annotations addAnnotations" [
  projectKey: string
  commitId: string
  repositorySlug: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --annotations: list # item shape: {externalId?: string, line?: int, link?: string, message: string, path?: string, severity: string, type?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/insights/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/reports/($key)/annotations")
  let body = {annotations: $annotations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace a Code Insights annotation
#
# PUT /insights/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/reports/{key}/annotations/{externalId}
# operationId: setAnnotation
export def "insights-latest-projects-repos-commits-reports-annotations setAnnotation" [
  projectKey: string
  externalId: string
  commitId: string
  repositorySlug: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-externalId: string # e.g. message-1
  --line: int # format: int32, e.g. 4
  --link: string # e.g. https://link.to.tool/that/produced/annotation/message-1
  message: string # e.g. This is a bug here because reasons
  --path: string # e.g. path/to/file/in/repo
  severity: string # e.g. MEDIUM
  --type: string # e.g. CODE_SMELL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/insights/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/reports/($key)/annotations/($externalId)")
  let body = {externalId: $body_externalId, line: $line, link: $link, message: $message, path: $path, severity: $severity, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Change CSP strictness setting
#
# PUT /csp/latest/settings
# operationId: settings
export def "csp-latest-settings settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --strictness: string@strictness-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/csp/latest/settings")
  let body = {strictness: $strictness} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create default reviewer condition
#
# POST /default-reviewers/latest/projects/{projectKey}/condition
# operationId: createPullRequestCondition
# --reviewerGroups item shape: {avatarUrl?: string, description?: string, id?: int, name?: string, scope?: record, users?: list}
# --reviewers item shape: {active?: bool, avatarUrl?: string, displayName?: string, emailAddress?: string, links?: record, name?: string, slug?: string, type?: "NORMAL"|"SERVICE"}
# --sourceMatcher shape: {displayId?: string, id?: string, type?: record}
# --targetMatcher shape: {displayId?: string, id?: string, type?: record}
export def "default-reviewers-latest-projects-condition createPullRequestCondition" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --requiredApprovals: int # format: int32, e.g. 1
  --reviewerGroups: list # item shape: {avatarUrl?: string, description?: string, id?: int, name?: string, scope?: record, users?: list}
  --reviewers: list # item shape: {active?: bool, avatarUrl?: string, displayName?: string, emailAddress?: string, links?: record, name?: string, slug?: string, type?: "NORMAL"|"SERVICE"}
  --sourceMatcher: any # shape: {displayId?: string, id?: string, type?: record}
  --targetMatcher: record # shape: {displayId?: string, id?: string, type?: record}
]: any -> record<id: int, requiredApprovals: int, reviewerGroups: table<avatarUrl: string, description: string, id: int, name: string, scope: record, users: list>, reviewers: table<avatarUrl: string, description: string, id: int, name: string, scope: record, users: list>, scope: record<resourceId: int, type: string>, sourceRefMatcher: record<displayId: string, id: string, type: record<id: string, name: string>>, targetRefMatcher: record<displayId: string, id: string, type: record<id: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/default-reviewers/latest/projects/($projectKey)/condition")
  let body = {requiredApprovals: $requiredApprovals, reviewerGroups: $reviewerGroups, reviewers: $reviewers, sourceMatcher: $sourceMatcher, targetMatcher: $targetMatcher} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete default reviewer condition
#
# DELETE /default-reviewers/latest/projects/{projectKey}/condition/{id}
# operationId: deletePullRequestCondition
export def "default-reviewers-latest-projects-condition delete" [
  projectKey: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/default-reviewers/latest/projects/($projectKey)/condition/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update default reviewer condition
#
# PUT /default-reviewers/latest/projects/{projectKey}/condition/{id}
# operationId: updatePullRequestCondition
# --reviewerGroups item shape: {avatarUrl?: string, description?: string, id?: int, name?: string, scope?: record, users?: list}
# --reviewers item shape: {active?: bool, avatarUrl?: string, displayName?: string, emailAddress?: string, links?: record, name?: string, slug?: string, type?: "NORMAL"|"SERVICE"}
# --sourceMatcher shape: {displayId?: string, id?: string, type?: record}
# --targetMatcher shape: {displayId?: string, id?: string, type?: record}
export def "default-reviewers-latest-projects-condition updatePullRequestCondition" [
  projectKey: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --requiredApprovals: int # format: int32, e.g. 1
  --reviewerGroups: list # item shape: {avatarUrl?: string, description?: string, id?: int, name?: string, scope?: record, users?: list}
  --reviewers: list # item shape: {active?: bool, avatarUrl?: string, displayName?: string, emailAddress?: string, links?: record, name?: string, slug?: string, type?: "NORMAL"|"SERVICE"}
  --sourceMatcher: any # shape: {displayId?: string, id?: string, type?: record}
  --targetMatcher: record # shape: {displayId?: string, id?: string, type?: record}
]: any -> record<id: int, requiredApprovals: int, reviewerGroups: table<avatarUrl: string, description: string, id: int, name: string, scope: record, users: list>, reviewers: table<avatarUrl: string, description: string, id: int, name: string, scope: record, users: list>, scope: record<resourceId: int, type: string>, sourceRefMatcher: record<displayId: string, id: string, type: record<id: string, name: string>>, targetRefMatcher: record<displayId: string, id: string, type: record<id: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/default-reviewers/latest/projects/($projectKey)/condition/($id)")
  let body = {requiredApprovals: $requiredApprovals, reviewerGroups: $reviewerGroups, reviewers: $reviewers, sourceMatcher: $sourceMatcher, targetMatcher: $targetMatcher} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get default reviewer conditions
#
# GET /default-reviewers/latest/projects/{projectKey}/conditions
# operationId: getPullRequestConditions
export def "default-reviewers-latest-projects-conditions get" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, requiredApprovals: int, reviewerGroups: list<record>, reviewers: list<record>, scope: record<resourceId: int, type: string>, sourceRefMatcher: record<displayId: string, id: string, type: record>, targetRefMatcher: record<displayId: string, id: string, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/default-reviewers/latest/projects/($projectKey)/conditions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create default reviewer condition
#
# POST /default-reviewers/latest/projects/{projectKey}/repos/{repositorySlug}/condition
# operationId: createPullRequestCondition_1
# --reviewerGroups item shape: {avatarUrl?: string, description?: string, id?: int, name?: string, scope?: record, users?: list}
# --reviewers item shape: {active?: bool, avatarUrl?: string, displayName?: string, emailAddress?: string, links?: record, name?: string, slug?: string, type?: "NORMAL"|"SERVICE"}
# --sourceMatcher shape: {displayId?: string, id?: string, type?: record}
# --targetMatcher shape: {displayId?: string, id?: string, type?: record}
export def "default-reviewers-latest-projects-repos-condition createPullRequestCondition-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --requiredApprovals: int # format: int32, e.g. 1
  --reviewerGroups: list # item shape: {avatarUrl?: string, description?: string, id?: int, name?: string, scope?: record, users?: list}
  --reviewers: list # item shape: {active?: bool, avatarUrl?: string, displayName?: string, emailAddress?: string, links?: record, name?: string, slug?: string, type?: "NORMAL"|"SERVICE"}
  --sourceMatcher: any # shape: {displayId?: string, id?: string, type?: record}
  --targetMatcher: record # shape: {displayId?: string, id?: string, type?: record}
]: any -> record<id: int, requiredApprovals: int, reviewerGroups: table<avatarUrl: string, description: string, id: int, name: string, scope: record, users: list>, reviewers: table<avatarUrl: string, description: string, id: int, name: string, scope: record, users: list>, scope: record<resourceId: int, type: string>, sourceRefMatcher: record<displayId: string, id: string, type: record<id: string, name: string>>, targetRefMatcher: record<displayId: string, id: string, type: record<id: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/default-reviewers/latest/projects/($projectKey)/repos/($repositorySlug)/condition")
  let body = {requiredApprovals: $requiredApprovals, reviewerGroups: $reviewerGroups, reviewers: $reviewers, sourceMatcher: $sourceMatcher, targetMatcher: $targetMatcher} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete default reviewer condition
#
# DELETE /default-reviewers/latest/projects/{projectKey}/repos/{repositorySlug}/condition/{id}
# operationId: deletePullRequestCondition_1
export def "default-reviewers-latest-projects-repos-condition delete-by-projectKey-id-repositorySlug" [
  projectKey: string
  id: int
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/default-reviewers/latest/projects/($projectKey)/repos/($repositorySlug)/condition/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update default reviewer condition
#
# PUT /default-reviewers/latest/projects/{projectKey}/repos/{repositorySlug}/condition/{id}
# operationId: updatePullRequestCondition_1
# --reviewerGroups item shape: {avatarUrl?: string, description?: string, id?: int, name?: string, scope?: record, users?: list}
# --reviewers item shape: {active?: bool, avatarUrl?: string, displayName?: string, emailAddress?: string, links?: record, name?: string, slug?: string, type?: "NORMAL"|"SERVICE"}
# --sourceMatcher shape: {displayId?: string, id?: string, type?: record}
# --targetMatcher shape: {displayId?: string, id?: string, type?: record}
export def "default-reviewers-latest-projects-repos-condition updatePullRequestCondition-by-projectKey-id-repositorySlug" [
  projectKey: string
  id: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --requiredApprovals: int # format: int32, e.g. 1
  --reviewerGroups: list # item shape: {avatarUrl?: string, description?: string, id?: int, name?: string, scope?: record, users?: list}
  --reviewers: list # item shape: {active?: bool, avatarUrl?: string, displayName?: string, emailAddress?: string, links?: record, name?: string, slug?: string, type?: "NORMAL"|"SERVICE"}
  --sourceMatcher: any # shape: {displayId?: string, id?: string, type?: record}
  --targetMatcher: record # shape: {displayId?: string, id?: string, type?: record}
]: any -> record<id: int, requiredApprovals: int, reviewerGroups: table<avatarUrl: string, description: string, id: int, name: string, scope: record, users: list>, reviewers: table<avatarUrl: string, description: string, id: int, name: string, scope: record, users: list>, scope: record<resourceId: int, type: string>, sourceRefMatcher: record<displayId: string, id: string, type: record<id: string, name: string>>, targetRefMatcher: record<displayId: string, id: string, type: record<id: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/default-reviewers/latest/projects/($projectKey)/repos/($repositorySlug)/condition/($id)")
  let body = {requiredApprovals: $requiredApprovals, reviewerGroups: $reviewerGroups, reviewers: $reviewers, sourceMatcher: $sourceMatcher, targetMatcher: $targetMatcher} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get default reviewer conditions
#
# GET /default-reviewers/latest/projects/{projectKey}/repos/{repositorySlug}/conditions
# operationId: getPullRequestConditions_1
export def "default-reviewers-latest-projects-repos-conditions get-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, requiredApprovals: int, reviewerGroups: list<record>, reviewers: list<record>, scope: record<resourceId: int, type: string>, sourceRefMatcher: record<displayId: string, id: string, type: record>, targetRefMatcher: record<displayId: string, id: string, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/default-reviewers/latest/projects/($projectKey)/repos/($repositorySlug)/conditions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get required reviewers for PR creation
#
# GET /default-reviewers/latest/projects/{projectKey}/repos/{repositorySlug}/reviewers
# operationId: getReviewers
export def "default-reviewers-latest-projects-repos-reviewers get" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --targetRepoId: string # The ID of the repository in which the target ref exists
  --sourceRepoId: string # The ID of the repository in which the source ref exists
  --sourceRefId: string # The ID of the source ref
  --targetRefId: string # The ID of the target ref
]: nothing -> table<id: int, requiredApprovals: int, reviewerGroups: list<record>, reviewers: list<record>, scope: record<resourceId: int, type: string>, sourceRefMatcher: record<displayId: string, id: string, type: record>, targetRefMatcher: record<displayId: string, id: string, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "targetRepoId" $targetRepoId "scalar") (serialize-qp "sourceRepoId" $sourceRepoId "scalar") (serialize-qp "sourceRefId" $sourceRefId "scalar") (serialize-qp "targetRefId" $targetRefId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/default-reviewers/latest/projects/($projectKey)/repos/($repositorySlug)/reviewers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check PR rebase precondition
#
# GET /git/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/rebase
# operationId: canRebase
export def "git-latest-projects-repos-pull-requests-rebase canRebase" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/git/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/rebase")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rebase pull request
#
# POST /git/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/rebase
# operationId: rebase
export def "git-latest-projects-repos-pull-requests-rebase rebase" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: int # format: int32, e.g. 1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/git/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/rebase")
  let body = {version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create tag
#
# POST /git/latest/projects/{projectKey}/repos/{repositorySlug}/tags
# operationId: createTag
export def "git-latest-projects-repos-tags createTag" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool>
  --message: string # e.g. A new release tag
  --name: string # e.g. release-tag
  --startPoint: string # e.g. refs/heads/master
  --type: string@type-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/git/latest/projects/($projectKey)/repos/($repositorySlug)/tags")
  let body = {force: $force, message: $message, name: $name, startPoint: $startPoint, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete tag
#
# DELETE /git/latest/projects/{projectKey}/repos/{repositorySlug}/tags/{name}
# operationId: deleteTag
export def "git-latest-projects-repos-tags delete" [
  projectKey: string
  name: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/git/latest/projects/($projectKey)/repos/($repositorySlug)/tags/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes all default tasks for the repository
#
# DELETE /default-tasks/latest/projects/{projectKey}/repos/{repositorySlug}/tasks
# operationId: deleteAllDefaultTasks_1
export def "default-tasks-latest-projects-repos-tasks delete-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/default-tasks/latest/projects/($projectKey)/repos/($repositorySlug)/tasks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a page of default tasks
#
# GET /default-tasks/latest/projects/{projectKey}/repos/{repositorySlug}/tasks
# operationId: getDefaultTasks_1
export def "default-tasks-latest-projects-repos-tasks get-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --markup: string # If present or `"true"`, includes a markup-rendered description
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> record<isLastPage: bool, limit: float, nextPageStart: int, size: float, start: int, values: table<description: string, html: string, id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "markup" $markup "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/default-tasks/latest/projects/($projectKey)/repos/($repositorySlug)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a default task
#
# POST /default-tasks/latest/projects/{projectKey}/repos/{repositorySlug}/tasks
# operationId: addDefaultTask_1
# --sourceMatcher shape: {displayId?: string, id?: string, type?: record}
# --targetMatcher shape: {displayId?: string, id?: string, type?: record}
export def "default-tasks-latest-projects-repos-tasks addDefaultTask-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # e.g. Default task description
  --sourceMatcher: any # shape: {displayId?: string, id?: string, type?: record}
  --targetMatcher: record # shape: {displayId?: string, id?: string, type?: record}
]: any -> record<description: string, html: string, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/default-tasks/latest/projects/($projectKey)/repos/($repositorySlug)/tasks")
  let body = {description: $description, sourceMatcher: $sourceMatcher, targetMatcher: $targetMatcher} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a specific default task
#
# DELETE /default-tasks/latest/projects/{projectKey}/repos/{repositorySlug}/tasks/{taskId}
# operationId: deleteDefaultTask_1
export def "default-tasks-latest-projects-repos-tasks delete-by-projectKey-repositorySlug-taskId" [
  projectKey: string
  repositorySlug: string
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/default-tasks/latest/projects/($projectKey)/repos/($repositorySlug)/tasks/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a default task
#
# PUT /default-tasks/latest/projects/{projectKey}/repos/{repositorySlug}/tasks/{taskId}
# operationId: updateDefaultTask_1
# --sourceMatcher shape: {displayId?: string, id?: string, type?: record}
# --targetMatcher shape: {displayId?: string, id?: string, type?: record}
export def "default-tasks-latest-projects-repos-tasks updateDefaultTask-by-projectKey-repositorySlug-taskId" [
  projectKey: string
  repositorySlug: string
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # e.g. Default task description
  --sourceMatcher: any # shape: {displayId?: string, id?: string, type?: record}
  --targetMatcher: record # shape: {displayId?: string, id?: string, type?: record}
]: any -> record<description: string, html: string, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/default-tasks/latest/projects/($projectKey)/repos/($repositorySlug)/tasks/($taskId)")
  let body = {description: $description, sourceMatcher: $sourceMatcher, targetMatcher: $targetMatcher} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes all default tasks for the project
#
# DELETE /default-tasks/latest/projects/{projectKey}/tasks
# operationId: deleteAllDefaultTasks
export def "default-tasks-latest-projects-tasks delete-by-projectKey" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/default-tasks/latest/projects/($projectKey)/tasks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a page of default tasks
#
# GET /default-tasks/latest/projects/{projectKey}/tasks
# operationId: getDefaultTasks
export def "default-tasks-latest-projects-tasks get" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --markup: string # If present or "true", includes a markup-rendered description
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> record<isLastPage: bool, limit: float, nextPageStart: int, size: float, start: int, values: table<description: string, html: string, id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "markup" $markup "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/default-tasks/latest/projects/($projectKey)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a default task
#
# POST /default-tasks/latest/projects/{projectKey}/tasks
# operationId: addDefaultTask
# --sourceMatcher shape: {displayId?: string, id?: string, type?: record}
# --targetMatcher shape: {displayId?: string, id?: string, type?: record}
export def "default-tasks-latest-projects-tasks addDefaultTask" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # e.g. Default task description
  --sourceMatcher: any # shape: {displayId?: string, id?: string, type?: record}
  --targetMatcher: record # shape: {displayId?: string, id?: string, type?: record}
]: any -> record<description: string, html: string, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/default-tasks/latest/projects/($projectKey)/tasks")
  let body = {description: $description, sourceMatcher: $sourceMatcher, targetMatcher: $targetMatcher} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a specific default task
#
# DELETE /default-tasks/latest/projects/{projectKey}/tasks/{taskId}
# operationId: deleteDefaultTask
export def "default-tasks-latest-projects-tasks delete-by-projectKey-taskId" [
  projectKey: string
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/default-tasks/latest/projects/($projectKey)/tasks/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a default task
#
# PUT /default-tasks/latest/projects/{projectKey}/tasks/{taskId}
# operationId: updateDefaultTask
# --sourceMatcher shape: {displayId?: string, id?: string, type?: record}
# --targetMatcher shape: {displayId?: string, id?: string, type?: record}
export def "default-tasks-latest-projects-tasks updateDefaultTask" [
  projectKey: string
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # e.g. Default task description
  --sourceMatcher: any # shape: {displayId?: string, id?: string, type?: record}
  --targetMatcher: record # shape: {displayId?: string, id?: string, type?: record}
]: any -> record<description: string, html: string, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/default-tasks/latest/projects/($projectKey)/tasks/($taskId)")
  let body = {description: $description, sourceMatcher: $sourceMatcher, targetMatcher: $targetMatcher} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete all GPG keys for user
#
# DELETE /gpg/latest/keys
# operationId: deleteForUser
export def "gpg-latest-keys delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # The username of the user to delete the keys for. If no username is specified, the GPG keys will be deleted for the currently authenticated user.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/gpg/latest/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all GPG keys
#
# GET /gpg/latest/keys
# operationId: getKeysForUser
export def "gpg-latest-keys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # The name of the user to get keys for (optional; requires ADMIN permission or higher).
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> record<isLastPage: bool, limit: float, nextPageStart: int, size: float, start: int, values: table<emailAddress: string, expiryDate: int, fingerprint: string, id: string, subKeys: list, text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/gpg/latest/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a GPG key
#
# POST /gpg/latest/keys
# operationId: addKey
# --subKeys item shape: {expiryDate?: string, fingerprint?: string}
export def "gpg-latest-keys addKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # The name of the user to add a key for (optional; requires ADMIN permission or higher).
  --text: string # e.g. -----BEGIN PGP SIGNATURE-----  iQEzBAABCAAdFiEEM8MrWnoxlp3K1lFY5BMGiWNefn4FAlkqKE4ACgkQ5BMGiWNe fn6/kggAyzKhDDqdVb3Rq02hiSqeqKa1JuKRqDmzIpa6Pxa+1CpCnxwaIVrGgIii vj0ZNJzL1Bm2xm0JasotJDiZq5pFKi0FfQ0WmskuhsW1VY/f08TltHpHvK2kHVRr GEMVDUb0nj0I7Duc8XTipiYoDGS1GvydNR/bu3SsFTcZyapXirQcTCRT6/Sn0/IP pUeIwQo1qK4e8gTOhWhfWEiVig39lQhiZFtm5S/vfAY72/Rgp68zMYmwasMSnBgF /LLFW6lXAqZIoAP8AnmsMRjCH6mS98+/lxKq2+K71+2YUUIAnNEeO09Lufo3B3Da Pbs7BpD28w4lKlzb2EQ0n0C9rrxdPA== =VZpm -----END PGP SIGNATURE-----
]: any -> record<emailAddress: string, expiryDate: int, fingerprint: string, id: string, subKeys: table<expiryDate: string, fingerprint: string>, text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/gpg/latest/keys" $qp)
  let body = {text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a GPG key
#
# DELETE /gpg/latest/keys/{fingerprintOrId}
# operationId: deleteKey
export def "gpg-latest-keys delete-by-fingerprintOrId" [
  fingerprintOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gpg/latest/keys/($fingerprintOrId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop a Jira development information backfill sync
#
# DELETE /jira-dev/latest/devinfo-backfill
# operationId: stopBackfillSync
export def "jira-dev-latest-devinfo-backfill stopBackfillSync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/jira-dev/latest/devinfo-backfill")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start a Jira development information backfill sync
#
# POST /jira-dev/latest/devinfo-backfill
# operationId: startBackfillSync
# --repositories item shape: {projectKey: string, slug: string}
export def "jira-dev-latest-devinfo-backfill startBackfillSync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fromDate: int # The starting timestamp in milliseconds for looking for backfill items, non-inclusive (format: int64, e.g. 1769123493000)
  jiraSiteIds: list
  repositories: list # item shape: {projectKey: string, slug: string}
  --toDate: int # The ending timestamp in milliseconds for looking for backfill items, non-inclusive (format: int64, e.g. 1770653493000)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/jira-dev/latest/devinfo-backfill")
  let body = {fromDate: $fromDate, jiraSiteIds: $jiraSiteIds, repositories: $repositories, toDate: $toDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get repository backfill tasks that failed and their associated errors
#
# GET /jira-dev/latest/devinfo-backfill/report
# operationId: getBackfillSyncReport
export def "jira-dev-latest-devinfo-backfill-report get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/jira-dev/latest/devinfo-backfill/report")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Jira development information backfill status
#
# GET /jira-dev/latest/devinfo-backfill/status
# operationId: getBackfillSyncStatus
export def "jira-dev-latest-devinfo-backfill-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/jira-dev/latest/devinfo-backfill/status")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Jira Issue
#
# POST /jira/latest/comments/{commentId}/issues
# operationId: createIssue
export def "jira-latest-comments-issues createIssue" [
  commentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --applicationId: string # id of the Jira server
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "applicationId" $applicationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jira/latest/comments/($commentId)/issues" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get changesets for issue key
#
# GET /jira/latest/issues/{issueKey}/commits
# operationId: getCommitsByIssueKey
export def "jira-latest-issues-commits get" [
  issueKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxChanges: string # The maximum number of changes to retrieve for each changeset
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxChanges" $maxChanges "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/jira/latest/issues/($issueKey)/commits" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get entity link
#
# GET /jira/latest/projects/{projectKey}/primary-enhanced-entitylink
# operationId: getEnhancedEntityLinkForProject
export def "jira-latest-projects-primary-enhanced-entitylink get" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/jira/latest/projects/($projectKey)/primary-enhanced-entitylink")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issues for a pull request
#
# GET /jira/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/issues
# operationId: getIssueKeysForPullRequest
export def "jira-latest-projects-repos-pull-requests-issues get" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/jira/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/issues")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a reaction from comment
#
# DELETE /comment-likes/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/comments/{commentId}/reactions/{emoticon}
# operationId: unReact
export def "comment-likes-latest-projects-repos-commits-comments-reactions unReact" [
  projectKey: string
  commentId: string
  commitId: string
  emoticon: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comment-likes/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/comments/($commentId)/reactions/($emoticon)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# React to a comment
#
# PUT /comment-likes/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/comments/{commentId}/reactions/{emoticon}
# operationId: react
export def "comment-likes-latest-projects-repos-commits-comments-reactions react" [
  projectKey: string
  commentId: string
  commitId: string
  emoticon: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comment-likes/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/comments/($commentId)/reactions/($emoticon)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a reaction from a PR comment
#
# DELETE /comment-likes/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/comments/{commentId}/reactions/{emoticon}
# operationId: unReact_1
export def "comment-likes-latest-projects-repos-pull-requests-comments-reactions unReact-by-projectKey-commentId-pullRequestId-emoticon-repositorySlug" [
  projectKey: string
  commentId: string
  pullRequestId: string
  emoticon: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comment-likes/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/comments/($commentId)/reactions/($emoticon)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# React to a PR comment
#
# PUT /comment-likes/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/comments/{commentId}/reactions/{emoticon}
# operationId: react_1
export def "comment-likes-latest-projects-repos-pull-requests-comments-reactions react-by-projectKey-commentId-pullRequestId-emoticon-repositorySlug" [
  projectKey: string
  commentId: string
  pullRequestId: string
  emoticon: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comment-likes/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/comments/($commentId)/reactions/($emoticon)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve inactive AES key(s)
#
# GET /secrets/1.0/keys/inactive
# operationId: getInactiveKeys
export def "secrets-10-keys-inactive get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/secrets/1.0/keys/inactive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete inactive AES key(s)
#
# DELETE /secrets/1.0/keys/inactive
# operationId: deleteInactiveKeys
export def "secrets-10-keys-inactive delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/secrets/1.0/keys/inactive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rotate the current AES key
#
# POST /secrets/1.0/keys/rotate
# operationId: rotateKey
export def "secrets-10-keys-rotate rotateKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/secrets/1.0/keys/rotate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get farm nodes
#
# GET /mirroring/latest/farmNodes
# operationId: getFarmNodes
export def "mirroring-latest-farm-nodes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/farmNodes")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get delayed sync repositories
#
# GET /mirroring/latest/mirrorRepos/delayed-sync
# operationId: getDelayedSyncRepositories
export def "mirroring-latest-mirror-repos-delayed-sync get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --delayThreshold: string # Returns only those repositories that are delayed for the given duration. The minimum allowed value is the configured value for the property <code>plugin.mirroring.synchronization.interval</code>
  --limit: string # Limit the number of delayed sync repositories returned, the maximum allowed value is 100
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delayThreshold" $delayThreshold "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mirroring/latest/mirrorRepos/delayed-sync" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get clone URLs
#
# GET /mirroring/latest/mirrorRepos/{externalRepositoryId}
# operationId: getMirroredRepository
export def "mirroring-latest-mirror-repos get" [
  externalRepositoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mirroring/latest/mirrorRepos/($externalRepositoryId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get synchronization progress state
#
# GET /mirroring/latest/progress
# operationId: getSynchronizationProgress
export def "mirroring-latest-progress get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/progress")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the repository lock owner for the syncing process
#
# GET /mirroring/latest/supportInfo/projects/{projectKey}/repos/{repositorySlug}/repo-lock-owner
# operationId: getRepositoryLockOwner
export def "mirroring-latest-support-info-projects-repos-repo-lock-owner get" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mirroring/latest/supportInfo/projects/($projectKey)/repos/($repositorySlug)/repo-lock-owner")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about the mirrored repository
#
# GET /mirroring/latest/supportInfo/projects/{projectKey}/repos/{repositorySlug}/repoSyncStatus
# operationId: getRepoSyncStatus_1
export def "mirroring-latest-support-info-projects-repos-repo-sync-status get-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mirroring/latest/supportInfo/projects/($projectKey)/repos/($repositorySlug)/repoSyncStatus")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get items in ref changes queue
#
# GET /mirroring/latest/supportInfo/refChangesQueue
# operationId: getRefChangesQueue
export def "mirroring-latest-support-info-ref-changes-queue get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/supportInfo/refChangesQueue")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get total number of items in ref changes queue
#
# GET /mirroring/latest/supportInfo/refChangesQueue/count
# operationId: getRefChangesQueueCount
export def "mirroring-latest-support-info-ref-changes-queue-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/supportInfo/refChangesQueue/count")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the repository lock owners for the syncing process
#
# GET /mirroring/latest/supportInfo/repo-lock-owners
# operationId: getRepositoryLockOwners
export def "mirroring-latest-support-info-repo-lock-owners get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/supportInfo/repo-lock-owners")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sync status of repositories
#
# GET /mirroring/latest/supportInfo/repoSyncStatus
# operationId: getRepoSyncStatus
export def "mirroring-latest-support-info-repo-sync-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mirroring/latest/supportInfo/repoSyncStatus" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get upstream settings
#
# GET /mirroring/latest/syncSettings
# operationId: getMirrorSettings
export def "mirroring-latest-sync-settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/syncSettings")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update upstream settings
#
# PUT /mirroring/latest/syncSettings
# operationId: setMirrorSettings
export def "mirroring-latest-sync-settings setMirrorSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mode: string@mode-completer
  --projectIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/syncSettings")
  let body = {mode: $mode, projectIds: $projectIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get mirror mode
#
# GET /mirroring/latest/syncSettings/mode
# operationId: getMirrorMode
export def "mirroring-latest-sync-settings-mode get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/syncSettings/mode")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update mirror mode
#
# PUT /mirroring/latest/syncSettings/mode
# operationId: setMirrorMode
export def "mirroring-latest-sync-settings-mode setMirrorMode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/syncSettings/mode")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get mirrored project IDs
#
# GET /mirroring/latest/syncSettings/projects
# operationId: getMirroredProjects
export def "mirroring-latest-sync-settings-projects get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/syncSettings/projects")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add multiple projects to be mirrored
#
# POST /mirroring/latest/syncSettings/projects
# operationId: startMirroringProjects
export def "mirroring-latest-sync-settings-projects startMirroringProjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/syncSettings/projects")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Stop mirroring project
#
# DELETE /mirroring/latest/syncSettings/projects/{projectId}
# operationId: stopMirroringProject
export def "mirroring-latest-sync-settings-projects stopMirroringProject" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mirroring/latest/syncSettings/projects/($projectId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add project to be mirrored
#
# POST /mirroring/latest/syncSettings/projects/{projectId}
# operationId: startMirroringProject
export def "mirroring-latest-sync-settings-projects startMirroringProject" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mirroring/latest/syncSettings/projects/($projectId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get upstream server
#
# GET /mirroring/latest/upstreamServer
# operationId: getUpstreamServer
export def "mirroring-latest-upstream-server get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/upstreamServer")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# End ZDU upgrade on mirror farm
#
# POST /mirroring/latest/zdu/end
# operationId: endRollingUpgrade
export def "mirroring-latest-zdu-end endRollingUpgrade" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/zdu/end")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start ZDU upgrade on mirror farm
#
# POST /mirroring/latest/zdu/start
# operationId: startRollingUpgrade
export def "mirroring-latest-zdu-start startRollingUpgrade" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/zdu/start")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get synchronization status
#
# GET /sync/latest/projects/{projectKey}/repos/{repositorySlug}
# operationId: getStatus
export def "sync-latest-projects-repos get" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --at: string # Retrieves the synchronization status for the specified ref within the repository, rather than for the entire repository
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "at" $at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sync/latest/projects/($projectKey)/repos/($repositorySlug)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable synchronization
#
# POST /sync/latest/projects/{projectKey}/repos/{repositorySlug}
# operationId: setEnabled
# --aheadRefs shape: {displayId: string, id: string, state?: "AHEAD"|"DIVERGED"|"ORPHANED", tag?: bool, type: "BRANCH"|"TAG"}
# --divergedRefs shape: {displayId: string, id: string, state?: "AHEAD"|"DIVERGED"|"ORPHANED", tag?: bool, type: "BRANCH"|"TAG"}
# --orphanedRefs shape: {displayId: string, id: string, state?: "AHEAD"|"DIVERGED"|"ORPHANED", tag?: bool, type: "BRANCH"|"TAG"}
export def "sync-latest-projects-repos setEnabled" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sync/latest/projects/($projectKey)/repos/($repositorySlug)")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Manual synchronization
#
# POST /sync/latest/projects/{projectKey}/repos/{repositorySlug}/synchronize
# operationId: synchronize
# --context shape: {commitMessage?: string}
export def "sync-latest-projects-repos-synchronize synchronize" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer # e.g. MERGE
  --context: record # shape: {commitMessage?: string}
  --refId: string # e.g. refs/heads/master
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sync/latest/projects/($projectKey)/repos/($repositorySlug)/synchronize")
  let body = {action: $action, context: $context, refId: $refId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove preferred mirror
#
# DELETE /mirroring/latest/account/settings/preferred-mirror
# operationId: deletePreferredMirrorId
export def "mirroring-latest-account-settings-preferred-mirror delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/account/settings/preferred-mirror")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get preferred mirror
#
# GET /mirroring/latest/account/settings/preferred-mirror
# operationId: getPreferredMirrorId
export def "mirroring-latest-account-settings-preferred-mirror get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/account/settings/preferred-mirror")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set preferred mirror
#
# POST /mirroring/latest/account/settings/preferred-mirror
# operationId: setPreferredMirrorId
export def "mirroring-latest-account-settings-preferred-mirror setPreferredMirrorId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/account/settings/preferred-mirror")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get analytics settings from upstream
#
# GET /mirroring/latest/analyticsSettings
# operationId: analyticsSettings
export def "mirroring-latest-analytics-settings analyticsSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/analyticsSettings")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Authenticate on behalf of a user
#
# POST /mirroring/latest/authenticate
# operationId: authenticate
# --credentials shape: {password?: string, username?: string, token?: string, algorithm?: string, publicKey?: string}
export def "mirroring-latest-authenticate authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  credentials: record # shape: {password?: string, username?: string, token?: string, algorithm?: string, publicKey?: string}
  --repositoryId: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/authenticate")
  let body = {credentials: $credentials, repositoryId: $repositoryId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all mirrors
#
# GET /mirroring/latest/mirrorServers
# operationId: listMirrors
export def "mirroring-latest-mirror-servers listMirrors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mirroring/latest/mirrorServers" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete mirror by ID
#
# DELETE /mirroring/latest/mirrorServers/{mirrorId}
# operationId: remove
export def "mirroring-latest-mirror-servers remove" [
  mirrorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mirroring/latest/mirrorServers/($mirrorId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get mirror by ID
#
# GET /mirroring/latest/mirrorServers/{mirrorId}
# operationId: getMirror
export def "mirroring-latest-mirror-servers get" [
  mirrorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mirroring/latest/mirrorServers/($mirrorId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upgrade mirror server
#
# PUT /mirroring/latest/mirrorServers/{mirrorId}
# operationId: upgrade
export def "mirroring-latest-mirror-servers upgrade" [
  mirrorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --baseUrl: string # e.g. https://bitbucket-eu.example.com:7990/bitbucket
  --productVersion: string # e.g. 8.0.0
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mirroring/latest/mirrorServers/($mirrorId)")
  let body = {baseUrl: $baseUrl, productVersion: $productVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Publish RepositoryMirrorEvent
#
# POST /mirroring/latest/mirrorServers/{mirrorId}/events
# operationId: publishEvent
export def "mirroring-latest-mirror-servers-events publishEvent" [
  mirrorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mirrorRepoId: int # format: int32, e.g. 42
  type: string@type-completer-1
  upstreamRepoId: string # e.g. 24
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mirroring/latest/mirrorServers/($mirrorId)/events")
  let body = {mirrorRepoId: $mirrorRepoId, type: $type, upstreamRepoId: $upstreamRepoId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get project
#
# GET /mirroring/latest/projects/{projectId}
# operationId: getProjectById
export def "mirroring-latest-projects get" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mirroring/latest/projects/($projectId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get hashes for repositories in project
#
# GET /mirroring/latest/projects/{projectId}/repos
# operationId: getAllReposForProject
export def "mirroring-latest-projects-repos get" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeDefaultBranch: string@includeDefaultBranch-completer # includes defaultBranchId in the response, if <code>true</code>. Default value is <code>false</code> (default: false)
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeDefaultBranch" $includeDefaultBranch "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mirroring/latest/projects/($projectId)/repos" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get content hashes for repositories
#
# GET /mirroring/latest/repos
# operationId: getAllContentHashes
export def "mirroring-latest-repos list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeDefaultBranch: string@includeDefaultBranch-completer # includes defaultBranchId for each repository in the response, if <code>true</code>. Default value is <code>false</code>. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeDefaultBranch" $includeDefaultBranch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mirroring/latest/repos" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get content hash for a repository
#
# GET /mirroring/latest/repos/{repoId}
# operationId: getContentHashById
export def "mirroring-latest-repos get" [
  repoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeDefaultBranch: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeDefaultBranch" $includeDefaultBranch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mirroring/latest/repos/($repoId)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get mirrors for repository
#
# GET /mirroring/latest/repos/{repoId}/mirrors
# operationId: getRepositoryMirrors
export def "mirroring-latest-repos-mirrors get" [
  repoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --preAuthorized: oneof<nothing, bool>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "preAuthorized" $preAuthorized "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/mirroring/latest/repos/($repoId)/mirrors" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get mirroring requests
#
# GET /mirroring/latest/requests
# operationId: listRequests
export def "mirroring-latest-requests listRequests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer-1 # (optional) the request state to filter on
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mirroring/latest/requests" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a mirroring request
#
# POST /mirroring/latest/requests
# operationId: register
export def "mirroring-latest-requests register" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mirrorBaseUrl: string # e.g. https://bitbucket-eu.example.com:7990/bitbucket
  --mirrorId: string # e.g. 4f0eb5fc-67fc-48f8-b4a7-87981f026c6a
  --mirrorName: string # e.g. Bitbucket Mirror
  --mirrorType: string@mirrorType-completer
  --productVersion: string # e.g. 8.0.0
  --state: string@state-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mirroring/latest/requests")
  let body = {mirrorBaseUrl: $mirrorBaseUrl, mirrorId: $mirrorId, mirrorName: $mirrorName, mirrorType: $mirrorType, productVersion: $productVersion, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a mirroring request
#
# DELETE /mirroring/latest/requests/{mirroringRequestId}
# operationId: deleteMirroringRequest
export def "mirroring-latest-requests delete" [
  mirroringRequestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mirroring/latest/requests/($mirroringRequestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a mirroring request
#
# GET /mirroring/latest/requests/{mirroringRequestId}
# operationId: getMirroringRequest
export def "mirroring-latest-requests get" [
  mirroringRequestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mirroring/latest/requests/($mirroringRequestId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Accept a mirroring request
#
# POST /mirroring/latest/requests/{mirroringRequestId}/accept
# operationId: accept
export def "mirroring-latest-requests-accept accept" [
  mirroringRequestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mirroring/latest/requests/($mirroringRequestId)/accept")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reject a mirroring request
#
# POST /mirroring/latest/requests/{mirroringRequestId}/reject
# operationId: reject
export def "mirroring-latest-requests-reject reject" [
  mirroringRequestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mirroring/latest/requests/($mirroringRequestId)/reject")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get repository archive policy
#
# GET /policies/latest/admin/repos/archive
# operationId: getRepositoryArchivePolicy
export def "policies-latest-admin-repos-archive get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/policies/latest/admin/repos/archive")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update repository archive policy
#
# PUT /policies/latest/admin/repos/archive
# operationId: setRepositoryArchivePolicy
export def "policies-latest-admin-repos-archive setRepositoryArchivePolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permission: string@permission-completer # The permission required to delete repositories. Must be one of: "SYS_ADMIN", "ADMIN", "PROJECT_ADMIN", "REPO_ADMIN". (e.g. ADMIN)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/policies/latest/admin/repos/archive")
  let body = {permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get repository delete policy
#
# GET /policies/latest/admin/repos/delete
# operationId: getRepositoryDeletePolicy
export def "policies-latest-admin-repos-delete get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/policies/latest/admin/repos/delete")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the repository delete policy
#
# PUT /policies/latest/admin/repos/delete
# operationId: setRepositoryDeletePolicy
export def "policies-latest-admin-repos-delete setRepositoryDeletePolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permission: string@permission-completer # The permission required to delete repositories. Must be one of: "SYS_ADMIN", "ADMIN", "PROJECT_ADMIN", "REPO_ADMIN". (e.g. ADMIN)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/policies/latest/admin/repos/delete")
  let body = {permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search for ref restrictions
#
# GET /branch-permissions/latest/projects/{projectKey}/repos/{repositorySlug}/restrictions
# operationId: getRestrictions_1
export def "branch-permissions-latest-projects-repos-restrictions get-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --matcherType: string@matcherType-completer # Matcher type to filter on
  --matcherId: string # Matcher id to filter on. Requires the matcherType parameter to be specified also.
  --type: string@type-completer-2 # Types of restrictions to filter on.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "matcherType" $matcherType "scalar") (serialize-qp "matcherId" $matcherId "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/branch-permissions/latest/projects/($projectKey)/repos/($repositorySlug)/restrictions" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create multiple ref restrictions
#
# POST /branch-permissions/latest/projects/{projectKey}/repos/{repositorySlug}/restrictions
# operationId: createRestrictions_1
export def "branch-permissions-latest-projects-repos-restrictions createRestrictions-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/branch-permissions/latest/projects/($projectKey)/repos/($repositorySlug)/restrictions")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.atl.bitbucket.bulk+json" $body
}

# Delete a ref restriction
#
# DELETE /branch-permissions/latest/projects/{projectKey}/repos/{repositorySlug}/restrictions/{id}
# operationId: deleteRestriction_1
export def "branch-permissions-latest-projects-repos-restrictions delete-by-projectKey-id-repositorySlug" [
  projectKey: string
  id: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/branch-permissions/latest/projects/($projectKey)/repos/($repositorySlug)/restrictions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a ref restriction
#
# GET /branch-permissions/latest/projects/{projectKey}/repos/{repositorySlug}/restrictions/{id}
# operationId: getRestriction_1
export def "branch-permissions-latest-projects-repos-restrictions get-by-projectKey-id-repositorySlug" [
  projectKey: string
  id: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/branch-permissions/latest/projects/($projectKey)/repos/($repositorySlug)/restrictions/($id)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for ref restrictions
#
# GET /branch-permissions/latest/projects/{projectKey}/restrictions
# operationId: getRestrictions
export def "branch-permissions-latest-projects-restrictions list" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --matcherType: string@matcherType-completer # Matcher type to filter on
  --matcherId: string # Matcher id to filter on. Requires the matcherType parameter to be specified also.
  --type: string@type-completer-2 # Types of restrictions to filter on.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "matcherType" $matcherType "scalar") (serialize-qp "matcherId" $matcherId "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/branch-permissions/latest/projects/($projectKey)/restrictions" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create multiple ref restrictions
#
# POST /branch-permissions/latest/projects/{projectKey}/restrictions
# operationId: createRestrictions
export def "branch-permissions-latest-projects-restrictions createRestrictions" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/branch-permissions/latest/projects/($projectKey)/restrictions")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.atl.bitbucket.bulk+json" $body
}

# Delete a ref restriction
#
# DELETE /branch-permissions/latest/projects/{projectKey}/restrictions/{id}
# operationId: deleteRestriction
export def "branch-permissions-latest-projects-restrictions delete" [
  projectKey: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/branch-permissions/latest/projects/($projectKey)/restrictions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a ref restriction
#
# GET /branch-permissions/latest/projects/{projectKey}/restrictions/{id}
# operationId: getRestriction
export def "branch-permissions-latest-projects-restrictions get" [
  projectKey: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/branch-permissions/latest/projects/($projectKey)/restrictions/($id)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all configured IdPs
#
# GET /authconfig/latest/idps
# operationId: getIdps
export def "authconfig-latest-idps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 50 is used. A limit of -1 means that the request will fetch all results. (e.g. 50)
]: nothing -> record<isLastPage: bool, limit: float, results: table<additional_scopes: list, authorization_endpoint: string, buttonText: string, certificate: string, client_id: string, client_secret: string, crowd_url: string, discovery_enabled: bool, enable_remember_me: bool, enabled: bool, id: int, idp_type: string, include_customer_logins: bool, issuer_url: string, jit_configuration: record, last_updated: string, name: string, name_id_policy: string, sign_authnrequest: bool, signature_algorithm: string, sso_issuer: string, sso_type: string, sso_url: string, token_endpoint: string, userinfo_endpoint: string, username_attribute: string, username_claim: string>, size: float, start: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authconfig/latest/idps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create IdP configuration
#
# POST /authconfig/latest/idps
# operationId: addIdp
# --jit-configuration shape: {additional-openid-scopes?: list, mapping-display-name?: string, mapping-email?: string, mapping-groups?: string, user-provisioning-enabled?: bool}
export def "authconfig-latest-idps addIdp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-scopes: list
  --authorization-endpoint: string
  --buttonText: string
  --certificate: string
  --client-id: string
  --client-secret: string
  --crowd-url: string
  --discovery-enabled: oneof<nothing, bool>
  --enable-remember-me: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --id: int # format: int64
  --idp-type: string@idp-type-completer
  --include-customer-logins: oneof<nothing, bool>
  --issuer-url: string
  --jit-configuration: any # shape: {additional-openid-scopes?: list, mapping-display-name?: string, mapping-email?: string, mapping-groups?: string, user-provisioning-enabled?: bool}
  --last-updated: string # format: date-time
  --name: string
  --name-id-policy: string@name-id-policy-completer
  --sign-authnrequest: oneof<nothing, bool>
  --signature-algorithm: string@signature-algorithm-completer
  --sso-issuer: string
  --sso-type: string@sso-type-completer
  --sso-url: string
  --token-endpoint: string
  --userinfo-endpoint: string
  --username-attribute: string
  --username-claim: string
]: any -> record<additional_scopes: list<string>, authorization_endpoint: string, buttonText: string, certificate: string, client_id: string, client_secret: string, crowd_url: string, discovery_enabled: bool, enable_remember_me: bool, enabled: bool, id: int, idp_type: string, include_customer_logins: bool, issuer_url: string, jit_configuration: record<additional_openid_scopes: list<string>, mapping_display_name: string, mapping_email: string, mapping_groups: string, user_provisioning_enabled: bool>, last_updated: string, name: string, name_id_policy: string, sign_authnrequest: bool, signature_algorithm: string, sso_issuer: string, sso_type: string, sso_url: string, token_endpoint: string, userinfo_endpoint: string, username_attribute: string, username_claim: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authconfig/latest/idps")
  let body = {additional-scopes: $additional_scopes, authorization-endpoint: $authorization_endpoint, buttonText: $buttonText, certificate: $certificate, client-id: $client_id, client-secret: $client_secret, crowd-url: $crowd_url, discovery-enabled: $discovery_enabled, enable-remember-me: $enable_remember_me, enabled: $enabled, id: $id, idp-type: $idp_type, include-customer-logins: $include_customer_logins, issuer-url: $issuer_url, jit-configuration: $jit_configuration, last-updated: $last_updated, name: $name, name-id-policy: $name_id_policy, sign-authnrequest: $sign_authnrequest, signature-algorithm: $signature_algorithm, sso-issuer: $sso_issuer, sso-type: $sso_type, sso-url: $sso_url, token-endpoint: $token_endpoint, userinfo-endpoint: $userinfo_endpoint, username-attribute: $username_attribute, username-claim: $username_claim} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete IdP configuration
#
# DELETE /authconfig/latest/idps/{id}
# operationId: removeIdp
export def "authconfig-latest-idps removeIdp" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<additional_scopes: list<string>, authorization_endpoint: string, buttonText: string, certificate: string, client_id: string, client_secret: string, crowd_url: string, discovery_enabled: bool, enable_remember_me: bool, enabled: bool, id: int, idp_type: string, include_customer_logins: bool, issuer_url: string, jit_configuration: record<additional_openid_scopes: list<string>, mapping_display_name: string, mapping_email: string, mapping_groups: string, user_provisioning_enabled: bool>, last_updated: string, name: string, name_id_policy: string, sign_authnrequest: bool, signature_algorithm: string, sso_issuer: string, sso_type: string, sso_url: string, token_endpoint: string, userinfo_endpoint: string, username_attribute: string, username_claim: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authconfig/latest/idps/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get IdP configuration
#
# GET /authconfig/latest/idps/{id}
# operationId: getIdp
export def "authconfig-latest-idps get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<additional_scopes: list<string>, authorization_endpoint: string, buttonText: string, certificate: string, client_id: string, client_secret: string, crowd_url: string, discovery_enabled: bool, enable_remember_me: bool, enabled: bool, id: int, idp_type: string, include_customer_logins: bool, issuer_url: string, jit_configuration: record<additional_openid_scopes: list<string>, mapping_display_name: string, mapping_email: string, mapping_groups: string, user_provisioning_enabled: bool>, last_updated: string, name: string, name_id_policy: string, sign_authnrequest: bool, signature_algorithm: string, sso_issuer: string, sso_type: string, sso_url: string, token_endpoint: string, userinfo_endpoint: string, username_attribute: string, username_claim: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authconfig/latest/idps/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update IdP configuration
#
# PATCH /authconfig/latest/idps/{id}
# operationId: updateIdp
# --jit-configuration shape: {additional-openid-scopes?: list, mapping-display-name?: string, mapping-email?: string, mapping-groups?: string, user-provisioning-enabled?: bool}
export def "authconfig-latest-idps updateIdp" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-scopes: list
  --authorization-endpoint: string
  --buttonText: string
  --certificate: string
  --client-id: string
  --client-secret: string
  --crowd-url: string
  --discovery-enabled: oneof<nothing, bool>
  --enable-remember-me: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --body-id: int # format: int64
  --idp-type: string@idp-type-completer
  --include-customer-logins: oneof<nothing, bool>
  --issuer-url: string
  --jit-configuration: any # shape: {additional-openid-scopes?: list, mapping-display-name?: string, mapping-email?: string, mapping-groups?: string, user-provisioning-enabled?: bool}
  --last-updated: string # format: date-time
  --name: string
  --name-id-policy: string@name-id-policy-completer
  --sign-authnrequest: oneof<nothing, bool>
  --signature-algorithm: string@signature-algorithm-completer
  --sso-issuer: string
  --sso-type: string@sso-type-completer
  --sso-url: string
  --token-endpoint: string
  --userinfo-endpoint: string
  --username-attribute: string
  --username-claim: string
]: any -> record<additional_scopes: list<string>, authorization_endpoint: string, buttonText: string, certificate: string, client_id: string, client_secret: string, crowd_url: string, discovery_enabled: bool, enable_remember_me: bool, enabled: bool, id: int, idp_type: string, include_customer_logins: bool, issuer_url: string, jit_configuration: record<additional_openid_scopes: list<string>, mapping_display_name: string, mapping_email: string, mapping_groups: string, user_provisioning_enabled: bool>, last_updated: string, name: string, name_id_policy: string, sign_authnrequest: bool, signature_algorithm: string, sso_issuer: string, sso_type: string, sso_url: string, token_endpoint: string, userinfo_endpoint: string, username_attribute: string, username_claim: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authconfig/latest/idps/($id)")
  let body = {additional-scopes: $additional_scopes, authorization-endpoint: $authorization_endpoint, buttonText: $buttonText, certificate: $certificate, client-id: $client_id, client-secret: $client_secret, crowd-url: $crowd_url, discovery-enabled: $discovery_enabled, enable-remember-me: $enable_remember_me, enabled: $enabled, id: $body_id, idp-type: $idp_type, include-customer-logins: $include_customer_logins, issuer-url: $issuer_url, jit-configuration: $jit_configuration, last-updated: $last_updated, name: $name, name-id-policy: $name_id_policy, sign-authnrequest: $sign_authnrequest, signature-algorithm: $signature_algorithm, sso-issuer: $sso_issuer, sso-type: $sso_type, sso-url: $sso_url, token-endpoint: $token_endpoint, userinfo-endpoint: $userinfo_endpoint, username-attribute: $username_attribute, username-claim: $username_claim} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all JIT provisioned users
#
# GET /authconfig/latest/jit-users
# operationId: getJitProvisionedUsers
export def "authconfig-latest-jit-users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<display_name: string, email: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authconfig/latest/jit-users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get available login options
#
# GET /authconfig/latest/login-options
# operationId: getLoginOptions
export def "authconfig-latest-login-options get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 50 is used. A limit of -1 means that the request will fetch all results. (e.g. 50)
]: nothing -> record<isLastPage: bool, limit: float, results: table<buttonText: string, id: int, loginLink: string, type: string>, size: float, start: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authconfig/latest/login-options" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# returns the currently used certificate for signing SAML authentication requests
#
# GET /authconfig/latest/saml/certificate
# operationId: getSamlCertificate
export def "authconfig-latest-saml-certificate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authconfig/latest/saml/certificate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# generates a new certificate for signing SAML authentication requests
#
# POST /authconfig/latest/saml/certificate/reset
# operationId: regenerateCertificate
export def "authconfig-latest-saml-certificate-reset regenerateCertificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authconfig/latest/saml/certificate/reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SSO configuration
#
# GET /authconfig/latest/sso
# operationId: getConfig
export def "authconfig-latest-sso get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<discovery_refresh_cron: string, enable_authentication_fallback: bool, last_updated: string, show_login_form: bool, show_login_form_for_jsm: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authconfig/latest/sso")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update SSO configuration
#
# PATCH /authconfig/latest/sso
# operationId: updateConfig
export def "authconfig-latest-sso updateConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --discovery-refresh-cron: string
  --enable-authentication-fallback: oneof<nothing, bool>
  --last-updated: string # format: date-time
  --show-login-form: oneof<nothing, bool>
  --show-login-form-for-jsm: oneof<nothing, bool>
]: any -> record<discovery_refresh_cron: string, enable_authentication_fallback: bool, last_updated: string, show_login_form: bool, show_login_form_for_jsm: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authconfig/latest/sso")
  let body = {discovery-refresh-cron: $discovery_refresh_cron, enable-authentication-fallback: $enable_authentication_fallback, last-updated: $last_updated, show-login-form: $show_login_form, show-login-form-for-jsm: $show_login_form_for_jsm} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get basic auth configuration
#
# GET /basicauth/latest/config
# operationId: get
export def "basicauth-latest-config get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allowed_paths: list<string>, allowed_users: list<string>, block_requests: bool, show_warning_message: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/basicauth/latest/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update basic auth configuration
#
# PUT /basicauth/latest/config
# operationId: put
export def "basicauth-latest-config put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-paths: list
  --allowed-users: list
  --block-requests: oneof<nothing, bool>
  --show-warning-message: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/basicauth/latest/config")
  let body = {allowed-paths: $allowed_paths, allowed-users: $allowed_users, block-requests: $block_requests, show-warning-message: $show_warning_message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Authenticate with 2SV
#
# POST /tsv/latest/authenticate
# operationId: authenticate
export def "tsv-latest-authenticate authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --captchaChallenge: string
  --captchaId: string
  --password: string
  --rememberMe: oneof<nothing, bool>
  --targetUrl: string
  --username: string
]: any -> record<next: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tsv/latest/authenticate")
  let body = {captchaChallenge: $captchaChallenge, captchaId: $captchaId, password: $password, rememberMe: $rememberMe, targetUrl: $targetUrl, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get CAPTCHA challenge
#
# GET /tsv/latest/authenticate/captcha
# operationId: getCaptchaData
export def "tsv-latest-authenticate-captcha get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<captchaId: string, captchaImageUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tsv/latest/authenticate/captcha")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Authenticate using recovery code
#
# POST /tsv/latest/authenticate/recovery-code
# operationId: authenticateWithRecoveryCode
export def "tsv-latest-authenticate-recovery-code authenticateWithRecoveryCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conversationId: string
  --recoveryCode: string
]: any -> record<next: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tsv/latest/authenticate/recovery-code")
  let body = {conversationId: $conversationId, recoveryCode: $recoveryCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Authenticate using TOTP code
#
# POST /tsv/latest/authenticate/totp-code
# operationId: verifyCode
export def "tsv-latest-authenticate-totp-code verifyCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conversationId: string
  --totpCode: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tsv/latest/authenticate/totp-code")
  let body = {conversationId: $conversationId, totpCode: $totpCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get elevated session status
#
# GET /tsv/latest/elevate-permissions
# operationId: getElevatedPermissionStatus
export def "tsv-latest-elevate-permissions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actionType: string@actionType-completer # The type of action being performed.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actionType" $actionType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tsv/latest/elevate-permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create elevated session with password
#
# POST /tsv/latest/elevate-permissions/password
# operationId: elevatePermissionsWithPassword
export def "tsv-latest-elevate-permissions-password elevatePermissionsWithPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actionType: string@actionType-completer # The type of action being performed.
  --totpCode: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actionType" $actionType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tsv/latest/elevate-permissions/password" $qp)
  let body = {totpCode: $totpCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create elevated session with recovery code
#
# POST /tsv/latest/elevate-permissions/recovery-code
# operationId: elevatePermissionsWithRecoveryCode
export def "tsv-latest-elevate-permissions-recovery-code elevatePermissionsWithRecoveryCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actionType: string@actionType-completer # The type of action being performed.
  --recoveryCode: string
]: any -> record<recoveryCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actionType" $actionType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tsv/latest/elevate-permissions/recovery-code" $qp)
  let body = {recoveryCode: $recoveryCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create elevated session with TOTP
#
# POST /tsv/latest/elevate-permissions/totp
# operationId: elevatePermissionsWithTotp
export def "tsv-latest-elevate-permissions-totp elevatePermissionsWithTotp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actionType: string@actionType-completer # The type of action being performed.
  --totpCode: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actionType" $actionType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tsv/latest/elevate-permissions/totp" $qp)
  let body = {totpCode: $totpCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get SSO management status
#
# GET /tsv/latest/sso-management-status
# operationId: getSsoManagementStatus
export def "tsv-latest-sso-management-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<isManaged: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tsv/latest/sso-management-status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get two-step verification status
#
# GET /tsv/latest/status
# operationId: getStatus
export def "tsv-latest-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<isTwoSVActive: bool, methods: table<enabled: bool, enabledAt: string, enforced: bool, type: string>, twoSVActive: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tsv/latest/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Complete enforced enrollment in 2SV
#
# POST /tsv/latest/totp/complete-enforced-enrollment
# operationId: completeEnforcedEnrollment
export def "tsv-latest-totp-complete-enforced-enrollment completeEnforcedEnrollment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conversationId: string
  --totpCode: string
]: any -> record<recoveryCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tsv/latest/totp/complete-enforced-enrollment")
  let body = {conversationId: $conversationId, totpCode: $totpCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Complete authentication app update for 2SV
#
# POST /tsv/latest/totp/complete-enrollment-update
# operationId: completeAuthenticationChange
export def "tsv-latest-totp-complete-enrollment-update completeAuthenticationChange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conversationId: string
  --totpCode: string
]: any -> record<conversationId: string, secret: string, url: string, userName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tsv/latest/totp/complete-enrollment-update")
  let body = {conversationId: $conversationId, totpCode: $totpCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Complete voluntary enrollment in 2SV
#
# POST /tsv/latest/totp/complete-voluntary-enrollment
# operationId: completeVoluntaryEnrollment
export def "tsv-latest-totp-complete-voluntary-enrollment completeVoluntaryEnrollment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conversationId: string
  --totpCode: string
]: any -> record<conversationId: string, secret: string, url: string, userName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tsv/latest/totp/complete-voluntary-enrollment")
  let body = {conversationId: $conversationId, totpCode: $totpCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Rotate recovery code
#
# POST /tsv/latest/totp/recovery-code/rotate
# operationId: rotateRecoverCode
export def "tsv-latest-totp-recovery-code-rotate rotateRecoverCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<recoveryCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tsv/latest/totp/recovery-code/rotate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start enforced enrollment in 2SV
#
# POST /tsv/latest/totp/start-enforced-enrollment
# operationId: startEnforcedEnrollment
export def "tsv-latest-totp-start-enforced-enrollment startEnforcedEnrollment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conversationId: string
]: any -> record<conversationId: string, secret: string, url: string, userName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tsv/latest/totp/start-enforced-enrollment")
  let body = {conversationId: $conversationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Start authentication app update for 2SV
#
# POST /tsv/latest/totp/start-enrollment-update
# operationId: startEnrollmentUpdate
export def "tsv-latest-totp-start-enrollment-update startEnrollmentUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<conversationId: string, secret: string, url: string, userName: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tsv/latest/totp/start-enrollment-update")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start voluntary enrollment in 2SV
#
# POST /tsv/latest/totp/start-voluntary-enrollment
# operationId: startVoluntaryEnrollment
export def "tsv-latest-totp-start-voluntary-enrollment startVoluntaryEnrollment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<conversationId: string, secret: string, url: string, userName: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tsv/latest/totp/start-voluntary-enrollment")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Uneroll current user from two-step verification
#
# DELETE /tsv/latest/totp/unenroll
# operationId: unenroll
export def "tsv-latest-totp-unenroll unenroll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tsv/latest/totp/unenroll")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unenroll specific user from two-step verification
#
# DELETE /tsv/latest/totp/unenroll/user/{userName}
# operationId: unenrollUser
export def "tsv-latest-totp-unenroll-user unenrollUser" [
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --totpCode: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tsv/latest/totp/unenroll/user/($userName)")
  let body = {totpCode: $totpCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get repository search indexing details.
#
# GET /indexing/latest/projects/{projectKey}/repos/{repositorySlug}
# operationId: getDetails
export def "indexing-latest-projects-repos get" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<indexingError: string, lastIndexedCommitId: string, lastIndexedTimestamp: int, projectKey: string, repositorySlug: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexing/latest/projects/($projectKey)/repos/($repositorySlug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve detailed queue information for a repository
#
# GET /indexing/latest/projects/{projectKey}/repos/{repositorySlug}/indexing-queue-details
# operationId: getQueueDetails
export def "indexing-latest-projects-repos-indexing-queue-details get" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<capturedAt: int, nodeId: string, queued: bool, queuedAt: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexing/latest/projects/($projectKey)/repos/($repositorySlug)/indexing-queue-details")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks if a repository has been queued for indexing.
#
# GET /indexing/latest/projects/{projectKey}/repos/{repositorySlug}/indexing-queued-status
# operationId: indexingQueuedStatus
export def "indexing-latest-projects-repos-indexing-queued-status indexingQueuedStatus" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<queued: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexing/latest/projects/($projectKey)/repos/($repositorySlug)/indexing-queued-status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Re-indexes the search index of the provided list of repositories
#
# POST /indexing/latest/reindex
# operationId: reindexRepositories
export def "indexing-latest-reindex reindexRepositories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/indexing/latest/reindex")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restarts the search indexing worker thread
#
# POST /indexing/latest/restart
# operationId: restartIndexingThreadWorker
export def "indexing-latest-restart restartIndexingThreadWorker" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --gracefulShutdown: oneof<nothing, bool> # Should the indexing thread terminate immediately (default: false, e.g. true)
  --waitForRestart: oneof<nothing, bool> # Should the response wait until the worker has been restarted (default: false, e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/indexing/latest/restart")
  let body = {gracefulShutdown: $gracefulShutdown, waitForRestart: $waitForRestart} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a paged list of repositories which have exceeded the configured maximum indexing retries.
#
# GET /indexing/latest/support-info/broken-index-status-repos
# operationId: getBrokenIndexStatusRepos
export def "indexing-latest-support-info-broken-index-status-repos get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> record<isLastPage: bool, limit: float, nextPageStart: int, size: float, start: int, values: table<details: record, repository: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/indexing/latest/support-info/broken-index-status-repos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a snapshot of the indexing thread details.
#
# GET /indexing/latest/support-info/indexing-thread-snapshot
# operationId: getIndexingThreadSnapshot
export def "indexing-latest-support-info-indexing-thread-snapshot get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<capturedAt: int, currentProcess: record<currentTask: string, event: record>, delayedQueueSize: int, queueSize: int, state: record<code: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/indexing/latest/support-info/indexing-thread-snapshot")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets the desired number of indexing worker threads
#
# PUT /indexing/latest/threads
# operationId: setWorkerThreadCount
export def "indexing-latest-threads setWorkerThreadCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  desiredCount: int # The desired number of indexing worker threads (format: int32, e.g. 4)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/indexing/latest/threads")
  let body = {desiredCount: $desiredCount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get global SSH key settings
#
# GET /admin
# operationId: getGlobalSettings
export def "admin get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update global SSH key settings
#
# PUT /admin
# operationId: updateGlobalSettings
# --keyTypeRestrictions item shape: {algorithm?: string, allowed?: bool, minKeyLength?: int}
export def "admin updateGlobalSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --keyTypeRestrictions: list # item shape: {algorithm?: string, allowed?: bool, minKeyLength?: int}
  --maxExpiryDays: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin")
  let body = {keyTypeRestrictions: $keyTypeRestrictions, maxExpiryDays: $maxExpiryDays} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get supported SSH key algorithms and lengths
#
# GET /admin/supported-key-types
# operationId: getSupportedKeyTypes
export def "admin-supported-key-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/supported-key-types")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get repository SSH keys
#
# GET /keys/latest/projects/{projectKey}/repos/{repositorySlug}/ssh
# operationId: getForRepository_1
export def "keys-latest-projects-repos-ssh get-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only SSH access keys with a label prefixed with the supplied string will be returned
  --effective: string # Controls whether SSH access keys configured at the project level should be included in the results or not. When set to <code>true</code> all keys that have <em>access</em> to the repository (including project level keys) are included in the results. When set to <code>false</code>, only access keys configured for the specified <code>repository</code> are considered. Default is <code>false</code>.
  --minimumPermission: string # If specified only SSH access keys with at least the supplied permission will be returned. Default is <code>Permission.REPO_READ</code>.
  --permission: string
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "effective" $effective "scalar") (serialize-qp "minimumPermission" $minimumPermission "scalar") (serialize-qp "permission" $permission "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/latest/projects/($projectKey)/repos/($repositorySlug)/ssh" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add repository SSH key
#
# POST /keys/latest/projects/{projectKey}/repos/{repositorySlug}/ssh
# operationId: addForRepository
# --key shape: {algorithmType?: string, bitLength?: int, expiryDays?: int, label?: string, text?: string}
# --project shape: {avatar?: string, avatarUrl?: string, key: string, links?: record}
# --repository shape: {defaultBranch?: string, links?: record, name?: string, project?: record, scmId?: string, slug?: string}
export def "keys-latest-projects-repos-ssh addForRepository" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: record # shape: {algorithmType?: string, bitLength?: int, expiryDays?: int, label?: string, text?: string}
  --permission: string@permission-completer-1
  --project: record # shape: {avatar?: string, avatarUrl?: string, key: string, links?: record}
  --repository: record # shape: {defaultBranch?: string, links?: record, name?: string, project?: record, scmId?: string, slug?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/latest/projects/($projectKey)/repos/($repositorySlug)/ssh")
  let body = {key: $key, permission: $permission, project: $project, repository: $repository} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke repository SSH key
#
# DELETE /keys/latest/projects/{projectKey}/repos/{repositorySlug}/ssh/{keyId}
# operationId: revokeForRepository
export def "keys-latest-projects-repos-ssh revokeForRepository" [
  projectKey: string
  keyId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/latest/projects/($projectKey)/repos/($repositorySlug)/ssh/($keyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get repository SSH key
#
# GET /keys/latest/projects/{projectKey}/repos/{repositorySlug}/ssh/{keyId}
# operationId: getForRepository
export def "keys-latest-projects-repos-ssh get" [
  projectKey: string
  keyId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/latest/projects/($projectKey)/repos/($repositorySlug)/ssh/($keyId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update repository SSH key permission
#
# PUT /keys/latest/projects/{projectKey}/repos/{repositorySlug}/ssh/{keyId}/permission/{permission}
# operationId: updatePermission_1
export def "keys-latest-projects-repos-ssh-permission updatePermission-by-projectKey-keyId-permission-repositorySlug" [
  projectKey: string
  keyId: string
  permission: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/latest/projects/($projectKey)/repos/($repositorySlug)/ssh/($keyId)/permission/($permission)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SSH key
#
# GET /keys/latest/projects/{projectKey}/ssh
# operationId: getSshKeysForProject
export def "keys-latest-projects-ssh list" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only SSH access keys with a label prefixed with the supplied string will be returned.
  --permission: string # If specified only SSH access keys with at least the supplied permission will be returned Default is PROJECT_READ.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "permission" $permission "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/latest/projects/($projectKey)/ssh" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add project SSH key
#
# POST /keys/latest/projects/{projectKey}/ssh
# operationId: addForProject
# --key shape: {algorithmType?: string, bitLength?: int, expiryDays?: int, label?: string, text?: string}
# --project shape: {avatar?: string, avatarUrl?: string, key: string, links?: record}
# --repository shape: {defaultBranch?: string, links?: record, name?: string, project?: record, scmId?: string, slug?: string}
export def "keys-latest-projects-ssh addForProject" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: record # shape: {algorithmType?: string, bitLength?: int, expiryDays?: int, label?: string, text?: string}
  --permission: string@permission-completer-1
  --project: record # shape: {avatar?: string, avatarUrl?: string, key: string, links?: record}
  --repository: record # shape: {defaultBranch?: string, links?: record, name?: string, project?: record, scmId?: string, slug?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/latest/projects/($projectKey)/ssh")
  let body = {key: $key, permission: $permission, project: $project, repository: $repository} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke project SSH key
#
# DELETE /keys/latest/projects/{projectKey}/ssh/{keyId}
# operationId: revokeForProject
export def "keys-latest-projects-ssh revokeForProject" [
  projectKey: string
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/latest/projects/($projectKey)/ssh/($keyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project SSH key
#
# GET /keys/latest/projects/{projectKey}/ssh/{keyId}
# operationId: getForProject
export def "keys-latest-projects-ssh get" [
  projectKey: string
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/latest/projects/($projectKey)/ssh/($keyId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update project SSH key permission
#
# PUT /keys/latest/projects/{projectKey}/ssh/{keyId}/permission/{permission}
# operationId: updatePermission
export def "keys-latest-projects-ssh-permission updatePermission" [
  projectKey: string
  keyId: string
  permission: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/latest/projects/($projectKey)/ssh/($keyId)/permission/($permission)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke project SSH key
#
# DELETE /keys/latest/ssh/{keyId}
# operationId: revokeMany
# --projects shape: {avatar?: string, avatarUrl?: string, key?: string, links?: record}
# --repositories shape: {defaultBranch?: string, links?: record, name?: string, project?: record, scmId?: string, slug?: string}
export def "keys-latest-ssh revokeMany" [
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --projects: any # shape: {avatar?: string, avatarUrl?: string, key?: string, links?: record}
  --repositories: any # shape: {defaultBranch?: string, links?: record, name?: string, project?: record, scmId?: string, slug?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/latest/ssh/($keyId)")
  let body = {projects: $projects, repositories: $repositories} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get project SSH keys
#
# GET /keys/latest/ssh/{keyId}/projects
# operationId: getForProjects
export def "keys-latest-ssh-projects get" [
  keyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/latest/ssh/($keyId)/projects")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get repository SSH key
#
# GET /keys/latest/ssh/{keyId}/repos
# operationId: getForRepositories
export def "keys-latest-ssh-repos get" [
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --withRestrictions: string # Include the readOnly field. The `readOnly` field is contextual for the user making the request. `readOnly` returns true if there is a restriction and the user does not have`PROJECT_ADMIN` access for the repository the key is associated with.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withRestrictions" $withRestrictions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/latest/ssh/($keyId)/repos" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete all user SSH key
#
# DELETE /ssh/latest/keys
# operationId: deleteSshKeys
export def "ssh-latest-keys delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userName: string # the username of the user to delete the keys for. If no username is specified, the SSH keys will be deleted for the current authenticated user.
  --user: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $userName "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ssh/latest/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SSH keys for user
#
# GET /ssh/latest/keys
# operationId: getSshKeys
export def "ssh-latest-keys list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userName: string # the username of the user to retrieve the keys for. If no username is specified, the SSH keys will be retrieved for the current authenticated user.
  --user: string
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $userName "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ssh/latest/keys" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add SSH key for user
#
# POST /ssh/latest/keys
# operationId: addSshKey
export def "ssh-latest-keys addSshKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # the username of the user to add the SSH key for. If no username is specified, the SSH key will be added for the current authenticated user.
  --algorithmType: string
  --bitLength: int # format: int32
  --expiryDays: int # format: int32, e.g. 30
  --label: string # e.g. me@127.0.0.1
  --text: string # e.g. ssh-rsa AAAAB3... me@127.0.0.1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ssh/latest/keys" $qp)
  let body = {algorithmType: $algorithmType, bitLength: $bitLength, expiryDays: $expiryDays, label: $label, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove SSH key
#
# DELETE /ssh/latest/keys/{keyId}
# operationId: deleteSshKey
export def "ssh-latest-keys delete-by-keyId" [
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ssh/latest/keys/($keyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SSH key for user by keyId
#
# GET /ssh/latest/keys/{keyId}
# operationId: getSshKey
export def "ssh-latest-keys get" [
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ssh/latest/keys/($keyId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SSH settings
#
# GET /ssh/latest/settings
# operationId: sshSettings
export def "ssh-latest-settings sshSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ssh/latest/settings")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete announcement banner
#
# DELETE /api/latest/admin/banner
# operationId: deleteBanner
export def "latest-admin-banner delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/banner")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get announcement banner
#
# GET /api/latest/admin/banner
# operationId: getBanner
export def "latest-admin-banner get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/banner")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/Set announcement banner
#
# PUT /api/latest/admin/banner
# operationId: setBanner
export def "latest-admin-banner setBanner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  audience: string@audience-completer
  --enabled: oneof<nothing, bool>
  --message: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/banner")
  let body = {audience: $audience, enabled: $enabled, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get cluster node information
#
# GET /api/latest/admin/cluster
# operationId: getInformation
export def "latest-admin-cluster get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/cluster")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clear default branch
#
# DELETE /api/latest/admin/default-branch
# operationId: clearDefaultBranch
export def "latest-admin-default-branch clearDefaultBranch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/default-branch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the default branch
#
# GET /api/latest/admin/default-branch
# operationId: getDefaultBranch
export def "latest-admin-default-branch get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/default-branch")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/Set default branch
#
# PUT /api/latest/admin/default-branch
# operationId: setDefaultBranch
export def "latest-admin-default-branch setDefaultBranch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/default-branch")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the control plane PEM
#
# GET /api/latest/admin/git/mesh/config/control-plane.pem
# operationId: getControlPlanePublicKey
export def "latest-admin-git-mesh-config-control-planepem get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/git/mesh/config/control-plane.pem")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate Mesh connectivity report
#
# GET /api/latest/admin/git/mesh/diagnostics/connectivity
# operationId: connectivity
export def "latest-admin-git-mesh-diagnostics-connectivity connectivity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/git/mesh/diagnostics/connectivity")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all registered Mesh nodes
#
# GET /api/latest/admin/git/mesh/nodes
# operationId: getAllRegisteredMeshNodes
export def "latest-admin-git-mesh-nodes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/git/mesh/nodes")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register new Mesh node
#
# POST /api/latest/admin/git/mesh/nodes
# operationId: registerNewMeshNode
export def "latest-admin-git-mesh-nodes registerNewMeshNode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --availabilityZone: string # e.g. zone-1
  --id: string # e.g. 1
  --lastSeenDate: float # e.g. 1630041546433
  --name: string # e.g. My node
  --offline: oneof<nothing, bool> # e.g. false
  --rpcId: string # e.g. 1
  --rpcUrl: string # e.g. http://127.0.0.1:7999
  --state: string@state-completer-2 # e.g. AVAILABLE
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/git/mesh/nodes")
  let body = {availabilityZone: $availabilityZone, id: $id, lastSeenDate: $lastSeenDate, name: $name, offline: $offline, rpcId: $rpcId, rpcUrl: $rpcUrl, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Mesh node
#
# DELETE /api/latest/admin/git/mesh/nodes/{id}
# operationId: delete_2
export def "latest-admin-git-mesh-nodes delete-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/admin/git/mesh/nodes/($id)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Mesh node
#
# GET /api/latest/admin/git/mesh/nodes/{id}
# operationId: getRegisteredMeshNodeById
export def "latest-admin-git-mesh-nodes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/admin/git/mesh/nodes/($id)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Mesh node
#
# PUT /api/latest/admin/git/mesh/nodes/{id}
# operationId: updateMeshNode
export def "latest-admin-git-mesh-nodes updateMeshNode" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --availabilityZone: string # e.g. zone-1
  --body-id: string # e.g. 1
  --lastSeenDate: float # e.g. 1630041546433
  --name: string # e.g. My node
  --offline: oneof<nothing, bool> # e.g. false
  --rpcId: string # e.g. 1
  --rpcUrl: string # e.g. http://127.0.0.1:7999
  --state: string@state-completer-2 # e.g. AVAILABLE
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/admin/git/mesh/nodes/($id)")
  let body = {availabilityZone: $availabilityZone, id: $body_id, lastSeenDate: $lastSeenDate, name: $name, offline: $offline, rpcId: $rpcId, rpcUrl: $rpcUrl, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get support zips for all Mesh nodes
#
# GET /api/latest/admin/git/mesh/support-zips
# operationId: getSupportZips
export def "latest-admin-git-mesh-support-zips list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/git/mesh/support-zips")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get support zip for node
#
# GET /api/latest/admin/git/mesh/support-zips/{id}
# operationId: getSupportZip
export def "latest-admin-git-mesh-support-zips get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/admin/git/mesh/support-zips/($id)")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove group
#
# DELETE /api/latest/admin/groups
# operationId: deleteGroup
export def "latest-admin-groups delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name identifying the group to delete.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/groups" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get groups
#
# GET /api/latest/admin/groups
# operationId: getGroups_1
export def "latest-admin-groups get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only group names containing the supplied string will be returned.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/groups" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create group
#
# POST /api/latest/admin/groups
# operationId: createGroup
export def "latest-admin-groups createGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the group.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/groups" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add user to group
#
# POST /api/latest/admin/groups/add-user
# DEPRECATED
# operationId: addUserToGroup
@deprecated
export def "latest-admin-groups-add-user addUserToGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --context: string # e.g. group_a
  --itemName: string # e.g. user_a
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/groups/add-user")
  let body = {context: $context, itemName: $itemName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add multiple users to group
#
# POST /api/latest/admin/groups/add-users
# operationId: addUsersToGroup
export def "latest-admin-groups-add-users addUsersToGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group: string # e.g. group
  users: list # e.g. [user1, user2]
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/groups/add-users")
  let body = {group: $group, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get group members
#
# GET /api/latest/admin/groups/more-members
# operationId: findUsersInGroup
export def "latest-admin-groups-more-members findUsersInGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only users with usernames, display names or email addresses containing the supplied string will be returned.
  --context: string # The group which should be used to locate members.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "context" $context "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/groups/more-members" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get members not in group
#
# GET /api/latest/admin/groups/more-non-members
# operationId: findUsersNotInGroup
export def "latest-admin-groups-more-non-members findUsersNotInGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only users with usernames, display names or email addresses containing the supplied string will be returned.
  --context: string # The group which should be used to locate members.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "context" $context "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/groups/more-non-members" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove user from group
#
# POST /api/latest/admin/groups/remove-user
# DEPRECATED
# operationId: removeUserFromGroup
@deprecated
export def "latest-admin-groups-remove-user removeUserFromGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --context: string # e.g. group_a
  --itemName: string # e.g. user_a
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/groups/remove-user")
  let body = {context: $context, itemName: $itemName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get license details
#
# GET /api/latest/admin/license
# operationId: get_2
export def "latest-admin-license get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/license")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update license
#
# POST /api/latest/admin/license
# operationId: updateLicense
# --status shape: {currentNumberOfUsers?: int, serverId?: string}
export def "latest-admin-license updateLicense" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --license: string # e.g. <encoded license text>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/license")
  let body = {license: $license} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete mail configuration
#
# DELETE /api/latest/admin/mail-server
# operationId: deleteMailConfig
export def "latest-admin-mail-server delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/mail-server")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get mail configuration
#
# GET /api/latest/admin/mail-server
# operationId: getMailConfig
export def "latest-admin-mail-server get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/mail-server")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update mail configuration
#
# PUT /api/latest/admin/mail-server
# operationId: setMailConfig
export def "latest-admin-mail-server setMailConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authType: string@authType-completer
  --hostname: string # e.g. smtp.example.com
  --oauth2ProviderId: string
  --password: string # e.g. password
  --port: int # format: int32, e.g. 465
  --protocol: string@protocol-completer
  --requireStartTls: oneof<nothing, bool>
  --senderAddress: string # e.g. stash-no-reply@company.com
  --tokenId: string
  --useStartTls: oneof<nothing, bool>
  --username: string # e.g. user
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/mail-server")
  let body = {authType: $authType, hostname: $hostname, oauth2ProviderId: $oauth2ProviderId, password: $password, port: $port, protocol: $protocol, requireStartTls: $requireStartTls, senderAddress: $senderAddress, tokenId: $tokenId, useStartTls: $useStartTls, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update mail configuration
#
# DELETE /api/latest/admin/mail-server/sender-address
# operationId: clearSenderAddress
export def "latest-admin-mail-server-sender-address clearSenderAddress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/mail-server/sender-address")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get server mail address
#
# GET /api/latest/admin/mail-server/sender-address
# operationId: getSenderAddress
export def "latest-admin-mail-server-sender-address get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/mail-server/sender-address")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update server mail address
#
# PUT /api/latest/admin/mail-server/sender-address
# operationId: setSenderAddress
export def "latest-admin-mail-server-sender-address setSenderAddress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/mail-server/sender-address")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke all global permissions for group
#
# DELETE /api/latest/admin/permissions/groups
# operationId: revokePermissionsForGroup
export def "latest-admin-permissions-groups revokePermissionsForGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the group
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/permissions/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get groups with a global permission
#
# GET /api/latest/admin/permissions/groups
# operationId: getGroupsWithAnyPermission
export def "latest-admin-permissions-groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only group names containing the supplied string will be returned
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/permissions/groups" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update global permission for group
#
# PUT /api/latest/admin/permissions/groups
# operationId: setPermissionForGroups
export def "latest-admin-permissions-groups setPermissionForGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: list # The names of the groups
  --permission: string@permission-completer-2 # The permission to grant
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "multi") (serialize-qp "permission" $permission "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/permissions/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get groups with no global permission
#
# GET /api/latest/admin/permissions/groups/none
# operationId: getGroupsWithoutAnyPermission
export def "latest-admin-permissions-groups-none get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only user names containing the supplied string will be returned
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/permissions/groups/none" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke all global permissions for user
#
# DELETE /api/latest/admin/permissions/users
# operationId: revokePermissionsForUser
export def "latest-admin-permissions-users revokePermissionsForUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the user
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/permissions/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get users with a global permission
#
# GET /api/latest/admin/permissions/users
# operationId: getUsersWithAnyPermission
export def "latest-admin-permissions-users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only user names containing the supplied string will be returned
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/permissions/users" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update global permission for user
#
# PUT /api/latest/admin/permissions/users
# operationId: setPermissionForUsers
export def "latest-admin-permissions-users setPermissionForUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: list # The names of the users
  --permission: string@permission-completer-2 # The permission to grant
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "multi") (serialize-qp "permission" $permission "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/permissions/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get users with no global permission
#
# GET /api/latest/admin/permissions/users/none
# operationId: getUsersWithoutAnyPermission
export def "latest-admin-permissions-users-none get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only user names containing the supplied string will be returned
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/permissions/users/none" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get merge strategies
#
# GET /api/latest/admin/pull-requests/{scmId}
# operationId: getMergeConfig
export def "latest-admin-pull-requests get" [
  scmId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/admin/pull-requests/($scmId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update merge strategies
#
# POST /api/latest/admin/pull-requests/{scmId}
# operationId: setMergeConfig
# --mergeConfig shape: {commitMessageTemplate?: record, commitSummaries?: int, defaultStrategy?: record, strategies: list}
export def "latest-admin-pull-requests setMergeConfig" [
  scmId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mergeConfig: record # shape: {commitMessageTemplate?: record, commitSummaries?: int, defaultStrategy?: record, strategies: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/admin/pull-requests/($scmId)")
  let body = {mergeConfig: $mergeConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get rate limit history
#
# GET /api/latest/admin/rate-limit/history
# operationId: getHistory
export def "latest-admin-rate-limit-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer # An optional sort category to arrange the results in descending order
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/rate-limit/history" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get rate limit settings
#
# GET /api/latest/admin/rate-limit/settings
# operationId: getSettings_3
export def "latest-admin-rate-limit-settings get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/rate-limit/settings")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set rate limit
#
# PUT /api/latest/admin/rate-limit/settings
# operationId: setSettings_3
# --defaultSettings shape: {capacity?: int, fillRate?: int}
export def "latest-admin-rate-limit-settings setSettings-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --defaultSettings: record # shape: {capacity?: int, fillRate?: int}
  --enabled: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/rate-limit/settings")
  let body = {defaultSettings: $defaultSettings, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get rate limit settings for user
#
# GET /api/latest/admin/rate-limit/settings/users
# operationId: getAllRateLimitSettings
export def "latest-admin-rate-limit-settings-users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Optional filter
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/rate-limit/settings/users" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set rate limit settings for users
#
# POST /api/latest/admin/rate-limit/settings/users
# operationId: set_2
# --settings shape: {capacity?: int, fillRate?: int}
export def "latest-admin-rate-limit-settings-users set-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --settings: record # shape: {capacity?: int, fillRate?: int}
  usernames: list
  --whitelisted: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/rate-limit/settings/users")
  let body = {settings: $settings, usernames: $usernames, whitelisted: $whitelisted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete user specific rate limit settings
#
# DELETE /api/latest/admin/rate-limit/settings/users/{userSlug}
# operationId: delete_8
export def "latest-admin-rate-limit-settings-users delete-by-userSlug" [
  userSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/admin/rate-limit/settings/users/($userSlug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user specific rate limit settings
#
# GET /api/latest/admin/rate-limit/settings/users/{userSlug}
# operationId: get_6
export def "latest-admin-rate-limit-settings-users get-by-userSlug" [
  userSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/admin/rate-limit/settings/users/($userSlug)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set rate limit settings for user
#
# PUT /api/latest/admin/rate-limit/settings/users/{userSlug}
# operationId: set_3
# --settings shape: {capacity?: int, fillRate?: int}
export def "latest-admin-rate-limit-settings-users set-by-userSlug" [
  userSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --settings: record # shape: {capacity?: int, fillRate?: int}
  --whitelisted: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/admin/rate-limit/settings/users/($userSlug)")
  let body = {settings: $settings, whitelisted: $whitelisted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get directories
#
# GET /api/latest/admin/user-directories
# operationId: getUserDirectories
export def "latest-admin-user-directories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeInactive: string # Set <code>true</code> to include inactive directories; otherwise, <code>false</code> to only return active directories.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeInactive" $includeInactive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/user-directories" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove user
#
# DELETE /api/latest/admin/users
# operationId: deleteUser
export def "latest-admin-users delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The username identifying the user to delete.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/users" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get users
#
# GET /api/latest/admin/users
# operationId: getUsers_1
export def "latest-admin-users get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only users with usernames, display name or email addresses containing the supplied string will be returned.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/users" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create user
#
# POST /api/latest/admin/users
# operationId: createUser
export def "latest-admin-users createUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --emailAddress: string # The e-mail address for the new user.
  --password: string # The password for the new user. Required if the <code>notify</code> parameter is not present or is set to <code>false</false>
  --addToDefaultGroup: oneof<nothing, bool> # Set <code>true</code> to add the user to the default group, which can be used to grant them a set of initial permissions; otherwise, <code>false</code> to not add them to a group. (default: true)
  --displayName: string # The display name for the new user.
  --name: string # The username for the new user.
  --notify: oneof<nothing, bool> # If present and not <code>false</code> instead of requiring a password, the create user will be notified via email their account has been created and requires a password to be reset. This option can only be used if a mail server has been configured.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "emailAddress" $emailAddress "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "addToDefaultGroup" $addToDefaultGroup "scalar") (serialize-qp "displayName" $displayName "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "notify" $notify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user details
#
# PUT /api/latest/admin/users
# operationId: updateUserDetails
export def "latest-admin-users updateUserDetails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string # e.g. Jane Citizen
  --email: string # e.g. jane@example.com
  --name: string # e.g. jcitizen
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/users")
  let body = {displayName: $displayName, email: $email, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add user to group
#
# POST /api/latest/admin/users/add-group
# DEPRECATED
# operationId: addGroupToUser
@deprecated
export def "latest-admin-users-add-group addGroupToUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --context: string # e.g. user_a
  --itemName: string # e.g. group_a
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/users/add-group")
  let body = {context: $context, itemName: $itemName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add user to groups
#
# POST /api/latest/admin/users/add-groups
# operationId: addUserToGroups
export def "latest-admin-users-add-groups addUserToGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  groups: list # e.g. [group_a, group_b]
  --user: string # e.g. user
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/users/add-groups")
  let body = {groups: $groups, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Clear CAPTCHA for user
#
# DELETE /api/latest/admin/users/captcha
# operationId: clearUserCaptchaChallenge
export def "latest-admin-users-captcha clearUserCaptchaChallenge" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The username
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/users/captcha" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set password for user
#
# PUT /api/latest/admin/users/credentials
# operationId: updateUserPassword
export def "latest-admin-users-credentials updateUserPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # e.g. jcitizen
  --password: string # e.g. my-secret-password
  --passwordConfirm: string # e.g. my-secret-password
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/users/credentials")
  let body = {name: $name, password: $password, passwordConfirm: $passwordConfirm} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Check user removal
#
# GET /api/latest/admin/users/erasure
# operationId: validateErasable
export def "latest-admin-users-erasure validateErasable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The username of the user to validate erasability for.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/users/erasure" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Erase user information
#
# POST /api/latest/admin/users/erasure
# operationId: eraseUser
export def "latest-admin-users-erasure eraseUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The username identifying the user to erase.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/users/erasure" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get groups for user
#
# GET /api/latest/admin/users/more-members
# operationId: findGroupsForUser
export def "latest-admin-users-more-members findGroupsForUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only users with usernames, display names or email addresses containing the supplied string will be returned.
  --context: string # The group which should be used to locate members.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "context" $context "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/users/more-members" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find other groups for user
#
# GET /api/latest/admin/users/more-non-members
# operationId: findOtherGroupsForUser
export def "latest-admin-users-more-non-members findOtherGroupsForUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only groups with names containing the supplied string will be returned.
  --context: string # The user which should be used to locate groups.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "context" $context "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/admin/users/more-non-members" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove user from group
#
# POST /api/latest/admin/users/remove-group
# operationId: removeGroupFromUser
export def "latest-admin-users-remove-group removeGroupFromUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --context: string # e.g. user_a
  --itemName: string # e.g. group_a
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/users/remove-group")
  let body = {context: $context, itemName: $itemName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Rename user
#
# POST /api/latest/admin/users/rename
# operationId: renameUser
export def "latest-admin-users-rename renameUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # e.g. jcitizen
  --newName: string # e.g. jcitizen-new
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/admin/users/rename")
  let body = {name: $name, newName: $newName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get application properties
#
# GET /api/latest/application-properties
# operationId: getApplicationProperties
export def "latest-application-properties get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/application-properties")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get build capabilities
#
# GET /api/latest/build/capabilities
# operationId: getCapabilities
export def "latest-build-capabilities get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/build/capabilities")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pull request suggestions
#
# GET /api/latest/dashboard/pull-request-suggestions
# operationId: getPullRequestSuggestions
export def "latest-dashboard-pull-request-suggestions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --changesSince: string # restrict pull request suggestions to be based on events that occurred since some timein the past. This is expressed in seconds since "now". So to return suggestionsbased only on activity within the past 48 hours, pass a value of 172800.
  --limit: string # restricts the result set to return at most this many suggestions.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "changesSince" $changesSince "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/dashboard/pull-request-suggestions" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pull requests for a user
#
# GET /api/latest/dashboard/pull-requests
# operationId: getPullRequests_1
export def "latest-dashboard-pull-requests get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --closedSince: string # (optional, defaults to returning pull requests regardless of closed since date). Permits returning only pull requests with a closed timestamp set more recently that (now - closedSince). Units are in seconds. So for example if closed since 86400 is set only pull requests closed in the previous 24 hours will be returned.
  --role: string # (optional, defaults to returning pull requests for any role). If a role is supplied only pull requests where the authenticated user is a participant in the given role will be returned. Either <strong>REVIEWER</strong>, <strong>AUTHOR</strong> or <strong>PARTICIPANT</strong>.
  --participantStatus: string # (optional, defaults to returning pull requests with any participant status). A comma separated list of participant status. That is, one or more of <strong>UNAPPROVED</strong>, <strong>NEEDS_WORK</strong>, or <strong>APPROVED</strong>.
  --state: string # (optional, defaults to returning pull requests in any state). If a state is supplied only pull requests in the specified state will be returned. Either <strong>OPEN</strong>, <strong>DECLINED</strong> or <strong>MERGED</strong>. Omit this parameter to return pull request in any state.
  --user: string # The name of the involved user, defaults to the current user.
  --order: string # (optional, defaults to <strong>NEWEST</strong>) the order/(s) to return pull requests in; can choose from <strong>OLDEST</strong> (as in: "oldest first"), <strong>NEWEST</strong>, <strong>DRAFT_STATUS</strong>, <strong>PARTICIPANT_STATUS</strong>, and/or <strong>CLOSED_DATE</strong>. Where <strong>CLOSED_DATE</strong> is specified and the result set includes pull requests that are not in the closed state, these pull requests will appear first in the result set, followed by most recently closed pull requests.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "closedSince" $closedSince "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "participantStatus" $participantStatus "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/dashboard/pull-requests" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get deployment capabilities
#
# GET /api/latest/deployment/capabilities
# operationId: getCapabilities_1
export def "latest-deployment-capabilities get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/deployment/capabilities")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get group names
#
# GET /api/latest/groups
# operationId: getGroups
export def "latest-groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/groups" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new hook script
#
# POST /api/latest/hook-scripts
# operationId: createHookScript
export def "latest-hook-scripts createHookScript" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # The hook script contents.
  --description: string # A description of the hook script (useful when querying registered hook scripts).
  --name: string # The name of the hook script (useful when querying registered hook scripts).
  --type: string # The type of hook script; supported values are "PRE" for pre-receive hooks and "POST" for post-receive hooks.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/hook-scripts")
  let body = {content: $content, description: $description, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Delete a hook script.
#
# DELETE /api/latest/hook-scripts/{scriptId}
# operationId: deleteHookScript
export def "latest-hook-scripts delete" [
  scriptId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/hook-scripts/($scriptId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a hook script
#
# GET /api/latest/hook-scripts/{scriptId}
# operationId: getHookScript
export def "latest-hook-scripts get" [
  scriptId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/hook-scripts/($scriptId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a hook script
#
# PUT /api/latest/hook-scripts/{scriptId}
# operationId: updateHookScript
export def "latest-hook-scripts updateHookScript" [
  scriptId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/hook-scripts/($scriptId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $body
}

# Get hook script content
#
# GET /api/latest/hook-scripts/{scriptId}/content
# operationId: read
export def "latest-hook-scripts-content read" [
  scriptId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/hook-scripts/($scriptId)/content")
  let accept_val = ($accept | default "application/octet-stream")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project avatar
#
# GET /api/latest/hooks/{hookKey}/avatar
# operationId: getAvatar
export def "latest-hooks-avatar get" [
  hookKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # (optional) Version used for HTTP caching only - any non-blank version will result in a large max-age Cache-Control header. Note that this does not affect the Last-Modified header.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/hooks/($hookKey)/avatar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pull requests in inbox
#
# GET /api/latest/inbox/pull-requests
# operationId: getPullRequests_2
export def "latest-inbox-pull-requests get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string # default: reviewer
  --limit: int # format: int32, default: 25
  --start: int # format: int32, default: 0
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/inbox/pull-requests" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get total number of pull requests in inbox
#
# GET /api/latest/inbox/pull-requests/count
# operationId: getPullRequestCount
export def "latest-inbox-pull-requests-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/inbox/pull-requests/count")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all labels
#
# GET /api/latest/labels
# operationId: getLabels
export def "latest-labels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --prefix: string # (optional) prefix to filter the labels on.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prefix" $prefix "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/labels" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get label
#
# GET /api/latest/labels/{labelName}
# operationId: getLabel
export def "latest-labels get" [
  labelName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/labels/($labelName)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get labelables for label
#
# GET /api/latest/labels/{labelName}/labeled
# operationId: getLabelables
export def "latest-labels-labeled get" [
  labelName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string #  the type of labelables to be returned. Supported values: REPOSITORY
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/labels/($labelName)/labeled" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get current log level
#
# GET /api/latest/logs/logger/{loggerName}
# operationId: getLevel
export def "latest-logs-logger get" [
  loggerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/logs/logger/($loggerName)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set log level
#
# PUT /api/latest/logs/logger/{loggerName}/{levelName}
# operationId: setLevel
export def "latest-logs-logger setLevel" [
  levelName: string
  loggerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/logs/logger/($loggerName)/($levelName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get root log level
#
# GET /api/latest/logs/rootLogger
# operationId: getRootLevel
export def "latest-logs-root-logger get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/logs/rootLogger")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set root log level
#
# PUT /api/latest/logs/rootLogger/{levelName}
# operationId: setRootLevel
export def "latest-logs-root-logger setRootLevel" [
  levelName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/logs/rootLogger/($levelName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get debug logging and profiling
#
# GET /api/latest/logs/settings
# operationId: getSettings_2
export def "latest-logs-settings get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/logs/settings")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set debug logging and profiling
#
# PUT /api/latest/logs/settings
# operationId: setSettings_2
export def "latest-logs-settings setSettings-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --debugLoggingEnabled: oneof<nothing, bool> # e.g. false
  --profilingEnabled: oneof<nothing, bool> # e.g. false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/logs/settings")
  let body = {debugLoggingEnabled: $debugLoggingEnabled, profilingEnabled: $profilingEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Preview markdown render
#
# POST /api/latest/markup/preview
# operationId: preview
export def "latest-markup-preview preview" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --htmlEscape: string # (Optional) true if HTML should be escaped in the input markup, false otherwise.
  --urlMode: string # (Optional) The mode to use when building URLs. One of: ABSOLUTE, RELATIVE or, CONFIGURED. By default this is RELATIVE.
  --includeHeadingId: string # (Optional) true if headers should contain an ID based on the heading content.
  --hardwrap: string # (Optional) Whether the markup implementation should convert newlines to breaks. By default this is false which reflects the standard markdown specification.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "htmlEscape" $htmlEscape "scalar") (serialize-qp "urlMode" $urlMode "scalar") (serialize-qp "includeHeadingId" $includeHeadingId "scalar") (serialize-qp "hardwrap" $hardwrap "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/markup/preview" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $body
}

# Start export job
#
# POST /api/latest/migration/exports
# operationId: startExport
# --repositoriesRequest shape: {includes: list}
export def "latest-migration-exports startExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --exportLocation: string # e.g. example/sub/directory
  repositoriesRequest: record # shape: {includes: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/migration/exports")
  let body = {exportLocation: $exportLocation, repositoriesRequest: $repositoriesRequest} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Preview export
#
# POST /api/latest/migration/exports/preview
# operationId: previewExport
# --repositoriesRequest shape: {includes: list}
export def "latest-migration-exports-preview previewExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --exportLocation: string # e.g. example/sub/directory
  repositoriesRequest: record # shape: {includes: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/migration/exports/preview")
  let body = {exportLocation: $exportLocation, repositoriesRequest: $repositoriesRequest} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get export job details
#
# GET /api/latest/migration/exports/{jobId}
# operationId: getExportJob
export def "latest-migration-exports get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/migration/exports/($jobId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel export job
#
# POST /api/latest/migration/exports/{jobId}/cancel
# operationId: cancelExportJob
export def "latest-migration-exports-cancel cancelExportJob" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/migration/exports/($jobId)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get job messages
#
# GET /api/latest/migration/exports/{jobId}/messages
# operationId: getExportJobMessages
export def "latest-migration-exports-messages get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --severity: string # The severity to include in the results
  --subject: string # The subject
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "severity" $severity "scalar") (serialize-qp "subject" $subject "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/migration/exports/($jobId)/messages" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start import job
#
# POST /api/latest/migration/imports
# operationId: startImport
export def "latest-migration-imports startImport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --archivePath: string # e.g. Bitbucket_export_1.tar
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/migration/imports")
  let body = {archivePath: $archivePath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get import job status
#
# GET /api/latest/migration/imports/{jobId}
# operationId: getImportJob
export def "latest-migration-imports get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/migration/imports/($jobId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel import job
#
# POST /api/latest/migration/imports/{jobId}/cancel
# operationId: cancelImportJob
export def "latest-migration-imports-cancel cancelImportJob" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/migration/imports/($jobId)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get import job messages
#
# GET /api/latest/migration/imports/{jobId}/messages
# operationId: getImportJobMessages
export def "latest-migration-imports-messages get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --severity: string # The severity to include in the results
  --subject: string # The subject
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "severity" $severity "scalar") (serialize-qp "subject" $subject "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/migration/imports/($jobId)/messages" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start Mesh migration job
#
# POST /api/latest/migration/mesh
# operationId: startMeshMigration
export def "latest-migration-mesh startMeshMigration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool>
  projectIds: list
  repositoryIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/migration/mesh")
  let body = {all: $all, projectIds: $projectIds, repositoryIds: $repositoryIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Preview Mesh migration
#
# POST /api/latest/migration/mesh/preview
# operationId: previewMeshMigration
export def "latest-migration-mesh-preview previewMeshMigration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool>
  projectIds: list
  repositoryIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/migration/mesh/preview")
  let body = {all: $all, projectIds: $projectIds, repositoryIds: $repositoryIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Find repositories by Mesh migration state
#
# GET /api/latest/migration/mesh/repos
# operationId: searchMeshMigrationRepos
export def "latest-migration-mesh-repos searchMeshMigrationRepos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --migrationId: string # (optional) The currently active migration job. If not passed, this is looked up internally.
  --projectKey: string # (optional) The project key. Can be specified more than once to filter by more than one project.
  --name: string # (optional) The repository name
  --state: string # (optional) If a migration is active, the MeshMigrationQueueState state to filter results by. Can be specified more than once to filter by more than one state.
  --remote: string # (optional) Whether the repository has been fully migrated to Mesh. If not present, all repositories are considered regardless of where they're located.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "migrationId" $migrationId "scalar") (serialize-qp "projectKey" $projectKey "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "remote" $remote "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/migration/mesh/repos" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all Mesh migration job summaries
#
# GET /api/latest/migration/mesh/summaries
# operationId: getAllMeshMigrationSummaries
export def "latest-migration-mesh-summaries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/migration/mesh/summaries" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get summary for Mesh migration job
#
# GET /api/latest/migration/mesh/summary
# operationId: getActiveMeshMigrationSummary
export def "latest-migration-mesh-summary list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/migration/mesh/summary")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Mesh migration job details
#
# GET /api/latest/migration/mesh/{jobId}
# operationId: getMeshMigrationJob
export def "latest-migration-mesh get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/migration/mesh/($jobId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel Mesh migration job
#
# POST /api/latest/migration/mesh/{jobId}/cancel
# operationId: cancelMeshMigrationJob
export def "latest-migration-mesh-cancel cancelMeshMigrationJob" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/migration/mesh/($jobId)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Mesh migration job messages
#
# GET /api/latest/migration/mesh/{jobId}/messages
# operationId: getMeshMigrationJobMessages
export def "latest-migration-mesh-messages get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --severity: string # The severity to include in the results
  --subject: string # The subject
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "severity" $severity "scalar") (serialize-qp "subject" $subject "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/migration/mesh/($jobId)/messages" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Mesh migration job summary
#
# GET /api/latest/migration/mesh/{jobId}/summary
# operationId: getMeshMigrationJobSummary
export def "latest-migration-mesh-summary get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/migration/mesh/($jobId)/summary")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get recently accessed repositories
#
# GET /api/latest/profile/recent/repos
# operationId: getRepositoriesRecentlyAccessed
export def "latest-profile-recent-repos get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permission: string # (optional) If specified, it must be a valid repository permission level name and will limit the resulting repository list to ones that the requesting user has the specified permission level to. If not specified, the default <code>REPO_READ</code> permission level will be assumed. (default: REPO_READ)
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permission" $permission "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/profile/recent/repos" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get projects
#
# GET /api/latest/projects
# operationId: getProjects
export def "latest-projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name to filter by.
  --permission: string # Permission to filter by
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "permission" $permission "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/projects" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new project
#
# POST /api/latest/projects
# operationId: createProject
export def "latest-projects createProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatar: string
  --avatarUrl: string
  --key: string # e.g. PRJ
  --links: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/projects")
  let body = {avatar: $avatar, avatarUrl: $avatarUrl, key: $key, links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete project
#
# DELETE /api/latest/projects/{projectKey}
# operationId: deleteProject
export def "latest-projects delete" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a project
#
# GET /api/latest/projects/{projectKey}
# operationId: getProject
export def "latest-projects get" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update project
#
# PUT /api/latest/projects/{projectKey}
# operationId: updateProject
export def "latest-projects updateProject" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatar: string
  --avatarUrl: string
  --key: string # e.g. PRJ
  --links: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)")
  let body = {avatar: $avatar, avatarUrl: $avatarUrl, key: $key, links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get avatar for project
#
# GET /api/latest/projects/{projectKey}/avatar.png
# operationId: getProjectAvatar
export def "latest-projects-avatarpng get" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --s: string # The desired size of the image. The server will return an image as close as possible to the specified size.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "s" $s "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/avatar.png" $qp)
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update project avatar
#
# POST /api/latest/projects/{projectKey}/avatar.png
# operationId: uploadAvatar
export def "latest-projects-avatarpng uploadAvatar" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatar: string # The avatar file to upload. (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/avatar.png")
  let body = {avatar: $avatar} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get configured hook scripts
#
# GET /api/latest/projects/{projectKey}/hook-scripts
# operationId: getConfigurations
export def "latest-projects-hook-scripts get" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/hook-scripts" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a hook script
#
# DELETE /api/latest/projects/{projectKey}/hook-scripts/{scriptId}
# operationId: removeConfiguration
export def "latest-projects-hook-scripts removeConfiguration" [
  projectKey: string
  scriptId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/hook-scripts/($scriptId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create/update a hook script
#
# PUT /api/latest/projects/{projectKey}/hook-scripts/{scriptId}
# operationId: setConfiguration
export def "latest-projects-hook-scripts setConfiguration" [
  projectKey: string
  scriptId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  triggerIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/hook-scripts/($scriptId)")
  let body = {triggerIds: $triggerIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke project permissions
#
# DELETE /api/latest/projects/{projectKey}/permissions
# operationId: revokePermissions
export def "latest-projects-permissions revokePermissions" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # The names of the users
  --group: string # The names of the groups
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar") (serialize-qp "group" $group "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke group project permission
#
# DELETE /api/latest/projects/{projectKey}/permissions/groups
# operationId: revokePermissionsForGroup_1
export def "latest-projects-permissions-groups revokePermissionsForGroup-by-projectKey" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the group
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/permissions/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get groups with permission to project
#
# GET /api/latest/projects/{projectKey}/permissions/groups
# operationId: getGroupsWithAnyPermission_1
export def "latest-projects-permissions-groups get-by-projectKey" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only group names containing the supplied string will be returned
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/permissions/groups" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update group project permission
#
# PUT /api/latest/projects/{projectKey}/permissions/groups
# operationId: setPermissionForGroups_1
export def "latest-projects-permissions-groups setPermissionForGroups-by-projectKey" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The names of the groups
  --permission: string # The permission to grant.See the [permissions documentation](https://confluence.atlassian.com/display/BitbucketServer/Using+project+permissions)for a detailed explanation of what each permission entails. Available project permissions are:  - PROJECT_READ - PROJECT_WRITE - PROJECT_ADMIN  
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "permission" $permission "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/permissions/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get groups without project permission
#
# GET /api/latest/projects/{projectKey}/permissions/groups/none
# operationId: getGroupsWithoutAnyPermission_1
export def "latest-projects-permissions-groups-none get-by-projectKey" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only group names containing the supplied string will be returned
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/permissions/groups/none" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search project permissions
#
# GET /api/latest/projects/{projectKey}/permissions/search
# operationId: searchPermissions
export def "latest-projects-permissions-search searchPermissions" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permission: string # Permissions to filter by. See the [permissions documentation](https://confluence.atlassian.com/display/BitbucketServer/Using+project+permissions)for a detailed explanation of what each permission entails. This parameter can be specified multiple times to filter by more than one permission, and can contain global and project permissions. 
  --filterText: string # Name of the user or group to filter the name of
  --type: string # Type of entity (user or group)Valid entity types are:  - USER- GROUP
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permission" $permission "scalar") (serialize-qp "filterText" $filterText "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/permissions/search" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke user project permission
#
# DELETE /api/latest/projects/{projectKey}/permissions/users
# operationId: revokePermissionsForUser_1
export def "latest-projects-permissions-users revokePermissionsForUser-by-projectKey" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the user
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/permissions/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get users with permission to project
#
# GET /api/latest/projects/{projectKey}/permissions/users
# operationId: getUsersWithAnyPermission_1
export def "latest-projects-permissions-users get-by-projectKey" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only user names containing the supplied string will be returned
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/permissions/users" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user project permission
#
# PUT /api/latest/projects/{projectKey}/permissions/users
# operationId: setPermissionForUsers_1
export def "latest-projects-permissions-users setPermissionForUsers-by-projectKey" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The names of the users
  --permission: string # The permission to grant.See the [permissions documentation](https://confluence.atlassian.com/display/BitbucketServer/Using+project+permissions)for a detailed explanation of what each permission entails. Available project permissions are:  - PROJECT_READ - PROJECT_WRITE - PROJECT_ADMIN  
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "permission" $permission "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/permissions/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get users without project permission
#
# GET /api/latest/projects/{projectKey}/permissions/users/none
# operationId: getUsersWithoutPermission
export def "latest-projects-permissions-users-none get" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only user names containing the supplied string will be returned
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/permissions/users/none" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check default project permission
#
# GET /api/latest/projects/{projectKey}/permissions/{permission}/all
# operationId: hasAllUserPermission
export def "latest-projects-permissions-all hasAllUserPermission" [
  projectKey: string
  permission: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/permissions/($permission)/all")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Grant project permission
#
# POST /api/latest/projects/{projectKey}/permissions/{permission}/all
# operationId: modifyAllUserPermission
export def "latest-projects-permissions-all modifyAllUserPermission" [
  projectKey: string
  permission: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow: string # <em>true</em> to grant the specified permission to all users, or <em>false</em> to revoke it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allow" $allow "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/permissions/($permission)/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get repositories for project
#
# GET /api/latest/projects/{projectKey}/repos
# operationId: getRepositories
export def "latest-projects-repos list" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create repository
#
# POST /api/latest/projects/{projectKey}/repos
# operationId: createRepository
# --origin shape: {defaultBranch?: string, links?: record, name?: string, project?: record, scmId?: string, slug?: string}
# --project shape: {avatar?: string, avatarUrl?: string, key: string, links?: record}
export def "latest-projects-repos createRepository" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --defaultBranch: string # e.g. main
  --links: record
  --name: string # e.g. My repo
  --project: record # shape: {avatar?: string, avatarUrl?: string, key: string, links?: record}
  --scmId: string # e.g. git
  --slug: string # e.g. my-repo
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos")
  let body = {defaultBranch: $defaultBranch, links: $links, name: $name, project: $project, scmId: $scmId, slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete repository
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}
# operationId: deleteRepository
export def "latest-projects-repos delete" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)")
  let accept_val = ($accept | default "application/json;charset=UTF-8")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get repository
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}
# operationId: getRepository
export def "latest-projects-repos get" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fork repository
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}
# operationId: forkRepository
# --origin shape: {defaultBranch?: string, links?: record, name?: string, project?: record, scmId?: string, slug?: string}
# --project shape: {avatar?: string, avatarUrl?: string, key: string, links?: record}
export def "latest-projects-repos forkRepository" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --defaultBranch: string # e.g. main
  --links: record
  --name: string # e.g. My repo
  --project: record # shape: {avatar?: string, avatarUrl?: string, key: string, links?: record}
  --scmId: string # e.g. git
  --slug: string # e.g. my-repo
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)")
  let body = {defaultBranch: $defaultBranch, links: $links, name: $name, project: $project, scmId: $scmId, slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update repository
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}
# operationId: updateRepository
# --origin shape: {defaultBranch?: string, links?: record, name?: string, project?: record, scmId?: string, slug?: string}
# --project shape: {avatar?: string, avatarUrl?: string, key: string, links?: record}
export def "latest-projects-repos updateRepository" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --defaultBranch: string # e.g. main
  --links: record
  --name: string # e.g. My repo
  --project: record # shape: {avatar?: string, avatarUrl?: string, key: string, links?: record}
  --scmId: string # e.g. git
  --slug: string # e.g. my-repo
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)")
  let body = {defaultBranch: $defaultBranch, links: $links, name: $name, project: $project, scmId: $scmId, slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Stream archive of repository
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/archive
# operationId: getArchive
export def "latest-projects-repos-archive get" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --path: string # Paths to include in the streamed archive; may be repeated to include multiple paths
  --filename: string # A filename to include the "Content-Disposition" header
  --at: string # The commit hash or fully-qualified ref name (e.g. refs/tags/example) to stream an archive of; if not supplied, an archive of the default branch is streamed
  --prefix: string # A prefix to apply to all entries in the streamed archive; if the supplied prefix does not end with a trailing /, one will be added automatically
  --format: string # The format to stream the archive in; must be one of: zip, tar, tar.gz or tgz
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "filename" $filename "scalar") (serialize-qp "at" $at "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/archive" $qp)
  let accept_val = ($accept | default "application/octet-stream")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an attachment
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/attachments/{attachmentId}
# operationId: deleteAttachment
export def "latest-projects-repos-attachments delete" [
  projectKey: string
  attachmentId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/attachments/($attachmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an attachment
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/attachments/{attachmentId}
# operationId: getAttachment
export def "latest-projects-repos-attachments get" [
  projectKey: string
  attachmentId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --User-Agent: string
  --Range: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/attachments/($attachmentId)")
  let extra_headers = {"User-Agent": $User_Agent, "Range": $Range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete attachment metadata
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/attachments/{attachmentId}/metadata
# operationId: deleteAttachmentMetadata
export def "latest-projects-repos-attachments-metadata delete" [
  projectKey: string
  attachmentId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/attachments/($attachmentId)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attachment metadata
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/attachments/{attachmentId}/metadata
# operationId: getAttachmentMetadata
export def "latest-projects-repos-attachments-metadata get" [
  projectKey: string
  attachmentId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/attachments/($attachmentId)/metadata")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save attachment metadata
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/attachments/{attachmentId}/metadata
# operationId: saveAttachmentMetadata
export def "latest-projects-repos-attachments-metadata saveAttachmentMetadata" [
  projectKey: string
  attachmentId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/attachments/($attachmentId)/metadata")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Find branches
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/branches
# operationId: getBranches
export def "latest-projects-repos-branches get" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --boostMatches: oneof<nothing, bool> # Controls whether exact and prefix matches will be boosted to the top
  --context: string
  --orderBy: string@orderBy-completer # Ordering of refs either ALPHABETICAL (by name) or MODIFICATION (last updated)
  --details: oneof<nothing, bool> # Whether to retrieve plugin-provided metadata about each branch
  --filterText: string # The text to match on
  --qp-base: string # Base branch or tag to compare each branch to (for the metadata providers that uses that information
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "boostMatches" $boostMatches "scalar") (serialize-qp "context" $context "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "details" $details "scalar") (serialize-qp "filterText" $filterText "scalar") (serialize-qp "base" $qp_base "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/branches" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create branch
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/branches
# operationId: createBranchForRepository
export def "latest-projects-repos-branches createBranchForRepository" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # e.g. This is my branch or tag
  --name: string # e.g. my-branch-or-tag
  --startPoint: string # e.g. 8d351a10fb428c0c1239530256e21cf24f136e73
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/branches")
  let body = {message: $message, name: $name, startPoint: $startPoint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get default branch
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/branches/default
# DEPRECATED
# operationId: getDefaultBranch_1
@deprecated
export def "latest-projects-repos-branches-default get-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/branches/default")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update default branch
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/branches/default
# DEPRECATED
# operationId: setDefaultBranch_1
@deprecated
export def "latest-projects-repos-branches-default setDefaultBranch-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # e.g. refs/heads/master
  --type: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/branches/default")
  let body = {id: $id, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get file content at revision
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/browse
# operationId: getContent
export def "latest-projects-repos-browse get" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --noContent: string # If blame&amp;noContent only the blame is retrieved instead of the contents
  --at: string # The commit ID or ref to retrieve the content for
  --size: string # If true only the size will be returned for the file path instead of the contents
  --blame: string # If present and not equal to 'false', the blame will be returned for the file as well
  --type: string # If true only the type will be returned for the file path instead of the contents
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "noContent" $noContent "scalar") (serialize-qp "at" $at "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "blame" $blame "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/browse" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get file content
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/browse/{path}
# operationId: getContent_1
export def "latest-projects-repos-browse get-by-path-projectKey-repositorySlug" [
  path: string
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --noContent: string # If blame&amp;noContent only the blame is retrieved instead of the contents
  --at: string # The commit ID or ref to retrieve the content for
  --size: string # If true only the size will be returned for the file path instead of the contents
  --blame: string # If present and not equal to 'false', the blame will be returned for the file as well
  --type: string # If true only the type will be returned for the file path instead of the contents
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "noContent" $noContent "scalar") (serialize-qp "at" $at "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "blame" $blame "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/browse/($path)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit file
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/browse/{path}
# operationId: editFile
export def "latest-projects-repos-browse editFile" [
  path: string
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch: string # The branch on which the <code>path</code> should be modified or created.
  --content: string # The full content of the file at <code>path</code>.
  --message: string # The message associated with this change, to be used as the commit message. Or null if the default message should be used.
  --sourceBranch: string # The starting point for <code>branch</code>. If provided and different from <code>branch</code>, <code>branch</code> will be created as a new branch, branching off from <code>sourceBranch</code>.
  --sourceCommitId: string # The commit ID of the file before it was edited, used to identify if content has changed. Or null if this is a new file
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/browse/($path)")
  let body = {branch: $branch, content: $content, message: $message, sourceBranch: $sourceBranch, sourceCommitId: $sourceCommitId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get changes made in commit
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/changes
# operationId: getChanges_1
export def "latest-projects-repos-changes get-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --until: string # The commit to retrieve changes for
  --since: string # The commit to which <code>until</code> should be compared to produce a page of changes. If not specified the commit's first parent is assumed (if one exists)
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "until" $until "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/changes" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get commits
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits
# operationId: getCommits
export def "latest-projects-repos-commits list" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatarScheme: string # The desired scheme for the avatar URL. If the parameter is not present URLs will use the same scheme as this request
  --path: string # An optional path to filter commits by
  --withCounts: string # Optionally include the total number of commits and total number of unique authors
  --followRenames: string # If <code>true</code>, the commit history of the specified file will be followed past renames. Only valid for a path to a single file.
  --until: string # The commit ID (SHA1) or ref (inclusively) to retrieve commits before
  --avatarSize: string # If present the service adds avatar URLs for commit authors. Should be an integer specifying the desired size in pixels. If the parameter is not present, avatar URLs will not be set
  --since: string # The commit ID or ref (exclusively) to retrieve commits after
  --merges: string # If present, controls how merge commits should be filtered. Can be either <code>exclude</code>, to exclude merge commits, <code>include</code>, to include both merge commits and non-merge commits or <code>only</code>, to only return merge commits.
  --ignoreMissing: string # <code>true</code> to ignore missing commits, <code>false</code> otherwise
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "avatarScheme" $avatarScheme "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "withCounts" $withCounts "scalar") (serialize-qp "followRenames" $followRenames "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "avatarSize" $avatarSize "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "merges" $merges "scalar") (serialize-qp "ignoreMissing" $ignoreMissing "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get commit by ID
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}
# operationId: getCommit
export def "latest-projects-repos-commits get" [
  projectKey: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # An optional path to filter the commit by. If supplied the details returned <i>may not</i> be for the specified commit. Instead, starting from the specified commit, they will be the details for the first commit affecting the specified path.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a specific build status
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/builds
# operationId: delete
export def "latest-projects-repos-commits-builds delete" [
  projectKey: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # the key of the build status
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/builds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific build status
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/builds
# operationId: get
export def "latest-projects-repos-commits-builds get" [
  projectKey: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # the key of the build status
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/builds" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Store a build status
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/builds
# operationId: add
export def "latest-projects-repos-commits-builds add" [
  projectKey: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/builds")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $body
}

# Get changes in commit
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/changes
# operationId: getChanges
export def "latest-projects-repos-commits-changes get" [
  projectKey: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --withComments: string # <code>true</code> to apply comment counts in the changes (the default); otherwise, <code>false</code> to stream changes without comment counts
  --since: string # The commit to which <code>until</code> should be compared to produce a page of changes. If not specified the commit's first parent is assumed (if one exists)
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withComments" $withComments "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/changes" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for commit comments
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/comments
# operationId: getComments
export def "latest-projects-repos-commits-comments list" [
  projectKey: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The path to the file on which comments were made
  --since: string # For a merge commit, a parent can be provided to specify which diff the comments are on. For a commit range, a sinceId can be provided to specify where the comments are anchored from.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/comments" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new commit comment
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/comments
# operationId: createComment
# --anchor shape: {diffType?: "COMMIT"|"EFFECTIVE"|"RANGE", fileType?: "FROM"|"TO", fromHash?: string, line?: int, lineType?: "ADDED"|"CONTEXT"|"REMOVED", path?: record, srcPath?: record, toHash?: string}
# --author shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
# --comments item shape: {anchor?: record, comments?: list, id?: int, properties?: record, severity?: string, state?: string, text?: string, threadResolved?: bool, version?: int}
# --parent shape: {anchor?: record, comments?: list, id?: int, properties?: record, severity?: string, state?: string, text?: string, threadResolved?: bool, version?: int}
# --resolver shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
# --threadResolver shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
export def "latest-projects-repos-commits-comments createComment" [
  projectKey: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # For a merge commit, a parent can be provided to specify which diff the comments should be on. For a commit range, a sinceId can be provided to specify where the comments should be anchored from.
  --anchor: record # shape: {diffType?: "COMMIT"|"EFFECTIVE"|"RANGE", fileType?: "FROM"|"TO", fromHash?: string, line?: int, lineType?: "ADDED"|"CONTEXT"|"REMOVED", path?: record, srcPath?: record, toHash?: string}
  --comments: list # item shape: {anchor?: record, comments?: list, id?: int, properties?: record, severity?: string, state?: string, text?: string, threadResolved?: bool, version?: int}
  --id: int # format: int64, e.g. 1
  --properties: record
  --severity: string # e.g. NORMAL
  --state: string # e.g. OPEN
  --text: string # e.g. An insightful comment.
  --threadResolved: oneof<nothing, bool> # Indicates if this comment thread has been marked as resolved or not
  --version: int # format: int32, e.g. 1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/comments" $qp)
  let body = {anchor: $anchor, comments: $comments, id: $id, properties: $properties, severity: $severity, state: $state, text: $text, threadResolved: $threadResolved, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a commit comment
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/comments/{commentId}
# operationId: deleteComment
export def "latest-projects-repos-commits-comments delete" [
  projectKey: string
  commentId: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The expected version of the comment. This must match the server's version of the comment or the delete will fail. To determine the current version of the comment, the comment should be fetched from the server prior to the delete. Look for the 'version' attribute in the returned JSON structure.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/comments/($commentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a commit comment
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/comments/{commentId}
# operationId: getComment
export def "latest-projects-repos-commits-comments get" [
  projectKey: string
  commentId: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/comments/($commentId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a commit comment
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/comments/{commentId}
# operationId: updateComment
# --anchor shape: {diffType?: "COMMIT"|"EFFECTIVE"|"RANGE", fileType?: "FROM"|"TO", fromHash?: string, line?: int, lineType?: "ADDED"|"CONTEXT"|"REMOVED", path?: record, srcPath?: record, toHash?: string}
# --author shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
# --comments item shape: {anchor?: record, comments?: list, id?: int, properties?: record, severity?: string, state?: string, text?: string, threadResolved?: bool, version?: int}
# --parent shape: {anchor?: record, comments?: list, id?: int, properties?: record, severity?: string, state?: string, text?: string, threadResolved?: bool, version?: int}
# --resolver shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
# --threadResolver shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
export def "latest-projects-repos-commits-comments updateComment" [
  projectKey: string
  commentId: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --anchor: record # shape: {diffType?: "COMMIT"|"EFFECTIVE"|"RANGE", fileType?: "FROM"|"TO", fromHash?: string, line?: int, lineType?: "ADDED"|"CONTEXT"|"REMOVED", path?: record, srcPath?: record, toHash?: string}
  --comments: list # item shape: {anchor?: record, comments?: list, id?: int, properties?: record, severity?: string, state?: string, text?: string, threadResolved?: bool, version?: int}
  --id: int # format: int64, e.g. 1
  --properties: record
  --severity: string # e.g. NORMAL
  --state: string # e.g. OPEN
  --text: string # e.g. An insightful comment.
  --threadResolved: oneof<nothing, bool> # Indicates if this comment thread has been marked as resolved or not
  --version: int # format: int32, e.g. 1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/comments/($commentId)")
  let body = {anchor: $anchor, comments: $comments, id: $id, properties: $properties, severity: $severity, state: $state, text: $text, threadResolved: $threadResolved, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a deployment
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/deployments
# operationId: delete_1
export def "latest-projects-repos-commits-deployments delete-by-projectKey-commitId-repositorySlug" [
  projectKey: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deploymentSequenceNumber: string # the sequence number of the deployment, as detailed by the query parameter
  --key: string # the key of the deployment, as detailed by the query parameter
  --environmentKey: string # the key of the environment, as detailed by the query parameter
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deploymentSequenceNumber" $deploymentSequenceNumber "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "environmentKey" $environmentKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/deployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a deployment
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/deployments
# operationId: get_1
export def "latest-projects-repos-commits-deployments get-by-projectKey-commitId-repositorySlug" [
  projectKey: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deploymentSequenceNumber: string # the sequence number of the deployment, as detailed by the query param (e.g. deploymentSequenceNumber)
  --key: string # the key of the deployment, as detailed by the query parameter
  --environmentKey: string # the key of the environment, as detailed by the query parameter
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deploymentSequenceNumber" $deploymentSequenceNumber "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "environmentKey" $environmentKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/deployments" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a deployment
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/deployments
# operationId: createOrUpdateDeployment
export def "latest-projects-repos-commits-deployments createOrUpdateDeployment" [
  projectKey: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/deployments")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $body
}

# Get diff stats summary between revisions
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/diff-stats-summary/{path}
# operationId: getDiffStatsSummary
export def "latest-projects-repos-commits-diff-stats-summary get" [
  path: string
  projectKey: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --srcPath: string # The source path for the file, if it was copied, moved or renamed
  --autoSrcPath: string # <code>true</code> to automatically try to find the source path when it's not provided, <code>false</code> otherwise. Requires the path to be provided.
  --whitespace: string # Optional whitespace flag which can be set to ignore-all
  --since: string # The base revision to diff from. If omitted the parent revision of the commit ID is used
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "srcPath" $srcPath "scalar") (serialize-qp "autoSrcPath" $autoSrcPath "scalar") (serialize-qp "whitespace" $whitespace "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/diff-stats-summary/($path)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get diff between revisions
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/diff/{path}
# operationId: streamDiff
export def "latest-projects-repos-commits-diff streamDiff" [
  commitId: string
  repositorySlug: string
  path: string
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --srcPath: string # The source path for the file, if it was copied, moved or renamed
  --avatarSize: string # If present the service adds avatar URLs for comment authors where the provided value specifies the desired avatar size in pixels. Not applicable if streaming raw diff
  --filter: string # Text used to filter files and lines (optional). Not applicable if streaming raw diff
  --avatarScheme: string # The security scheme for avatar URLs. If the scheme is not present then it is inherited from the request. It can be set to "https" to force the use of secure URLs. Not applicable if streaming raw diff
  --contextLines: string # The number of context lines to include around added/removed lines in the diff.Not applicable if streaming raw diff
  --autoSrcPath: string # <code>true</code> to automatically try to find the source path when it's not provided, <code>false</code> otherwise. Requires the path to be provided.
  --whitespace: string # Optional whitespace flag which can be set to ignore-all
  --withComments: string # <code>true</code> to embed comments in the diff (the default); otherwise <code>false</code> to stream the diff without comments. Not applicable if streaming raw diff
  --since: string # The base revision to diff from. If omitted the parent revision of the until revision is used
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "srcPath" $srcPath "scalar") (serialize-qp "avatarSize" $avatarSize "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "avatarScheme" $avatarScheme "scalar") (serialize-qp "contextLines" $contextLines "scalar") (serialize-qp "autoSrcPath" $autoSrcPath "scalar") (serialize-qp "whitespace" $whitespace "scalar") (serialize-qp "withComments" $withComments "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/diff/($path)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the common ancestor between two commits
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/merge-base
# operationId: getMergeBase
export def "latest-projects-repos-commits-merge-base get" [
  projectKey: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --otherCommitId: string # The other commit id to calculate the merge-base on
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "otherCommitId" $otherCommitId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/merge-base" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get repository pull requests containing commit
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/pull-requests
# operationId: getPullRequests
export def "latest-projects-repos-commits-pull-requests get" [
  projectKey: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/pull-requests" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop watching commit
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/watch
# operationId: unwatch
export def "latest-projects-repos-commits-watch unwatch" [
  projectKey: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/watch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Watch commit
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/commits/{commitId}/watch
# operationId: watch
export def "latest-projects-repos-commits-watch watch" [
  projectKey: string
  commitId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/commits/($commitId)/watch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Compare commits
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/compare/changes
# operationId: streamChanges
export def "latest-projects-repos-compare-changes streamChanges" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fromRepo: string # an optional parameter specifying the source repository containing the source commit if that commit is not present in the current repository; the repository can be specified by either its ID <em>fromRepo=42</em> or by its project key plus its repo slug separated by a slash: <em>fromRepo=projectKey/repoSlug</em>
  --qp-from: string # the source commit (can be a partial/full commit ID or qualified/unqualified ref name)
  --qp-to: string # the target commit (can be a partial/full commit ID or qualified/unqualified ref name)
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromRepo" $fromRepo "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/compare/changes" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get accessible commits
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/compare/commits
# operationId: streamCommits
export def "latest-projects-repos-compare-commits streamCommits" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fromRepo: string # an optional parameter specifying the source repository containing the source commit if that commit is not present in the current repository; the repository can be specified by either its ID <em>fromRepo=42</em> or by its project key plus its repo slug separated by a slash: <em>fromRepo=projectKey/repoSlug</em>
  --qp-from: string # the source commit (can be a partial/full commit ID or qualified/unqualified ref name)
  --qp-to: string # the target commit (can be a partial/full commit ID or qualified/unqualified ref name)
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromRepo" $fromRepo "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/compare/commits" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the diff stats summary between commits
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/compare/diff-stats-summary{path}
# operationId: getDiffStatsSummary_1
export def "latest-projects-repos-compare-diff-stats-summary-path get-by-path-projectKey-repositorySlug" [
  path: string
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fromRepo: string # an optional parameter specifying the source repository containing the source commit if that commit is not present in the current repository; the repository can be specified by either its ID <em>fromRepo=42</em> or by its project key plus its repo slug separated by a slash: <em>fromRepo=projectKey/repoSlug</em>
  --srcPath: string # source path
  --qp-from: string # the source commit (can be a partial/full commit ID or qualified/unqualified ref name)
  --qp-to: string # the target commit (can be a partial/full commit ID or qualified/unqualified ref name)
  --whitespace: string # an optional whitespace flag which can be set to <code>ignore-all</code>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromRepo" $fromRepo "scalar") (serialize-qp "srcPath" $srcPath "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "whitespace" $whitespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/compare/diff-stats-summary($path)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get diff between commits
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/compare/diff{path}
# operationId: streamDiff_1
export def "latest-projects-repos-compare-diff-path streamDiff-by-path-projectKey-repositorySlug" [
  path: string
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contextLines: string # an optional number of context lines to include around each added or removed lines in the diff
  --fromRepo: string # an optional parameter specifying the source repository containing the source commit if that commit is not present in the current repository; the repository can be specified by either its ID <em>fromRepo=42</em> or by its project key plus its repo slug separated by a slash: <em>fromRepo=projectKey/repoSlug</em>
  --srcPath: string # source path
  --qp-from: string # the source commit (can be a partial/full commit ID or qualified/unqualified ref name)
  --qp-to: string # the target commit (can be a partial/full commit ID or qualified/unqualified ref name)
  --whitespace: string # an optional whitespace flag which can be set to <code>ignore-all</code>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contextLines" $contextLines "scalar") (serialize-qp "fromRepo" $fromRepo "scalar") (serialize-qp "srcPath" $srcPath "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "whitespace" $whitespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/compare/diff($path)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get repository contributing guidelines
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/contributing
# operationId: streamContributing
export def "latest-projects-repos-contributing streamContributing" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --at: string # A specific commit or ref to retrieve the guidelines at, or the default branch if not specified
  --markup: string # If present or <code>"true"</code>, triggers the raw content to be markup-rendered and returned as HTML; otherwise, if not specified, or any value other than <code>"true"</code>, the content is streamed without markup
  --htmlEscape: string # (Optional) true if HTML should be escaped in the input markup, false otherwise. If not specified, the value of the <code>markup.render.html.escape</code> property, which is <code>true</code> by default, will be used
  --includeHeadingId: string # (Optional) true if headings should contain an ID based on the heading content. If not specified, the value of the <code>markup.render.headerids</code> property, which is false by default, will be used
  --hardwrap: string # (Optional) Whether the markup implementation should convert newlines to breaks. If not specified, the value of the <code>markup.render.hardwrap</code> property, which is <code>true</code> by default, will be used
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "at" $at "scalar") (serialize-qp "markup" $markup "scalar") (serialize-qp "htmlEscape" $htmlEscape "scalar") (serialize-qp "includeHeadingId" $includeHeadingId "scalar") (serialize-qp "hardwrap" $hardwrap "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/contributing" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get repository default branch
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/default-branch
# operationId: getDefaultBranch_2
export def "latest-projects-repos-default-branch get-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/default-branch")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update default branch for repository
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/default-branch
# operationId: setDefaultBranch_2
export def "latest-projects-repos-default-branch setDefaultBranch-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # e.g. refs/heads/master
  --type: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/default-branch")
  let body = {id: $id, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get raw diff for path
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/diff
# operationId: streamRawDiff
export def "latest-projects-repos-diff streamRawDiff" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contextLines: string # The number of context lines to include around added/removed lines in the diff
  --srcPath: string # The source path for the file, if it was copied, moved or renamed
  --until: string # The target revision to diff to (required)
  --whitespace: string # Optional whitespace flag which can be set to <code>ignore-all</code>
  --since: string # The base revision to diff from. If omitted the parent revision of the until revision is used
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contextLines" $contextLines "scalar") (serialize-qp "srcPath" $srcPath "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "whitespace" $whitespace "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/diff" $qp)
  let accept_val = "text/plain; qs=0.1"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get raw diff for path
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/diff/{path}
# operationId: streamRawDiff_1
export def "latest-projects-repos-diff streamRawDiff-by-path-projectKey-repositorySlug" [
  path: string
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contextLines: string # The number of context lines to include around added/removed lines in the diff
  --srcPath: string # The source path for the file, if it was copied, moved or renamed
  --until: string # The target revision to diff to (required)
  --whitespace: string # Optional whitespace flag which can be set to <code>ignore-all</code>
  --since: string # The base revision to diff from. If omitted the parent revision of the until revision is used
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contextLines" $contextLines "scalar") (serialize-qp "srcPath" $srcPath "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "whitespace" $whitespace "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/diff/($path)" $qp)
  let accept_val = "text/plain; qs=0.1"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get files in directory
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/files
# operationId: streamFiles
export def "latest-projects-repos-files streamFiles" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --at: string # The commit ID or ref (e.g. a branch or tag) to list the files at. If not specified the default branch will be used instead.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "at" $at "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/files" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get files in directory
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/files/{path}
# operationId: streamFiles_1
export def "latest-projects-repos-files streamFiles-by-path-projectKey-repositorySlug" [
  path: string
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --at: string # The commit ID or ref (e.g. a branch or tag) to list the files at. If not specified the default branch will be used instead.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "at" $at "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/files/($path)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get repository forks
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/forks
# operationId: getForkedRepositories
export def "latest-projects-repos-forks get" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/forks" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get hook scripts
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/hook-scripts
# operationId: getConfigurations_1
export def "latest-projects-repos-hook-scripts get-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/hook-scripts" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a hook script
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/hook-scripts/{scriptId}
# operationId: removeConfiguration_1
export def "latest-projects-repos-hook-scripts removeConfiguration-by-projectKey-scriptId-repositorySlug" [
  projectKey: string
  scriptId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/hook-scripts/($scriptId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create/update a hook script
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/hook-scripts/{scriptId}
# operationId: setConfiguration_1
export def "latest-projects-repos-hook-scripts setConfiguration-by-projectKey-scriptId-repositorySlug" [
  projectKey: string
  scriptId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  triggerIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/hook-scripts/($scriptId)")
  let body = {triggerIds: $triggerIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get repository labels
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/labels
# operationId: getAllLabelsForRepository
export def "latest-projects-repos-labels get" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/labels")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add repository label
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/labels
# operationId: addLabel
export def "latest-projects-repos-labels addLabel" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # e.g. labelName
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/labels")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove repository label
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/labels/{labelName}
# operationId: removeLabel
export def "latest-projects-repos-labels removeLabel" [
  projectKey: string
  labelName: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/labels/($labelName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stream files
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/last-modified
# operationId: stream
export def "latest-projects-repos-last-modified stream" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --at: string # The commit to use as the starting point when listing files and calculating modifications
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "at" $at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/last-modified" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stream files with last modified commit in path
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/last-modified/{path}
# operationId: stream_1
export def "latest-projects-repos-last-modified stream-by-path-projectKey-repositorySlug" [
  path: string
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --at: string # The commit to use as the starting point when listing files and calculating modifications
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "at" $at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/last-modified/($path)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get repository license
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/license
# operationId: streamLicense
export def "latest-projects-repos-license streamLicense" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --at: string # A specific commit or ref to retrieve the guidelines at, or the default branch if not specified
  --markup: string # If present or <code>"true"</code>, triggers the raw content to be markup-rendered and returned as HTML; otherwise, if not specified, or any value other than <code>"true"</code>, the content is streamed without markup
  --htmlEscape: string # (Optional) true if HTML should be escaped in the input markup, false otherwise. If not specified, the value of the <code>markup.render.html.escape</code> property, which is <code>true</code> by default, will be used
  --includeHeadingId: string # (Optional) true if headings should contain an ID based on the heading content. If not specified, the value of the <code>markup.render.headerids</code> property, which is false by default, will be used
  --hardwrap: string # (Optional) Whether the markup implementation should convert newlines to breaks. If not specified, the value of the <code>markup.render.hardwrap</code> property, which is <code>true</code> by default, will be used
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "at" $at "scalar") (serialize-qp "markup" $markup "scalar") (serialize-qp "htmlEscape" $htmlEscape "scalar") (serialize-qp "includeHeadingId" $includeHeadingId "scalar") (serialize-qp "hardwrap" $hardwrap "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/license" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search pull request participants
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/participants
# operationId: search
export def "latest-projects-repos-participants search" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # (optional) Return only users, whose username, name or email address <i>contain</i> the filter value
  --role: string # (optional) The role associated with the pull request participant. This must be one of AUTHOR, REVIEWER, or PARTICIPANT
  --direction: string # (optional), Defaults to <strong>INCOMING</strong>) the direction relative to the specified repository. Either <strong>INCOMING</strong> or <strong>OUTGOING</strong>.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/participants" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get patch content at revision
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/patch
# operationId: streamPatch
export def "latest-projects-repos-patch streamPatch" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --until: string # The target revision from which to generate the patch (required)
  --allAncestors: string # indicates whether or not to generate a patch which includes all the ancestors of the 'until' revision. If true, the value provided by 'since' is ignored.
  --since: string # The base revision from which to generate the patch. This is only applicable when 'allAncestors' is false. If omitted the patch will represent one single commit, the 'until'.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "until" $until "scalar") (serialize-qp "allAncestors" $allAncestors "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/patch" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke all repository permissions for users and groups
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/permissions
# operationId: revokePermissions_1
export def "latest-projects-repos-permissions revokePermissions-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # The names of the users
  --group: string # The names of the groups
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar") (serialize-qp "group" $group "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke group repository permission
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/permissions/groups
# operationId: revokePermissionsForGroup_2
export def "latest-projects-repos-permissions-groups revokePermissionsForGroup-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the group.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/permissions/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get groups with permission to repository
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/permissions/groups
# operationId: getGroupsWithAnyPermission_2
export def "latest-projects-repos-permissions-groups get-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only group names containing the supplied string will be returned.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/permissions/groups" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update group repository permission
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/permissions/groups
# operationId: setPermissionForGroup
export def "latest-projects-repos-permissions-groups setPermissionForGroup" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: list # The names of the groups.
  --permission: string@permission-completer-3 # The permission to grant
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "multi") (serialize-qp "permission" $permission "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/permissions/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get groups without repository permission
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/permissions/groups/none
# operationId: getGroupsWithoutAnyPermission_2
export def "latest-projects-repos-permissions-groups-none get-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only group names containing the supplied string will be returned.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/permissions/groups/none" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search repository permissions
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/permissions/search
# operationId: searchPermissions_1
export def "latest-projects-repos-permissions-search searchPermissions-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permission: string # Permissions to filter by. See the [permissions documentation](https://confluence.atlassian.com/display/BitbucketServer/Using+repository+permissions)for a detailed explanation of what each permission entails. This parameter can be specified multiple times to filter by more than one permission, and can contain repository, project, and global permissions. 
  --filterText: string # Name of the user or group to filter the name of
  --type: string # Type of entity (user or group)Valid entity types are:  - USER- GROUP
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permission" $permission "scalar") (serialize-qp "filterText" $filterText "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/permissions/search" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke user repository permission
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/permissions/users
# operationId: revokePermissionsForUser_2
export def "latest-projects-repos-permissions-users revokePermissionsForUser-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the user.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/permissions/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get users with permission to repository
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/permissions/users
# operationId: getUsersWithAnyPermission_2
export def "latest-projects-repos-permissions-users get-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only user names containing the supplied string will be returned.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/permissions/users" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user repository permission
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/permissions/users
# operationId: setPermissionForUser
export def "latest-projects-repos-permissions-users setPermissionForUser" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: list # The names of the users.
  --permission: string@permission-completer-3 # The permission to grant
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "multi") (serialize-qp "permission" $permission "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/permissions/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get users without repository permission
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/permissions/users/none
# operationId: getUsersWithoutPermission_1
export def "latest-projects-repos-permissions-users-none get-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # If specified only user names containing the supplied string will be returned.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/permissions/users/none" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pull requests for repository
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests
# operationId: getPage
export def "latest-projects-repos-pull-requests get" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --withAttributes: string # (optional) defaults to true, whether to return additional pull request attributes
  --at: string # (optional) a <i>fully-qualified</i> branch ID to find pull requests to or from, such as refs/heads/master
  --withProperties: string # (optional) defaults to true, whether to return additional pull request properties
  --draft: string # (optional) If specified, only pull requests matching the supplied draft status will be returned.
  --filterText: string # (optional) If specified, only pull requests where the title or description contains the supplied string will be returned.
  --state: string # (optional, defaults to <strong>OPEN</strong>). Supply <strong>ALL</strong> to return pull request in any state. If a state is supplied only pull requests in the specified state will be returned. Either <strong>OPEN</strong>, <strong>DECLINED</strong> or <strong>MERGED</strong>.
  --order: string # (optional, defaults to <strong>NEWEST</strong>) the order to return pull requests in, either <strong>OLDEST</strong> (as in: "oldest first") or <strong>NEWEST</strong>.
  --direction: string # (optional, defaults to <strong>INCOMING</strong>) the direction relative to the specified repository. Either <strong>INCOMING</strong> or <strong>OUTGOING</strong>.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withAttributes" $withAttributes "scalar") (serialize-qp "at" $at "scalar") (serialize-qp "withProperties" $withProperties "scalar") (serialize-qp "draft" $draft "scalar") (serialize-qp "filterText" $filterText "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create pull request
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests
# operationId: create
# --author shape: {approved?: bool, lastReviewedCommit?: string, role?: "AUTHOR"|"REVIEWER"|"PARTICIPANT", status?: "UNAPPROVED"|"NEEDS_WORK"|"APPROVED", user?: record}
# --fromRef shape: {displayId: string, id: string, latestCommit: string, repository?: record, type?: "BRANCH"|"TAG"}
# --participants item shape: {approved?: bool, lastReviewedCommit?: string, role?: "AUTHOR"|"REVIEWER"|"PARTICIPANT", status?: "UNAPPROVED"|"NEEDS_WORK"|"APPROVED", user?: record}
# --reviewers item shape: {approved?: bool, lastReviewedCommit?: string, role?: "AUTHOR"|"REVIEWER"|"PARTICIPANT", status?: "UNAPPROVED"|"NEEDS_WORK"|"APPROVED", user?: record}
# --toRef shape: {displayId: string, id: string, latestCommit: string, repository?: record, type?: "BRANCH"|"TAG"}
export def "latest-projects-repos-pull-requests create" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --closed: oneof<nothing, bool>
  --closedDate: int # format: int64, e.g. 19990759200
  --createdDate: int # format: int64, e.g. 13590759200
  --description: string # e.g. It is a kludge, but put the tuple from the database in the cache.
  --descriptionAsHtml: string
  --draft: oneof<nothing, bool>
  --fromRef: record # shape: {displayId: string, id: string, latestCommit: string, repository?: record, type?: "BRANCH"|"TAG"}
  --htmlDescription: string
  --id: int # format: int64, e.g. 1
  --links: record
  --locked: oneof<nothing, bool>
  --body-open: oneof<nothing, bool>
  --participants: list # item shape: {approved?: bool, lastReviewedCommit?: string, role?: "AUTHOR"|"REVIEWER"|"PARTICIPANT", status?: "UNAPPROVED"|"NEEDS_WORK"|"APPROVED", user?: record}
  --reviewers: list # item shape: {approved?: bool, lastReviewedCommit?: string, role?: "AUTHOR"|"REVIEWER"|"PARTICIPANT", status?: "UNAPPROVED"|"NEEDS_WORK"|"APPROVED", user?: record}
  --state: string@state-completer-3
  --title: string # e.g. Talking Nerdy
  --toRef: record # shape: {displayId: string, id: string, latestCommit: string, repository?: record, type?: "BRANCH"|"TAG"}
  --updatedDate: int # format: int64, e.g. 14490759200
  --version: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests")
  let body = {closed: $closed, closedDate: $closedDate, createdDate: $createdDate, description: $description, descriptionAsHtml: $descriptionAsHtml, draft: $draft, fromRef: $fromRef, htmlDescription: $htmlDescription, id: $id, links: $links, locked: $locked, open: $body_open, participants: $participants, reviewers: $reviewers, state: $state, title: $title, toRef: $toRef, updatedDate: $updatedDate, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete pull request
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}
# operationId: delete_3
export def "latest-projects-repos-pull-requests delete-by-projectKey-pullRequestId-repositorySlug" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)")
  let body = {version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get pull request
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}
# operationId: get_3
export def "latest-projects-repos-pull-requests get-by-projectKey-pullRequestId-repositorySlug" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --withProperties: string # (optional) defaults to false, whether to return additional pull request properties
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withProperties" $withProperties "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update pull request metadata
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}
# operationId: update
# --author shape: {approved?: bool, lastReviewedCommit?: string, role?: "AUTHOR"|"REVIEWER"|"PARTICIPANT", status?: "UNAPPROVED"|"NEEDS_WORK"|"APPROVED", user?: record}
# --fromRef shape: {displayId: string, id: string, latestCommit: string, repository?: record, type?: "BRANCH"|"TAG"}
# --participants item shape: {approved?: bool, lastReviewedCommit?: string, role?: "AUTHOR"|"REVIEWER"|"PARTICIPANT", status?: "UNAPPROVED"|"NEEDS_WORK"|"APPROVED", user?: record}
# --reviewers item shape: {approved?: bool, lastReviewedCommit?: string, role?: "AUTHOR"|"REVIEWER"|"PARTICIPANT", status?: "UNAPPROVED"|"NEEDS_WORK"|"APPROVED", user?: record}
# --toRef shape: {displayId: string, id: string, latestCommit: string, repository?: record, type?: "BRANCH"|"TAG"}
export def "latest-projects-repos-pull-requests update" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --closed: oneof<nothing, bool>
  --closedDate: int # format: int64, e.g. 19990759200
  --createdDate: int # format: int64, e.g. 13590759200
  --description: string # e.g. It is a kludge, but put the tuple from the database in the cache.
  --descriptionAsHtml: string
  --draft: oneof<nothing, bool>
  --fromRef: record # shape: {displayId: string, id: string, latestCommit: string, repository?: record, type?: "BRANCH"|"TAG"}
  --htmlDescription: string
  --id: int # format: int64, e.g. 1
  --links: record
  --locked: oneof<nothing, bool>
  --body-open: oneof<nothing, bool>
  --participants: list # item shape: {approved?: bool, lastReviewedCommit?: string, role?: "AUTHOR"|"REVIEWER"|"PARTICIPANT", status?: "UNAPPROVED"|"NEEDS_WORK"|"APPROVED", user?: record}
  --reviewers: list # item shape: {approved?: bool, lastReviewedCommit?: string, role?: "AUTHOR"|"REVIEWER"|"PARTICIPANT", status?: "UNAPPROVED"|"NEEDS_WORK"|"APPROVED", user?: record}
  --state: string@state-completer-3
  --title: string # e.g. Talking Nerdy
  --toRef: record # shape: {displayId: string, id: string, latestCommit: string, repository?: record, type?: "BRANCH"|"TAG"}
  --updatedDate: int # format: int64, e.g. 14490759200
  --version: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)")
  let body = {closed: $closed, closedDate: $closedDate, createdDate: $createdDate, description: $description, descriptionAsHtml: $descriptionAsHtml, draft: $draft, fromRef: $fromRef, htmlDescription: $htmlDescription, id: $id, links: $links, locked: $locked, open: $body_open, participants: $participants, reviewers: $reviewers, state: $state, title: $title, toRef: $toRef, updatedDate: $updatedDate, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Stream raw pull request diff
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}.diff
# operationId: streamRawDiff_2
export def "latest-projects-repos-pull-requests streamRawDiff-by-projectKey-pullRequestId-repositorySlug" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contextLines: string # The number of context lines to include around added/removed lines in the diff
  --whitespace: string # optional whitespace flag which can be set to <code>ignore-all</code>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contextLines" $contextLines "scalar") (serialize-qp "whitespace" $whitespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId).diff" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stream pull request as patch
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}.patch
# operationId: streamPatch_1
export def "latest-projects-repos-pull-requests streamPatch-by-projectKey-pullRequestId-repositorySlug" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId).patch")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pull request activity
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/activities
# operationId: getActivities
export def "latest-projects-repos-pull-requests-activities get" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fromType: string # (required if <strong>fromId</strong> is present) the type of the activity item specified by <strong>fromId</strong> (either <strong>COMMENT</strong> or <strong>ACTIVITY</strong>)
  --fromId: string # (optional) the ID of the activity item to use as the first item in the returned page
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromType" $fromType "scalar") (serialize-qp "fromId" $fromId "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/activities" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unapprove pull request
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/approve
# DEPRECATED
# operationId: withdrawApproval
@deprecated
export def "latest-projects-repos-pull-requests-approve withdrawApproval" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/approve")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Approve pull request
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/approve
# DEPRECATED
# operationId: approve
@deprecated
export def "latest-projects-repos-pull-requests-approve approve" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/approve")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel auto-merge for pull request
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/auto-merge
# operationId: cancelAutoMerge
export def "latest-projects-repos-pull-requests-auto-merge cancelAutoMerge" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/auto-merge")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get auto-merge request for pull request
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/auto-merge
# operationId: getAutoMergeRequest
export def "latest-projects-repos-pull-requests-auto-merge get" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/auto-merge")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Auto-merge pull request
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/auto-merge
# operationId: tryAutoMerge
export def "latest-projects-repos-pull-requests-auto-merge tryAutoMerge" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/auto-merge")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search pull request comments
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/blocker-comments
# operationId: getComments_1
export def "latest-projects-repos-pull-requests-blocker-comments get-by-projectKey-pullRequestId-repositorySlug" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: string # If true only the count of the comments by state will be returned (and not the body of the comments).
  --state: list
  --states: string # (optional). If supplied, only comments with a state in the given list will be returned. The state can be OPEN or RESOLVED.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "state" $state "multi") (serialize-qp "states" $states "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/blocker-comments" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add new blocker comment
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/blocker-comments
# operationId: createComment_1
# --anchor shape: {diffType?: "COMMIT"|"EFFECTIVE"|"RANGE", fileType?: "FROM"|"TO", fromHash?: string, line?: int, lineType?: "ADDED"|"CONTEXT"|"REMOVED", path?: record, srcPath?: record, toHash?: string}
# --author shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
# --comments item shape: {anchor?: record, comments?: list, id?: int, properties?: record, severity?: string, state?: string, text?: string, threadResolved?: bool, version?: int}
# --parent shape: {anchor?: record, comments?: list, id?: int, properties?: record, severity?: string, state?: string, text?: string, threadResolved?: bool, version?: int}
# --resolver shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
# --threadResolver shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
export def "latest-projects-repos-pull-requests-blocker-comments createComment-by-projectKey-pullRequestId-repositorySlug" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --anchor: record # shape: {diffType?: "COMMIT"|"EFFECTIVE"|"RANGE", fileType?: "FROM"|"TO", fromHash?: string, line?: int, lineType?: "ADDED"|"CONTEXT"|"REMOVED", path?: record, srcPath?: record, toHash?: string}
  --comments: list # item shape: {anchor?: record, comments?: list, id?: int, properties?: record, severity?: string, state?: string, text?: string, threadResolved?: bool, version?: int}
  --id: int # format: int64, e.g. 1
  --properties: record
  --severity: string # e.g. NORMAL
  --state: string # e.g. OPEN
  --text: string # e.g. An insightful comment.
  --threadResolved: oneof<nothing, bool> # Indicates if this comment thread has been marked as resolved or not
  --version: int # format: int32, e.g. 1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/blocker-comments")
  let body = {anchor: $anchor, comments: $comments, id: $id, properties: $properties, severity: $severity, state: $state, text: $text, threadResolved: $threadResolved, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete pull request comment
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/blocker-comments/{commentId}
# operationId: deleteComment_1
export def "latest-projects-repos-pull-requests-blocker-comments delete-by-projectKey-commentId-pullRequestId-repositorySlug" [
  projectKey: string
  commentId: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The expected version of the comment. This must match the server's version of the comment or the delete will fail. To determine the current version of the comment, the comment should be fetched from the server prior to the delete. Look for the 'version' attribute in the returned JSON structure.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/blocker-comments/($commentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pull request comment
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/blocker-comments/{commentId}
# operationId: getComment_1
export def "latest-projects-repos-pull-requests-blocker-comments get-by-projectKey-commentId-pullRequestId-repositorySlug" [
  projectKey: string
  commentId: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/blocker-comments/($commentId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update pull request comment
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/blocker-comments/{commentId}
# operationId: updateComment_1
# --anchor shape: {diffType?: "COMMIT"|"EFFECTIVE"|"RANGE", fileType?: "FROM"|"TO", fromHash?: string, line?: int, lineType?: "ADDED"|"CONTEXT"|"REMOVED", path?: record, srcPath?: record, toHash?: string}
# --author shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
# --comments item shape: {anchor?: record, comments?: list, id?: int, properties?: record, severity?: string, state?: string, text?: string, threadResolved?: bool, version?: int}
# --parent shape: {anchor?: record, comments?: list, id?: int, properties?: record, severity?: string, state?: string, text?: string, threadResolved?: bool, version?: int}
# --resolver shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
# --threadResolver shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
export def "latest-projects-repos-pull-requests-blocker-comments updateComment-by-projectKey-commentId-pullRequestId-repositorySlug" [
  projectKey: string
  commentId: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --anchor: record # shape: {diffType?: "COMMIT"|"EFFECTIVE"|"RANGE", fileType?: "FROM"|"TO", fromHash?: string, line?: int, lineType?: "ADDED"|"CONTEXT"|"REMOVED", path?: record, srcPath?: record, toHash?: string}
  --comments: list # item shape: {anchor?: record, comments?: list, id?: int, properties?: record, severity?: string, state?: string, text?: string, threadResolved?: bool, version?: int}
  --id: int # format: int64, e.g. 1
  --properties: record
  --severity: string # e.g. NORMAL
  --state: string # e.g. OPEN
  --text: string # e.g. An insightful comment.
  --threadResolved: oneof<nothing, bool> # Indicates if this comment thread has been marked as resolved or not
  --version: int # format: int32, e.g. 1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/blocker-comments/($commentId)")
  let body = {anchor: $anchor, comments: $comments, id: $id, properties: $properties, severity: $severity, state: $state, text: $text, threadResolved: $threadResolved, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets pull request changes
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/changes
# operationId: streamChanges_1
export def "latest-projects-repos-pull-requests-changes streamChanges-by-projectKey-pullRequestId-repositorySlug" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sinceId: string # The since commit hash to stream changes for a RANGE arbitrary change scope
  --changeScope: string # UNREVIEWED to stream the unreviewed changes for the current user (if they exist); RANGE to stream changes between two arbitrary commits (requires 'sinceId' and 'untilId'); otherwise ALL to stream all changes (the default)
  --untilId: string # The until commit hash to stream changes for a RANGE arbitrary change scope
  --withComments: string # true to apply comment counts in the changes (the default); otherwise, false to stream changes without comment counts
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sinceId" $sinceId "scalar") (serialize-qp "changeScope" $changeScope "scalar") (serialize-qp "untilId" $untilId "scalar") (serialize-qp "withComments" $withComments "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/changes" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pull request comments for path
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/comments
# operationId: getComments_2
export def "latest-projects-repos-pull-requests-comments get-by-projectKey-pullRequestId-repositorySlug" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The path to stream comments for a given path
  --fromHash: string # The from commit hash to stream comments for a RANGE or COMMIT arbitrary change scope
  --anchorState: string # ACTIVE to stream the active comments; ORPHANED to stream the orphaned comments; ALL to stream both the active and the orphaned comments;
  --diffType: list
  --toHash: string # The to commit hash to stream comments for a RANGE or COMMIT arbitrary change scope
  --state: list
  --diffTypes: string # EFFECTIVE to stream the comments related to the effective diff of the pull request; RANGE to stream comments related to a commit range between two arbitrary commits (requires 'fromHash' and 'toHash'); COMMIT to stream comments related to a commit between two arbitrary commits (requires 'fromHash' and 'toHash')
  --states: string # (optional). If supplied, only comments with a state in the given list will be returned. The state can be OPEN or RESOLVED.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "fromHash" $fromHash "scalar") (serialize-qp "anchorState" $anchorState "scalar") (serialize-qp "diffType" $diffType "multi") (serialize-qp "toHash" $toHash "scalar") (serialize-qp "state" $state "multi") (serialize-qp "diffTypes" $diffTypes "scalar") (serialize-qp "states" $states "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/comments" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add pull request comment
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/comments
# operationId: createComment_2
# --anchor shape: {diffType?: "COMMIT"|"EFFECTIVE"|"RANGE", fileType?: "FROM"|"TO", fromHash?: string, line?: int, lineType?: "ADDED"|"CONTEXT"|"REMOVED", path?: record, srcPath?: record, toHash?: string}
# --author shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
# --comments item shape: {anchor?: record, comments?: list, id?: int, properties?: record, severity?: string, state?: string, text?: string, threadResolved?: bool, version?: int}
# --parent shape: {anchor?: record, comments?: list, id?: int, properties?: record, severity?: string, state?: string, text?: string, threadResolved?: bool, version?: int}
# --resolver shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
# --threadResolver shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
export def "latest-projects-repos-pull-requests-comments createComment-by-projectKey-pullRequestId-repositorySlug" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --anchor: record # shape: {diffType?: "COMMIT"|"EFFECTIVE"|"RANGE", fileType?: "FROM"|"TO", fromHash?: string, line?: int, lineType?: "ADDED"|"CONTEXT"|"REMOVED", path?: record, srcPath?: record, toHash?: string}
  --comments: list # item shape: {anchor?: record, comments?: list, id?: int, properties?: record, severity?: string, state?: string, text?: string, threadResolved?: bool, version?: int}
  --id: int # format: int64, e.g. 1
  --properties: record
  --severity: string # e.g. NORMAL
  --state: string # e.g. OPEN
  --text: string # e.g. An insightful comment.
  --threadResolved: oneof<nothing, bool> # Indicates if this comment thread has been marked as resolved or not
  --version: int # format: int32, e.g. 1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/comments")
  let body = {anchor: $anchor, comments: $comments, id: $id, properties: $properties, severity: $severity, state: $state, text: $text, threadResolved: $threadResolved, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a pull request comment
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/comments/{commentId}
# operationId: deleteComment_2
export def "latest-projects-repos-pull-requests-comments delete-by-projectKey-commentId-pullRequestId-repositorySlug" [
  projectKey: string
  commentId: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The expected version of the comment. This must match the server's version of the comment or the delete will fail. To determine the current version of the comment, the comment should be fetched from the server prior to the delete. Look for the 'version' attribute in the returned JSON structure.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/comments/($commentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a pull request comment
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/comments/{commentId}
# operationId: getComment_2
export def "latest-projects-repos-pull-requests-comments get-by-projectKey-commentId-pullRequestId-repositorySlug" [
  projectKey: string
  commentId: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/comments/($commentId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update pull request comment
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/comments/{commentId}
# operationId: updateComment_2
# --anchor shape: {diffType?: "COMMIT"|"EFFECTIVE"|"RANGE", fileType?: "FROM"|"TO", fromHash?: string, line?: int, lineType?: "ADDED"|"CONTEXT"|"REMOVED", path?: record, srcPath?: record, toHash?: string}
# --author shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
# --comments item shape: {anchor?: record, comments?: list, id?: int, properties?: record, severity?: string, state?: string, text?: string, threadResolved?: bool, version?: int}
# --parent shape: {anchor?: record, comments?: list, id?: int, properties?: record, severity?: string, state?: string, text?: string, threadResolved?: bool, version?: int}
# --resolver shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
# --threadResolver shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
export def "latest-projects-repos-pull-requests-comments updateComment-by-projectKey-commentId-pullRequestId-repositorySlug" [
  projectKey: string
  commentId: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --anchor: record # shape: {diffType?: "COMMIT"|"EFFECTIVE"|"RANGE", fileType?: "FROM"|"TO", fromHash?: string, line?: int, lineType?: "ADDED"|"CONTEXT"|"REMOVED", path?: record, srcPath?: record, toHash?: string}
  --comments: list # item shape: {anchor?: record, comments?: list, id?: int, properties?: record, severity?: string, state?: string, text?: string, threadResolved?: bool, version?: int}
  --id: int # format: int64, e.g. 1
  --properties: record
  --severity: string # e.g. NORMAL
  --state: string # e.g. OPEN
  --text: string # e.g. An insightful comment.
  --threadResolved: oneof<nothing, bool> # Indicates if this comment thread has been marked as resolved or not
  --version: int # format: int32, e.g. 1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/comments/($commentId)")
  let body = {anchor: $anchor, comments: $comments, id: $id, properties: $properties, severity: $severity, state: $state, text: $text, threadResolved: $threadResolved, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Apply pull request suggestion
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/comments/{commentId}/apply-suggestion
# operationId: applySuggestion
export def "latest-projects-repos-pull-requests-comments-apply-suggestion applySuggestion" [
  projectKey: string
  commentId: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  commentVersion: int # format: int32, e.g. 0
  --commitMessage: string # e.g. A commit message
  pullRequestVersion: int # format: int32, e.g. 1
  suggestionIndex: int # format: int32, e.g. 2
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/comments/($commentId)/apply-suggestion")
  let body = {commentVersion: $commentVersion, commitMessage: $commitMessage, pullRequestVersion: $pullRequestVersion, suggestionIndex: $suggestionIndex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get commit message suggestion
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/commit-message-suggestion
# operationId: getCommitMessageSuggestion
export def "latest-projects-repos-pull-requests-commit-message-suggestion get" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/commit-message-suggestion")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pull request commits
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/commits
# operationId: getCommits_1
export def "latest-projects-repos-pull-requests-commits get-by-projectKey-pullRequestId-repositorySlug" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatarScheme: string # The desired scheme for the avatar URL. If the parameter is not present URLs will use the same scheme as this request
  --withCounts: string # If set to true, the service will add "authorCount" and "totalCount" at the end of the page. "authorCount" is the number of different authors and "totalCount" is the total number of commits.
  --avatarSize: string # If present the service adds avatar URLs for commit authors. Should be an integer specifying the desired size in pixels. If the parameter is not present, avatar URLs will not be setCOMMIT to stream comments related to a commit between two arbitrary commits (requires 'fromHash' and 'toHash')
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "avatarScheme" $avatarScheme "scalar") (serialize-qp "withCounts" $withCounts "scalar") (serialize-qp "avatarSize" $avatarSize "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/commits" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Decline pull request
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/decline
# operationId: decline
export def "latest-projects-repos-pull-requests-decline decline" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The current version of the pull request. If the server's version isn't the same as the specified version the operation will fail. To determine the current version of the pull request it should be fetched from the server prior to this operation. Look for the 'version' attribute in the returned JSON structure.
  --comment: string # e.g. An optional comment explaining why the pull request is being declined
  --version: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/decline" $qp)
  let body = {comment: $comment, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get diff stats summary for pull request
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/diff-stats-summary/{path}
# operationId: getDiffStatsSummary_2
export def "latest-projects-repos-pull-requests-diff-stats-summary get-by-path-projectKey-pullRequestId-repositorySlug" [
  path: string
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sinceId: string # The since commit hash to stream a diff between two arbitrary hashes
  --srcPath: string # The previous path to the file, if the file has been copied, moved or renamed
  --untilId: string # The until commit hash to stream a diff between two arbitrary hashes
  --whitespace: string # Optional whitespace flag which can be set to <code>ignore-all</code>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sinceId" $sinceId "scalar") (serialize-qp "srcPath" $srcPath "scalar") (serialize-qp "untilId" $untilId "scalar") (serialize-qp "whitespace" $whitespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/diff-stats-summary/($path)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stream a diff within a pull request
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/diff/{path}
# operationId: streamDiff_2
export def "latest-projects-repos-pull-requests-diff streamDiff-by-path-projectKey-pullRequestId-repositorySlug" [
  path: string
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatarScheme: string # The security scheme for avatar URLs. If the scheme is not present then it is inherited from the request. It can be set to "https" to force the use of secure URLs. Not applicable if streaming raw diff
  --contextLines: string # The number of context lines to include around added/removed lines in the diff
  --sinceId: string # The since commit hash to stream a diff between two arbitrary hashes
  --srcPath: string # The previous path to the file, if the file has been copied, moved or renamed
  --diffType: string # The type of diff being requested. When withComments is true this works as a hint to the system to attach the correct set of comments to the diff. Not applicable if streaming raw diff
  --untilId: string # The until commit hash to stream a diff between two arbitrary hashes
  --whitespace: string # Optional whitespace flag which can be set to <code>ignore-all</code>
  --withComments: string # <code>true</code> to embed comments in the diff (the default); otherwise, <code>false</code> to stream the diff without comments. Not applicable if streaming raw diff
  --avatarSize: string # If present the service adds avatar URLs for comment authors where the provided value specifies the desired avatar size in pixels. Not applicable if streaming raw diff
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "avatarScheme" $avatarScheme "scalar") (serialize-qp "contextLines" $contextLines "scalar") (serialize-qp "sinceId" $sinceId "scalar") (serialize-qp "srcPath" $srcPath "scalar") (serialize-qp "diffType" $diffType "scalar") (serialize-qp "untilId" $untilId "scalar") (serialize-qp "whitespace" $whitespace "scalar") (serialize-qp "withComments" $withComments "scalar") (serialize-qp "avatarSize" $avatarSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/diff/($path)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test if pull request can be merged
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/merge
# operationId: canMerge
export def "latest-projects-repos-pull-requests-merge canMerge" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/merge")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Merge pull request
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/merge
# operationId: merge
export def "latest-projects-repos-pull-requests-merge merge" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The current version of the pull request. If the server's version isn't the same as the specified version the operation will fail. To determine the current version of the pull request it should be fetched from the server prior to this operation. Look for the 'version' attribute in the returned JSON structure.
  --autoMerge: oneof<nothing, bool> # e.g. false
  --autoSubject: string # e.g. (Optional, 5.7+) true to prepend an auto-generated subject to the message (default), or false to use the message as-is
  --bypassMergeQueue: oneof<nothing, bool> # e.g. false
  --message: string # e.g. (Optional) A descriptive message for the merge commit
  --strategyId: string # e.g. (Optional) squash
  --version: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/merge" $qp)
  let body = {autoMerge: $autoMerge, autoSubject: $autoSubject, bypassMergeQueue: $bypassMergeQueue, message: $message, strategyId: $strategyId, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the common ancestor between the latest commits of the source and target branches of the pull request
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/merge-base
# operationId: getMergeBase_1
export def "latest-projects-repos-pull-requests-merge-base get-by-projectKey-pullRequestId-repositorySlug" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/merge-base")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unassign pull request participant
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/participants
# DEPRECATED
# operationId: unassignParticipantRole_1
@deprecated
export def "latest-projects-repos-pull-requests-participants unassignParticipantRole-by-projectKey-pullRequestId-repositorySlug" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/participants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pull request participants
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/participants
# operationId: listParticipants
export def "latest-projects-repos-pull-requests-participants listParticipants" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/participants" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign pull request participant role
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/participants
# operationId: assignParticipantRole
# --user shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
export def "latest-projects-repos-pull-requests-participants assignParticipantRole" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer
  --user: record # shape: {active?: bool, avatarUrl?: string, displayName: string, emailAddress?: string, links?: record, name: string, slug: string, type: "NORMAL"|"SERVICE"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/participants")
  let body = {role: $role, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unassign pull request participant
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/participants/{userSlug}
# operationId: unassignParticipantRole
export def "latest-projects-repos-pull-requests-participants unassignParticipantRole" [
  projectKey: string
  userSlug: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/participants/($userSlug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change pull request status
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/participants/{userSlug}
# operationId: updateStatus
@deprecated --flag version
export def "latest-projects-repos-pull-requests-participants updateStatus" [
  projectKey: string
  userSlug: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The current version of the pull request. If the server's version isn't the same as the specified version the operation will fail. To determine the current version of the pull request it should be fetched from the server prior to this operation. Look for the 'version' attribute in the returned JSON structure. Note: This parameter is deprecated. Use last reviewed commit in request body instead (DEPRECATED)
  --lastReviewedCommit: string # e.g. 685cac2c4499ff1f308851e35d2b4357844d8927
  --status: string@status-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/participants/($userSlug)" $qp)
  let body = {lastReviewedCommit: $lastReviewedCommit, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Re-open pull request
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/reopen
# operationId: reopen
export def "latest-projects-repos-pull-requests-reopen reopen" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The current version of the pull request. If the server's version isn't the same as the specified version the operation will fail. To determine the current version of the pull request it should be fetched from the server prior to this operation. Look for the 'version' attribute in the returned JSON structure.
  --version: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/reopen" $qp)
  let body = {version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Discard pull request review
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/review
# operationId: discardReview
export def "latest-projects-repos-pull-requests-review discardReview" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/review")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pull request comment thread
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/review
# operationId: getReview
export def "latest-projects-repos-pull-requests-review get" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/review" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Complete pull request review
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/review
# operationId: finishReview
@deprecated --flag version
export def "latest-projects-repos-pull-requests-review finishReview" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The current version of the pull request. If the server's version isn't the same as the specified version the operation will fail. To determine the current version of the pull request it should be fetched from the server prior to this operation. Look for the 'version' attribute in the returned JSON structure. Note: This parameter is deprecated. Use last reviewed commit in request body instead (DEPRECATED)
  --commentText: string # e.g. General comment text
  --lastReviewedCommit: string # e.g. 685cac2c4499ff1f308851e35d2b4357844d8927
  --participantStatus: string # e.g. approved
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/review" $qp)
  let body = {commentText: $commentText, lastReviewedCommit: $lastReviewedCommit, participantStatus: $participantStatus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Stop watching pull request
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/watch
# operationId: unwatch_1
export def "latest-projects-repos-pull-requests-watch unwatch-by-projectKey-pullRequestId-repositorySlug" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/watch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Watch pull request
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}/watch
# operationId: watch_1
export def "latest-projects-repos-pull-requests-watch watch-by-projectKey-pullRequestId-repositorySlug" [
  projectKey: string
  pullRequestId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/pull-requests/($pullRequestId)/watch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get raw content of a file at revision
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/raw/{path}
# operationId: streamRaw
export def "latest-projects-repos-raw streamRaw" [
  path: string
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --at: string # A specific commit or ref to retrieve the raw content at, or the default branch if not specified
  --markup: string # If present or "true", triggers the raw content to be markup-rendered and returned as HTML; otherwise, if not specified, or any value other than "true", the content is streamed without markup
  --htmlEscape: string # (Optional) true if HTML should be escaped in the input markup, false otherwise. If not specified, the value of the markup.render.html.escape property, which is true by default, will be used
  --includeHeadingId: string # (Optional) true if headings should contain an ID based on the heading content. If not specified, the value of the markup.render.headerids property, which is false by default, will be used
  --hardwrap: string # (Optional) Whether the markup implementation should convert newlines to breaks. If not specified, the value of the markup.render.hardwrap property, which is true by default, will be used
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "at" $at "scalar") (serialize-qp "markup" $markup "scalar") (serialize-qp "htmlEscape" $htmlEscape "scalar") (serialize-qp "includeHeadingId" $includeHeadingId "scalar") (serialize-qp "hardwrap" $hardwrap "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/raw/($path)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get repository readme
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/readme
# operationId: streamReadme
export def "latest-projects-repos-readme streamReadme" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --at: string # A specific commit or ref to retrieve the guidelines at, or the default branch if not specified
  --markup: string # If present or <code>"true"</code>, triggers the raw content to be markup-rendered and returned as HTML; otherwise, if not specified, or any value other than <code>"true"</code>, the content is streamed without markup
  --htmlEscape: string # (Optional) true if HTML should be escaped in the input markup, false otherwise. If not specified, the value of the <code>markup.render.html.escape</code> property, which is <code>true</code> by default, will be used
  --includeHeadingId: string # (Optional) true if headings should contain an ID based on the heading content. If not specified, the value of the <code>markup.render.headerids</code> property, which is false by default, will be used
  --hardwrap: string # (Optional) Whether the markup implementation should convert newlines to breaks. If not specified, the value of the <code>markup.render.hardwrap</code> property, which is <code>true</code> by default, will be used
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "at" $at "scalar") (serialize-qp "markup" $markup "scalar") (serialize-qp "htmlEscape" $htmlEscape "scalar") (serialize-qp "includeHeadingId" $includeHeadingId "scalar") (serialize-qp "hardwrap" $hardwrap "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/readme" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retry repository creation
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/recreate
# operationId: retryCreateRepository
export def "latest-projects-repos-recreate retryCreateRepository" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/recreate")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get ref change activity
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/ref-change-activities
# operationId: getRefChangeActivity
export def "latest-projects-repos-ref-change-activities get" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ref: string # (optional) exact match for a ref ID to filter ref change activity for
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ref" $ref "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/ref-change-activities" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get branches with ref change activities for repository
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/ref-change-activities/branches
# operationId: findBranches
export def "latest-projects-repos-ref-change-activities-branches findBranches" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filterText: string # (optional) Partial match for a ref ID to filter minimal refs for
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterText" $filterText "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/ref-change-activities/branches" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get related repository
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/related
# operationId: getRelatedRepositories
export def "latest-projects-repos-related get" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/related" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find repository secret scanning allowlist rules
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/secret-scanning/allowlist
# operationId: search_2
export def "latest-projects-repos-secret-scanning-allowlist search-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter names by the provided text (e.g. Access)
  --order: string@order-completer-1 # Order by
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/secret-scanning/allowlist" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create repository secret scanning allowlist rule
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/secret-scanning/allowlist
# operationId: createAllowlistRule_1
export def "latest-projects-repos-secret-scanning-allowlist createAllowlistRule-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/secret-scanning/allowlist")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $body
}

# Delete a repository secret scanning allowlist rule
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/secret-scanning/allowlist/{id}
# operationId: deleteAllowlistRule_1
export def "latest-projects-repos-secret-scanning-allowlist delete-by-projectKey-id-repositorySlug" [
  projectKey: string
  id: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/secret-scanning/allowlist/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a repository secret scanning allowlist rule
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/secret-scanning/allowlist/{id}
# operationId: getAllowlistRule_1
export def "latest-projects-repos-secret-scanning-allowlist get-by-projectKey-id-repositorySlug" [
  projectKey: string
  id: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/secret-scanning/allowlist/($id)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit an existing repository secret scanning allowlist rule
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/secret-scanning/allowlist/{id}
# operationId: editAllowlistRule_1
export def "latest-projects-repos-secret-scanning-allowlist editAllowlistRule-by-projectKey-id-repositorySlug" [
  projectKey: string
  id: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/secret-scanning/allowlist/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $body
}

# Delete an exempt repository
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/secret-scanning/exempt
# operationId: deleteExemptRepo
export def "latest-projects-repos-secret-scanning-exempt delete" [
  projectKey: any
  repositorySlug: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/secret-scanning/exempt")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get whether a repository is exempt
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/secret-scanning/exempt
# operationId: isRepoExempt
export def "latest-projects-repos-secret-scanning-exempt isRepoExempt" [
  projectKey: any
  repositorySlug: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/secret-scanning/exempt")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Exempt a repo from secret scanning
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/secret-scanning/exempt
# DEPRECATED
# operationId: addExemptRepo
@deprecated
export def "latest-projects-repos-secret-scanning-exempt addExemptRepo" [
  projectKey: any
  repositorySlug: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/secret-scanning/exempt")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find repository secret scanning rules
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/secret-scanning/rules
# operationId: search_3
export def "latest-projects-repos-secret-scanning-rules search-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter names by the provided text (e.g. Access)
  --order: string@order-completer-1 # Order by
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/secret-scanning/rules" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create repository secret scanning rule
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/secret-scanning/rules
# operationId: createRule_1
export def "latest-projects-repos-secret-scanning-rules createRule-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/secret-scanning/rules")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $body
}

# Delete a repository secret scanning rule
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/secret-scanning/rules/{id}
# operationId: deleteRule_1
export def "latest-projects-repos-secret-scanning-rules delete-by-projectKey-id-repositorySlug" [
  projectKey: string
  id: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/secret-scanning/rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a repository secret scanning rule
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/secret-scanning/rules/{id}
# operationId: getRule_1
export def "latest-projects-repos-secret-scanning-rules get-by-projectKey-id-repositorySlug" [
  projectKey: string
  id: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/secret-scanning/rules/($id)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit an existing repository secret scanning rule
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/secret-scanning/rules/{id}
# operationId: editRule_1
export def "latest-projects-repos-secret-scanning-rules editRule-by-projectKey-id-repositorySlug" [
  projectKey: string
  id: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/secret-scanning/rules/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $body
}

# Delete auto decline settings
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/auto-decline
# operationId: deleteAutoDeclineSettings_1
export def "latest-projects-repos-settings-auto-decline delete-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/auto-decline")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get auto decline settings
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/auto-decline
# operationId: getAutoDeclineSettings_1
export def "latest-projects-repos-settings-auto-decline get-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/auto-decline")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create auto decline settings
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/auto-decline
# operationId: setAutoDeclineSettings_1
export def "latest-projects-repos-settings-auto-decline setAutoDeclineSettings-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # e.g. true
  --inactivityWeeks: int # format: int32, e.g. 4
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/auto-decline")
  let body = {enabled: $enabled, inactivityWeeks: $inactivityWeeks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete pull request auto-merge settings
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/auto-merge
# operationId: delete_5
export def "latest-projects-repos-settings-auto-merge delete-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/auto-merge")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pull request auto-merge settings
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/auto-merge
# operationId: get_5
export def "latest-projects-repos-settings-auto-merge get-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/auto-merge")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update the pull request auto-merge settings
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/auto-merge
# operationId: set_1
export def "latest-projects-repos-settings-auto-merge set-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # e.g. false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/auto-merge")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get repository hooks
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/hooks
# operationId: getRepositoryHooks_1
export def "latest-projects-repos-settings-hooks get-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-3 # The optional type to filter by.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/hooks" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete repository hook
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/hooks/{hookKey}
# operationId: deleteRepositoryHook
export def "latest-projects-repos-settings-hooks delete" [
  projectKey: string
  hookKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/hooks/($hookKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get repository hook
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/hooks/{hookKey}
# operationId: getRepositoryHook_1
export def "latest-projects-repos-settings-hooks get-by-projectKey-hookKey-repositorySlug" [
  projectKey: string
  hookKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/hooks/($hookKey)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable repository hook
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/hooks/{hookKey}/enabled
# operationId: disableHook_1
export def "latest-projects-repos-settings-hooks-enabled disableHook-by-projectKey-hookKey-repositorySlug" [
  projectKey: string
  hookKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/hooks/($hookKey)/enabled")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable repository hook
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/hooks/{hookKey}/enabled
# operationId: enableHook_1
export def "latest-projects-repos-settings-hooks-enabled enableHook-by-projectKey-hookKey-repositorySlug" [
  projectKey: string
  hookKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Length: string # The content length.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/hooks/($hookKey)/enabled")
  let extra_headers = {"Content-Length": $Content_Length} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get repository hook settings
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/hooks/{hookKey}/settings
# operationId: getSettings_1
export def "latest-projects-repos-settings-hooks-settings get-by-projectKey-hookKey-repositorySlug" [
  projectKey: string
  hookKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/hooks/($hookKey)/settings")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update repository hook settings
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/hooks/{hookKey}/settings
# operationId: setSettings_1
export def "latest-projects-repos-settings-hooks-settings setSettings-by-projectKey-hookKey-repositorySlug" [
  projectKey: string
  hookKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --booleanValue: oneof<nothing, bool> # e.g. true
  --doubleValue: float # format: double, e.g. 1.1
  --integerValue: int # format: int32, e.g. 1
  --longValue: int # format: int64, e.g. -2147483648
  --stringValue: string # e.g. This is an arbitrary string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/hooks/($hookKey)/settings")
  let body = {booleanValue: $booleanValue, doubleValue: $doubleValue, integerValue: $integerValue, longValue: $longValue, stringValue: $stringValue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get pull request settings
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/pull-requests
# operationId: getPullRequestSettings_1
export def "latest-projects-repos-settings-pull-requests get-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/pull-requests")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update pull request settings
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/pull-requests
# operationId: updatePullRequestSettings_1
# --mergeConfig shape: {commitMessageTemplate?: record, commitSummaries?: int, defaultStrategy?: record, strategies: list}
# --requiredApprovers shape: {count?: string, enabled?: bool}
# --requiredSuccessfulBuilds shape: {count?: string, enabled?: bool}
export def "latest-projects-repos-settings-pull-requests updatePullRequestSettings-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mergeConfig: record # shape: {commitMessageTemplate?: record, commitSummaries?: int, defaultStrategy?: record, strategies: list}
  --requiredAllApprovers: oneof<nothing, bool>
  --requiredAllTasksComplete: oneof<nothing, bool>
  --requiredApprovers: record # shape: {count?: string, enabled?: bool}
  --requiredApproversDeprecated: int # format: int32
  --requiredSuccessfulBuilds: record # shape: {count?: string, enabled?: bool}
  --requiredSuccessfulBuildsDeprecated: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/pull-requests")
  let body = {mergeConfig: $mergeConfig, requiredAllApprovers: $requiredAllApprovers, requiredAllTasksComplete: $requiredAllTasksComplete, requiredApprovers: $requiredApprovers, requiredApproversDeprecated: $requiredApproversDeprecated, requiredSuccessfulBuilds: $requiredSuccessfulBuilds, requiredSuccessfulBuildsDeprecated: $requiredSuccessfulBuildsDeprecated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all reviewer groups
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/reviewer-groups
# operationId: getReviewerGroups_1
export def "latest-projects-repos-settings-reviewer-groups get-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/reviewer-groups" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create reviewer group
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/reviewer-groups
# operationId: create_2
# --scope shape: {resourceId: int, type: "GLOBAL"|"PROJECT"|"REPOSITORY"}
# --users item shape: {active?: bool, displayName?: string, emailAddress?: string, id?: int, name?: string, slug?: string, type?: "NORMAL"|"SERVICE"}
export def "latest-projects-repos-settings-reviewer-groups create-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatarUrl: string
  --description: string # e.g. null
  --id: int # format: int64
  --name: string # e.g. name
  --scope: record # shape: {resourceId: int, type: "GLOBAL"|"PROJECT"|"REPOSITORY"}
  --users: list # item shape: {active?: bool, displayName?: string, emailAddress?: string, id?: int, name?: string, slug?: string, type?: "NORMAL"|"SERVICE"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/reviewer-groups")
  let body = {avatarUrl: $avatarUrl, description: $description, id: $id, name: $name, scope: $scope, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete reviewer group
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/reviewer-groups/{id}
# operationId: delete_7
export def "latest-projects-repos-settings-reviewer-groups delete-by-projectKey-id-repositorySlug" [
  projectKey: string
  id: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/reviewer-groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get reviewer group
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/reviewer-groups/{id}
# operationId: getReviewerGroup_1
export def "latest-projects-repos-settings-reviewer-groups get-by-projectKey-id-repositorySlug" [
  projectKey: string
  id: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/reviewer-groups/($id)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update reviewer group attributes
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/reviewer-groups/{id}
# operationId: update_2
# --scope shape: {resourceId: int, type: "GLOBAL"|"PROJECT"|"REPOSITORY"}
# --users item shape: {active?: bool, displayName?: string, emailAddress?: string, id?: int, name?: string, slug?: string, type?: "NORMAL"|"SERVICE"}
export def "latest-projects-repos-settings-reviewer-groups update-by-projectKey-id-repositorySlug" [
  projectKey: string
  id: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatarUrl: string
  --description: string # e.g. null
  --body-id: int # format: int64
  --name: string # e.g. name
  --scope: record # shape: {resourceId: int, type: "GLOBAL"|"PROJECT"|"REPOSITORY"}
  --users: list # item shape: {active?: bool, displayName?: string, emailAddress?: string, id?: int, name?: string, slug?: string, type?: "NORMAL"|"SERVICE"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/reviewer-groups/($id)")
  let body = {avatarUrl: $avatarUrl, description: $description, id: $body_id, name: $name, scope: $scope, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get reviewer group users
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/settings/reviewer-groups/{id}/users
# operationId: getUsers
export def "latest-projects-repos-settings-reviewer-groups-users get" [
  projectKey: string
  id: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/settings/reviewer-groups/($id)/users")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find tag
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/tags
# operationId: getTags
export def "latest-projects-repos-tags list" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --orderBy: string # Ordering of refs either ALPHABETICAL (by name) or MODIFICATION (last updated)
  --filterText: string # The text to match on.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "filterText" $filterText "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/tags" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create tag
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/tags
# operationId: createTagForRepository
export def "latest-projects-repos-tags createTagForRepository" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # e.g. This is my branch or tag
  --name: string # e.g. my-branch-or-tag
  --startPoint: string # e.g. 8d351a10fb428c0c1239530256e21cf24f136e73
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/tags")
  let body = {message: $message, name: $name, startPoint: $startPoint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get tag
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/tags/{name}
# operationId: getTag
export def "latest-projects-repos-tags get" [
  projectKey: string
  name: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/tags/($name)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop watching repository
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/watch
# operationId: unwatch_2
export def "latest-projects-repos-watch unwatch-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/watch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Watch repository
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/watch
# operationId: watch_2
# --origin shape: {defaultBranch?: string, links?: record, name?: string, project?: record, scmId?: string, slug?: string}
# --project shape: {avatar?: string, avatarUrl?: string, key: string, links?: record}
export def "latest-projects-repos-watch watch-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --defaultBranch: string # e.g. main
  --links: record
  --name: string # e.g. My repo
  --project: record # shape: {avatar?: string, avatarUrl?: string, key: string, links?: record}
  --scmId: string # e.g. git
  --slug: string # e.g. my-repo
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/watch")
  let body = {defaultBranch: $defaultBranch, links: $links, name: $name, project: $project, scmId: $scmId, slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Find webhooks
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/webhooks
# operationId: findWebhooks_1
export def "latest-projects-repos-webhooks findWebhooks-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --event: string # List of <code>com.atlassian.webhooks.WebhookEvent</code> IDs to filter for
  --statistics: oneof<nothing, bool> # <code>true</code> if statistics should be provided for all found webhooks
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event" $event "scalar") (serialize-qp "statistics" $statistics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/webhooks" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create webhook
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/webhooks
# operationId: createWebhook_1
# --credentials shape: {password?: string, username?: string}
export def "latest-projects-repos-webhooks createWebhook-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --configuration: record
  --credentials: any # shape: {password?: string, username?: string}
  --events: list
  --name: string
  --scopeType: string
  --sslVerificationRequired: oneof<nothing, bool>
  --statistics: record
  --body-url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/webhooks")
  let body = {active: $active, configuration: $configuration, credentials: $credentials, events: $events, name: $name, scopeType: $scopeType, sslVerificationRequired: $sslVerificationRequired, statistics: $statistics, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search webhooks
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/webhooks/search
# operationId: searchWebhooks
export def "latest-projects-repos-webhooks-search searchWebhooks" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scopeType: string # Scopes to filter by. This parameter can be specified once e.g. "scopeType=repository", or twice e.g. "scopeType=repository&scopeType=project", to filter by more than one scope level. 
  --event: string # List of <code>com.atlassian.webhooks.WebhookEvent</code> ids to filter for
  --statistics: oneof<nothing, bool> # <code>true</code> if statistics should be provided for all found webhooks
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scopeType" $scopeType "scalar") (serialize-qp "event" $event "scalar") (serialize-qp "statistics" $statistics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/webhooks/search" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test webhook
#
# POST /api/latest/projects/{projectKey}/repos/{repositorySlug}/webhooks/test
# operationId: testWebhook_1
export def "latest-projects-repos-webhooks-test testWebhook-by-projectKey-repositorySlug" [
  projectKey: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --webhookId: int # format: int32
  --sslVerificationRequired: string # Whether SSL verification is required for the specified webhook URL. Default value is  <code>true</code>.
  --qp-url: string # The url in which to connect to
  --password: string
  --username: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "webhookId" $webhookId "scalar") (serialize-qp "sslVerificationRequired" $sslVerificationRequired "scalar") (serialize-qp "url" $qp_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/webhooks/test" $qp)
  let body = {password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete webhook
#
# DELETE /api/latest/projects/{projectKey}/repos/{repositorySlug}/webhooks/{webhookId}
# operationId: deleteWebhook_1
export def "latest-projects-repos-webhooks delete-by-projectKey-webhookId-repositorySlug" [
  projectKey: string
  webhookId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get webhook
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/webhooks/{webhookId}
# operationId: getWebhook_1
export def "latest-projects-repos-webhooks get-by-projectKey-webhookId-repositorySlug" [
  projectKey: string
  webhookId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --statistics: string # <code>true</code> if statistics should be provided for the webhook
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statistics" $statistics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/webhooks/($webhookId)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update webhook
#
# PUT /api/latest/projects/{projectKey}/repos/{repositorySlug}/webhooks/{webhookId}
# operationId: updateWebhook_1
# --credentials shape: {password?: string, username?: string}
export def "latest-projects-repos-webhooks updateWebhook-by-projectKey-webhookId-repositorySlug" [
  projectKey: string
  webhookId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --configuration: record
  --credentials: any # shape: {password?: string, username?: string}
  --events: list
  --name: string
  --scopeType: string
  --sslVerificationRequired: oneof<nothing, bool>
  --statistics: record
  --body-url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/webhooks/($webhookId)")
  let body = {active: $active, configuration: $configuration, credentials: $credentials, events: $events, name: $name, scopeType: $scopeType, sslVerificationRequired: $sslVerificationRequired, statistics: $statistics, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get last webhook invocation details
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/webhooks/{webhookId}/latest
# operationId: getLatestInvocation_1
export def "latest-projects-repos-webhooks-latest get-by-projectKey-webhookId-repositorySlug" [
  projectKey: string
  webhookId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --event: string # The string ID of a specific event to retrieve the last invocation for.
  --outcome: string # The outcome to filter for. Can be SUCCESS, FAILURE, ERROR. None specified means that the all will be considered
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event" $event "scalar") (serialize-qp "outcome" $outcome "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/webhooks/($webhookId)/latest" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get webhook statistics
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/webhooks/{webhookId}/statistics
# operationId: getStatistics_1
export def "latest-projects-repos-webhooks-statistics get-by-projectKey-webhookId-repositorySlug" [
  projectKey: string
  webhookId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --event: string # The string ID of a specific event to retrieve the last invocation for. May be empty, in which case all events are considered
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event" $event "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/webhooks/($webhookId)/statistics" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get webhook statistics summary
#
# GET /api/latest/projects/{projectKey}/repos/{repositorySlug}/webhooks/{webhookId}/statistics/summary
# operationId: getStatisticsSummary_1
export def "latest-projects-repos-webhooks-statistics-summary get-by-projectKey-webhookId-repositorySlug" [
  projectKey: string
  webhookId: string
  repositorySlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/repos/($repositorySlug)/webhooks/($webhookId)/statistics/summary")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find project secret scanning allowlist rules
#
# GET /api/latest/projects/{projectKey}/secret-scanning/allowlist
# operationId: searchAllowlistRule
export def "latest-projects-secret-scanning-allowlist searchAllowlistRule" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter names by the provided text (e.g. Access)
  --order: string@order-completer-1 # Order by
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/secret-scanning/allowlist" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create project secret scanning allowlist rule
#
# POST /api/latest/projects/{projectKey}/secret-scanning/allowlist
# operationId: createAllowlistRule
export def "latest-projects-secret-scanning-allowlist createAllowlistRule" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/secret-scanning/allowlist")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $body
}

# Delete a project secret scanning allowlist rule
#
# DELETE /api/latest/projects/{projectKey}/secret-scanning/allowlist/{id}
# operationId: deleteAllowlistRule
export def "latest-projects-secret-scanning-allowlist delete" [
  projectKey: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/secret-scanning/allowlist/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a project secret scanning allowlist rule
#
# GET /api/latest/projects/{projectKey}/secret-scanning/allowlist/{id}
# operationId: getAllowlistRule
export def "latest-projects-secret-scanning-allowlist get" [
  projectKey: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/secret-scanning/allowlist/($id)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit an existing project secret scanning allowlist rule
#
# PUT /api/latest/projects/{projectKey}/secret-scanning/allowlist/{id}
# operationId: editAllowlistRule
export def "latest-projects-secret-scanning-allowlist editAllowlistRule" [
  projectKey: string
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/secret-scanning/allowlist/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $body
}

# Find repos exempt from secret scanning for a project
#
# GET /api/latest/projects/{projectKey}/secret-scanning/exempt
# operationId: findExemptReposByProject
export def "latest-projects-secret-scanning-exempt findExemptReposByProject" [
  projectKey: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer-1 # Order by project name followed by repository name either ascending or descending, defaults to ascending.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/secret-scanning/exempt" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk exempt repos from secret scanning
#
# POST /api/latest/projects/{projectKey}/secret-scanning/exempt
# operationId: bulkAddExemptRepositories_1
export def "latest-projects-secret-scanning-exempt bulkAddExemptRepositories-by-projectKey" [
  projectKey: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/secret-scanning/exempt")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $body
}

# Find project secret scanning rules
#
# GET /api/latest/projects/{projectKey}/secret-scanning/rules
# operationId: search_1
export def "latest-projects-secret-scanning-rules search-by-projectKey" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter names by the provided text (e.g. Access)
  --order: string@order-completer-1 # Order by
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/secret-scanning/rules" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create project secret scanning rule
#
# POST /api/latest/projects/{projectKey}/secret-scanning/rules
# operationId: createRule
export def "latest-projects-secret-scanning-rules createRule" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/secret-scanning/rules")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $body
}

# Delete a project secret scanning rule
#
# DELETE /api/latest/projects/{projectKey}/secret-scanning/rules/{id}
# operationId: deleteRule
export def "latest-projects-secret-scanning-rules delete" [
  projectKey: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/secret-scanning/rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a project secret scanning rule
#
# GET /api/latest/projects/{projectKey}/secret-scanning/rules/{id}
# operationId: getRule
export def "latest-projects-secret-scanning-rules get" [
  projectKey: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/secret-scanning/rules/($id)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit an existing project secret scanning rule
#
# PUT /api/latest/projects/{projectKey}/secret-scanning/rules/{id}
# operationId: editRule
export def "latest-projects-secret-scanning-rules editRule" [
  projectKey: string
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/secret-scanning/rules/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $body
}

# Stop enforcing project restriction
#
# DELETE /api/latest/projects/{projectKey}/settings-restriction
# operationId: delete_9
export def "latest-projects-settings-restriction delete-by-projectKey" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string # A namespace used to identify the provider of the feature
  --componentKey: string # A key to uniquely identify individually restrictable subcomponents of a feature within the provided feature key and namespace
  --featureKey: string # A key to uniquely identify the feature within the provided namespace
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "componentKey" $componentKey "scalar") (serialize-qp "featureKey" $featureKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings-restriction" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get enforcing project setting
#
# GET /api/latest/projects/{projectKey}/settings-restriction
# operationId: get_7
export def "latest-projects-settings-restriction get-by-projectKey" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string # The namespace used to identify the provider of the feature
  --componentKey: string # The component key to uniquely identify individually restrictable subcomponents of a feature within the provided feature key and namespace
  --featureKey: string # The feature key to uniquely identify the feature within the provided namespace
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "componentKey" $componentKey "scalar") (serialize-qp "featureKey" $featureKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings-restriction" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enforce project restriction
#
# POST /api/latest/projects/{projectKey}/settings-restriction
# operationId: create_3
export def "latest-projects-settings-restriction create-by-projectKey" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --componentKey: string # e.g. my-admin-component
  featureKey: string # e.g. my-admin-feature
  namespace: string # e.g. org.featuredeveloper
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings-restriction")
  let body = {componentKey: $componentKey, featureKey: $featureKey, namespace: $namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all enforcing project settings
#
# GET /api/latest/projects/{projectKey}/settings-restriction/all
# operationId: getAll
export def "latest-projects-settings-restriction-all get" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string # A namespace used to identify the provider of the feature
  --featureKey: string # A key to uniquely identify the feature within the provided namespace
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "featureKey" $featureKey "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings-restriction/all" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete auto decline settings
#
# DELETE /api/latest/projects/{projectKey}/settings/auto-decline
# operationId: deleteAutoDeclineSettings
export def "latest-projects-settings-auto-decline delete" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings/auto-decline")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get auto decline settings
#
# GET /api/latest/projects/{projectKey}/settings/auto-decline
# operationId: getAutoDeclineSettings
export def "latest-projects-settings-auto-decline get" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings/auto-decline")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create/Update auto decline settings
#
# PUT /api/latest/projects/{projectKey}/settings/auto-decline
# operationId: setAutoDeclineSettings
export def "latest-projects-settings-auto-decline setAutoDeclineSettings" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # e.g. true
  --inactivityWeeks: int # format: int32, e.g. 4
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings/auto-decline")
  let body = {enabled: $enabled, inactivityWeeks: $inactivityWeeks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete pull request auto-merge settings
#
# DELETE /api/latest/projects/{projectKey}/settings/auto-merge
# operationId: delete_4
export def "latest-projects-settings-auto-merge delete-by-projectKey" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings/auto-merge")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pull request auto-merge settings
#
# GET /api/latest/projects/{projectKey}/settings/auto-merge
# operationId: get_4
export def "latest-projects-settings-auto-merge get-by-projectKey" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings/auto-merge")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update the pull request auto-merge settings
#
# PUT /api/latest/projects/{projectKey}/settings/auto-merge
# operationId: set
export def "latest-projects-settings-auto-merge set" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # e.g. false
  --restrictionAction: string@restrictionAction-completer # e.g. CREATE
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings/auto-merge")
  let body = {enabled: $enabled, restrictionAction: $restrictionAction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get repository hooks
#
# GET /api/latest/projects/{projectKey}/settings/hooks
# operationId: getRepositoryHooks
export def "latest-projects-settings-hooks list" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-3 # The optional type to filter by.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings/hooks" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a repository hook
#
# GET /api/latest/projects/{projectKey}/settings/hooks/{hookKey}
# operationId: getRepositoryHook
export def "latest-projects-settings-hooks get" [
  projectKey: string
  hookKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings/hooks/($hookKey)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable repository hook
#
# DELETE /api/latest/projects/{projectKey}/settings/hooks/{hookKey}/enabled
# operationId: disableHook
export def "latest-projects-settings-hooks-enabled disableHook" [
  projectKey: string
  hookKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings/hooks/($hookKey)/enabled")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable repository hook
#
# PUT /api/latest/projects/{projectKey}/settings/hooks/{hookKey}/enabled
# operationId: enableHook
export def "latest-projects-settings-hooks-enabled enableHook" [
  projectKey: string
  hookKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Length: int # The content length.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings/hooks/($hookKey)/enabled")
  let extra_headers = {"Content-Length": $Content_Length} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get repository hook settings
#
# GET /api/latest/projects/{projectKey}/settings/hooks/{hookKey}/settings
# operationId: getSettings
export def "latest-projects-settings-hooks-settings get" [
  projectKey: string
  hookKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings/hooks/($hookKey)/settings")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update repository hook settings
#
# PUT /api/latest/projects/{projectKey}/settings/hooks/{hookKey}/settings
# operationId: setSettings
export def "latest-projects-settings-hooks-settings setSettings" [
  projectKey: string
  hookKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --booleanValue: oneof<nothing, bool> # e.g. true
  --doubleValue: float # format: double, e.g. 1.1
  --integerValue: int # format: int32, e.g. 1
  --longValue: int # format: int64, e.g. -2147483648
  --stringValue: string # e.g. This is an arbitrary string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings/hooks/($hookKey)/settings")
  let body = {booleanValue: $booleanValue, doubleValue: $doubleValue, integerValue: $integerValue, longValue: $longValue, stringValue: $stringValue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get merge strategy
#
# GET /api/latest/projects/{projectKey}/settings/pull-requests/{scmId}
# operationId: getPullRequestSettings
export def "latest-projects-settings-pull-requests get" [
  projectKey: string
  scmId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings/pull-requests/($scmId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update merge strategy
#
# POST /api/latest/projects/{projectKey}/settings/pull-requests/{scmId}
# operationId: updatePullRequestSettings
# --mergeConfig shape: {commitMessageTemplate?: record, commitSummaries?: int, defaultStrategy?: record, strategies: list}
export def "latest-projects-settings-pull-requests updatePullRequestSettings" [
  projectKey: string
  scmId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mergeConfig: record # shape: {commitMessageTemplate?: record, commitSummaries?: int, defaultStrategy?: record, strategies: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings/pull-requests/($scmId)")
  let body = {mergeConfig: $mergeConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all reviewer groups
#
# GET /api/latest/projects/{projectKey}/settings/reviewer-groups
# operationId: getReviewerGroups
export def "latest-projects-settings-reviewer-groups list" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings/reviewer-groups" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create reviewer group
#
# POST /api/latest/projects/{projectKey}/settings/reviewer-groups
# operationId: create_1
# --scope shape: {resourceId: int, type: "GLOBAL"|"PROJECT"|"REPOSITORY"}
# --users item shape: {active?: bool, displayName?: string, emailAddress?: string, id?: int, name?: string, slug?: string, type?: "NORMAL"|"SERVICE"}
export def "latest-projects-settings-reviewer-groups create-by-projectKey" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatarUrl: string
  --description: string # e.g. null
  --id: int # format: int64
  --name: string # e.g. name
  --scope: record # shape: {resourceId: int, type: "GLOBAL"|"PROJECT"|"REPOSITORY"}
  --users: list # item shape: {active?: bool, displayName?: string, emailAddress?: string, id?: int, name?: string, slug?: string, type?: "NORMAL"|"SERVICE"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings/reviewer-groups")
  let body = {avatarUrl: $avatarUrl, description: $description, id: $id, name: $name, scope: $scope, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete reviewer group
#
# DELETE /api/latest/projects/{projectKey}/settings/reviewer-groups/{id}
# operationId: delete_6
export def "latest-projects-settings-reviewer-groups delete-by-projectKey-id" [
  projectKey: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings/reviewer-groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get reviewer group
#
# GET /api/latest/projects/{projectKey}/settings/reviewer-groups/{id}
# operationId: getReviewerGroup
export def "latest-projects-settings-reviewer-groups get" [
  projectKey: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings/reviewer-groups/($id)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update reviewer group attributes
#
# PUT /api/latest/projects/{projectKey}/settings/reviewer-groups/{id}
# operationId: update_1
# --scope shape: {resourceId: int, type: "GLOBAL"|"PROJECT"|"REPOSITORY"}
# --users item shape: {active?: bool, displayName?: string, emailAddress?: string, id?: int, name?: string, slug?: string, type?: "NORMAL"|"SERVICE"}
export def "latest-projects-settings-reviewer-groups update-by-projectKey-id" [
  projectKey: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatarUrl: string
  --description: string # e.g. null
  --body-id: int # format: int64
  --name: string # e.g. name
  --scope: record # shape: {resourceId: int, type: "GLOBAL"|"PROJECT"|"REPOSITORY"}
  --users: list # item shape: {active?: bool, displayName?: string, emailAddress?: string, id?: int, name?: string, slug?: string, type?: "NORMAL"|"SERVICE"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/settings/reviewer-groups/($id)")
  let body = {avatarUrl: $avatarUrl, description: $description, id: $body_id, name: $name, scope: $scope, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Find webhooks
#
# GET /api/latest/projects/{projectKey}/webhooks
# operationId: findWebhooks
export def "latest-projects-webhooks findWebhooks" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --event: string # List of <code>com.atlassian.webhooks.WebhookEvent</code> IDs to filter for
  --statistics: oneof<nothing, bool> # <code>true</code> if statistics should be provided for all found webhooks
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event" $event "scalar") (serialize-qp "statistics" $statistics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/webhooks" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create webhook
#
# POST /api/latest/projects/{projectKey}/webhooks
# operationId: createWebhook
# --credentials shape: {password?: string, username?: string}
export def "latest-projects-webhooks createWebhook" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --configuration: record
  --credentials: any # shape: {password?: string, username?: string}
  --events: list
  --name: string
  --scopeType: string
  --sslVerificationRequired: oneof<nothing, bool>
  --statistics: record
  --body-url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/webhooks")
  let body = {active: $active, configuration: $configuration, credentials: $credentials, events: $events, name: $name, scopeType: $scopeType, sslVerificationRequired: $sslVerificationRequired, statistics: $statistics, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Test webhook
#
# POST /api/latest/projects/{projectKey}/webhooks/test
# operationId: testWebhook
export def "latest-projects-webhooks-test testWebhook" [
  projectKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --webhookId: int # format: int32
  --sslVerificationRequired: oneof<nothing, bool> # default: true
  --qp-url: string # The url in which to connect to
  --password: string
  --username: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "webhookId" $webhookId "scalar") (serialize-qp "sslVerificationRequired" $sslVerificationRequired "scalar") (serialize-qp "url" $qp_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/webhooks/test" $qp)
  let body = {password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete webhook
#
# DELETE /api/latest/projects/{projectKey}/webhooks/{webhookId}
# operationId: deleteWebhook
export def "latest-projects-webhooks delete" [
  projectKey: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get webhook
#
# GET /api/latest/projects/{projectKey}/webhooks/{webhookId}
# operationId: getWebhook
export def "latest-projects-webhooks get" [
  projectKey: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --statistics: string # <code>true</code> if statistics should be provided for the webhook
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statistics" $statistics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/webhooks/($webhookId)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update webhook
#
# PUT /api/latest/projects/{projectKey}/webhooks/{webhookId}
# operationId: updateWebhook
# --credentials shape: {password?: string, username?: string}
export def "latest-projects-webhooks updateWebhook" [
  projectKey: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --configuration: record
  --credentials: any # shape: {password?: string, username?: string}
  --events: list
  --name: string
  --scopeType: string
  --sslVerificationRequired: oneof<nothing, bool>
  --statistics: record
  --body-url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/webhooks/($webhookId)")
  let body = {active: $active, configuration: $configuration, credentials: $credentials, events: $events, name: $name, scopeType: $scopeType, sslVerificationRequired: $sslVerificationRequired, statistics: $statistics, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get last webhook invocation details
#
# GET /api/latest/projects/{projectKey}/webhooks/{webhookId}/latest
# operationId: getLatestInvocation
export def "latest-projects-webhooks-latest get" [
  projectKey: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --event: string # The string ID of a specific event to retrieve the last invocation for.
  --outcome: string # The outcome to filter for. Can be SUCCESS, FAILURE, ERROR. None specified means that the all will be considered
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event" $event "scalar") (serialize-qp "outcome" $outcome "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/webhooks/($webhookId)/latest" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get webhook statistics
#
# GET /api/latest/projects/{projectKey}/webhooks/{webhookId}/statistics
# operationId: getStatistics
export def "latest-projects-webhooks-statistics get" [
  projectKey: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --event: string # The string ID of a specific event to retrieve the last invocation for. May be empty, in which case all events are considered
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event" $event "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/webhooks/($webhookId)/statistics" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get webhook statistics summary
#
# GET /api/latest/projects/{projectKey}/webhooks/{webhookId}/statistics/summary
# operationId: getStatisticsSummary
export def "latest-projects-webhooks-statistics-summary get" [
  projectKey: string
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/projects/($projectKey)/webhooks/($webhookId)/statistics/summary")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for repositories
#
# GET /api/latest/repos
# operationId: getRepositories_1
export def "latest-repos get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --archived: string # (optional) if specified, this will limit the resulting repository list to ones whose are <tt>ACTIVE</tt>, <tt>ARCHIVED</tt> or <tt>ALL</tt> for both. The match performed is case-insensitive. This filter defaults to <tt>ACTIVE</tt> when not set. <em>Available since 8.0</em>
  --projectname: string # (optional) if specified, this will limit the resulting repository list to ones whose project's name matches this parameter's value. The match performed is case-insensitive and any leading and/or trailing whitespace characters on the <code>projectname</code> parameter will be stripped.
  --projectkey: string # (optional) if specified, this will limit the resulting repository list to ones whose project's key matches this parameter's value. The match performed is case-insensitive and any leading  and/or trailing whitespace characters on the <code>projectKey</code> parameter will be stripped. <em>Available since 8.0</em>
  --visibility: string@visibility-completer # (optional) if specified, this will limit the resulting repository list based on the repositories visibility. Valid values are <em>public</em> or <em>private</em>.
  --name: string # (optional) if specified, this will limit the resulting repository list to ones whose name matches this parameter's value. The match performed is case-insensitive and any leading and/or trailing whitespace characters on the <code>name</code> parameter will be stripped.
  --permission: string@permission-completer-3 # (optional) if specified, it must be a valid repository permission level name and will limit the resulting repository list to ones that the requesting user has the specified permission level to. If not specified, the default implicit 'read' permission level will be assumed. The currently supported explicit permission values are <tt>REPO_READ</tt>, <tt>REPO_WRITE</tt> and <tt>REPO_ADMIN</tt>.
  --state: string@state-completer-4 # (optional) if specified, it must be a valid repository state name and will limit the resulting repository list to ones that are in the specified state. The currently supported explicit state values are <tt>AVAILABLE</tt>, <tt>INITIALISING</tt> and <tt>INITIALISATION_FAILED</tt>. Filtering by <tt>OFFLINE</tt> repositories is not supported.<br><em>Available since 5.13</em>
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "archived" $archived "scalar") (serialize-qp "projectname" $projectname "scalar") (serialize-qp "projectkey" $projectkey "scalar") (serialize-qp "visibility" $visibility "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "permission" $permission "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/repos" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find all repos exempt from secret scan
#
# GET /api/latest/secret-scanning/exempt
# operationId: findExemptReposByScope
export def "latest-secret-scanning-exempt findExemptReposByScope" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer-1 # Order by project name followed by repository name either ascending or descending, defaults to ascending.
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/secret-scanning/exempt" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk exempt repos from secret scanning
#
# POST /api/latest/secret-scanning/exempt
# operationId: bulkAddExemptRepositories
export def "latest-secret-scanning-exempt bulkAddExemptRepositories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/secret-scanning/exempt")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $body
}

# Find global secret scanning rules
#
# GET /api/latest/secret-scanning/rules
# operationId: search_4
export def "latest-secret-scanning-rules search-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter by rule name (e.g. Access)
  --order: string@order-completer-1 # Order by
  --start: float # Start number for the page (inclusive). If not passed, first page is assumed. (e.g. 0)
  --limit: float # Number of items to return. If not passed, a page size of 25 is used. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/secret-scanning/rules" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create global secret scanning rule
#
# POST /api/latest/secret-scanning/rules
# operationId: createRule_2
export def "latest-secret-scanning-rules createRule-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/secret-scanning/rules")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $body
}

# Delete a global secret scanning rule
#
# DELETE /api/latest/secret-scanning/rules/{id}
# operationId: deleteRule_2
export def "latest-secret-scanning-rules delete-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/secret-scanning/rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a global secret scanning rule
#
# GET /api/latest/secret-scanning/rules/{id}
# operationId: getRule_2
export def "latest-secret-scanning-rules get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/secret-scanning/rules/($id)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a global secret scanning rule.
#
# PUT /api/latest/secret-scanning/rules/{id}
# operationId: editRule_2
export def "latest-secret-scanning-rules editRule-by-id" [
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/secret-scanning/rules/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "*/*" $body
}

# Get all X.509 certificates
#
# GET /api/latest/signing/x509-certificates
# operationId: getAllCertificates
export def "latest-signing-x509-certificates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/signing/x509-certificates")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an X.509 certificate
#
# POST /api/latest/signing/x509-certificates
# operationId: createCertificate
export def "latest-signing-x509-certificates createCertificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificate: string # The X.509 certificate file to upload. (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/signing/x509-certificates")
  let body = {certificate: $certificate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Update X.509 CRL entries
#
# PUT /api/latest/signing/x509-certificates/crl/{id}
# operationId: updateCertificateRevocationListEntries
export def "latest-signing-x509-certificates-crl updateCertificateRevocationListEntries" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/signing/x509-certificates/crl/($id)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an X.509 certificate
#
# DELETE /api/latest/signing/x509-certificates/{id}
# operationId: deleteCertificate
export def "latest-signing-x509-certificates delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/signing/x509-certificates/($id)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get system signing configuration
#
# GET /api/latest/system-signing/configuration
# operationId: getSystemSigningConfiguration
export def "latest-system-signing-configuration get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/system-signing/configuration")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update system signing configuration
#
# POST /api/latest/system-signing/configuration
# operationId: updateSystemSigningConfiguration
export def "latest-system-signing-configuration updateSystemSigningConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # e.g. false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/system-signing/configuration")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all users
#
# GET /api/latest/users
# operationId: getUsers_2
export def "latest-users get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Return only users, whose username, name or email address <i>contain</i> the <code> filter</code> value
  --permissionN: string # The "root" of a single permission filter, similar to the <code>permission</code> parameter, where "N" is a natural number starting from 1. This allows clients to specify multiple permission filters, by providing consecutive filters as <code>permission.1</code>, <code>permission.2</code> etc. Note that the filters numbering has to start with 1 and be continuous for all filters to be processed. The total allowed number of permission filters is 50 and all filters exceeding that limit will be dropped. See the section "Permission Filters" above for more details on how the permission filters are processed.
  --permission: string # The "root" of a permission filter, whose value must be a valid global, project, or repository permission. Additional filter parameters referring to this filter that specify the resource (project or repository) to apply the filter to must be prefixed with <code>permission.</code>. See the section "Permission Filters" above for more details.
  --group: string # return only users who are members of the given group
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "permission.N" $permissionN "scalar") (serialize-qp "permission" $permission "scalar") (serialize-qp "group" $group "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/latest/users" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user details
#
# PUT /api/latest/users
# operationId: updateUserDetails_1
export def "latest-users updateUserDetails-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string # e.g. Jane Citizen
  --email: string # e.g. jane@example.com
  --name: string # e.g. jcitizen
  --password: string # The user's password, which the system may require when users update their email. (e.g. user-password)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/users")
  let body = {displayName: $displayName, email: $email, name: $name, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set password
#
# PUT /api/latest/users/credentials
# operationId: updateUserPassword_1
export def "latest-users-credentials updateUserPassword-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --oldPassword: string # e.g. my-old-secret-password
  --password: string # e.g. my-secret-password
  --passwordConfirm: string # e.g. my-secret-password
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/latest/users/credentials")
  let body = {oldPassword: $oldPassword, password: $password, passwordConfirm: $passwordConfirm} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get user
#
# GET /api/latest/users/{userSlug}
# operationId: getUser
export def "latest-users get" [
  userSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/users/($userSlug)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete user avatar
#
# DELETE /api/latest/users/{userSlug}/avatar.png
# operationId: deleteAvatar
export def "latest-users-avatarpng delete" [
  userSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/users/($userSlug)/avatar.png")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user avatar
#
# POST /api/latest/users/{userSlug}/avatar.png
# operationId: uploadAvatar_1
export def "latest-users-avatarpng uploadAvatar-by-userSlug" [
  userSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Atlassian-Token: string # This resource has Cross-Site Request Forgery (XSRF) protection. To allow the request to pass the XSRF check the caller needs to send an <code>X-Atlassian-Token</code> HTTP header with the value <code>no-check</code>. (e.g. no-check)
  --avatar: string # The avatar file to upload. (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/users/($userSlug)/avatar.png")
  let body = {avatar: $avatar} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Atlassian-Token": $X_Atlassian_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get user settings
#
# GET /api/latest/users/{userSlug}/settings
# operationId: getUserSettings
export def "latest-users-settings get" [
  userSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/users/($userSlug)/settings")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user settings
#
# POST /api/latest/users/{userSlug}/settings
# operationId: updateSettings
export def "latest-users-settings updateSettings" [
  userSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --boolean key: oneof<nothing, bool> # e.g. true
  --long key: float # e.g. 10
  --string key: string # e.g. string value
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/latest/users/($userSlug)/settings")
  let body = {boolean key: $boolean key, long key: $long key, string key: $string key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
