# Auto-generated client for AppVeyor REST API v1.0.0
# Source: https://api.apis.guru/v2/specs/appveyor.com/1.0.0/swagger.json
# Auth: --token flag or $env.APPVEYOR_REST_API_TOKEN

const BASE_URL = "https://ci.appveyor.com/api"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o APPVEYOR_REST_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://ci.appveyor.com/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def provider-completer [] { ["Agent" "AzureBlob" "AzureCS" "AzureWebJob" "BinTray" "FTP" "GitHub" "NuGet" "S3" "SqlDatabase" "WebDeploy" "Webhook"] }
def repositoryAuthentication-completer [] { ["credentials" "ssh"] }
def repositoryProvider-completer [] { ["bitBucket" "git" "gitHub" "gitLab" "kiln" "mercurial" "stash" "subversion" "vso"] }
def accept-completer-1 [] { ["image/png" "image/svg+xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-encrypt encryptValue" } } | get name | first)
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

# Encrypt a value for use in StoredValue.
#
# POST /account/encrypt
# operationId: encryptValue
export def "account-encrypt encryptValue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --plainValue: string # default: 
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/encrypt")
  let body = {plainValue: $plainValue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get build artifacts
#
# GET /buildjobs/{jobId}/artifacts
# Docs: https://www.appveyor.com/docs/api/samples/download-artifacts-advanced-ps/
# operationId: getBuildArtifacts
export def "buildjobs-artifacts list" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<created: string, fileName: string, name: string, size: int, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buildjobs/($jobId)/artifacts")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download build artifact
#
# GET /buildjobs/{jobId}/artifacts/{artifactFileName}
# Docs: https://www.appveyor.com/docs/api/samples/download-artifacts-advanced-ps/
# operationId: getBuildArtifact
export def "buildjobs-artifacts get" [
  jobId: string
  artifactFileName: string
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
  let full_url = (build-url $base $"/buildjobs/($jobId)/artifacts/($artifactFileName)")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download build log
#
# GET /buildjobs/{jobId}/log
# Docs: https://www.appveyor.com/docs/api/projects-builds/#download-build-log
# operationId: getBuildLog
export def "buildjobs-log get" [
  jobId: string
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
  let full_url = (build-url $base $"/buildjobs/($jobId)/log")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start build of branch most recent commit
#
# POST /builds
# Docs: https://www.appveyor.com/docs/api/projects-builds/#start-build-of-branch-most-recent-commit
# operationId: startBuild
export def "builds startBuild" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  accountName: string
  --branch: string
  --commitId: string
  --environmentVariables: record
  projectSlug: string
  --pullRequestId: int # Can not be used with `branch` or `commitId`
]: any -> record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: table<allowFailure: bool, artifactsCount: int, compilationErrorsCount: int, compilationMessagesCount: int, compilationWarningsCount: int, failedTestsCount: int, messagesCount: int, osType: string, passedTestsCount: int, testsCount: int>, messageExtended: string, messages: table<category: string, created: string, message: string>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/builds")
  let body = {accountName: $accountName, branch: $branch, commitId: $commitId, environmentVariables: $environmentVariables, projectSlug: $projectSlug, pullRequestId: $pullRequestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Re-run build
#
# PUT /builds
# Docs: https://www.appveyor.com/docs/api/projects-builds/#re-run-build
# operationId: reRunBuild
export def "builds reRunBuild" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  buildId: int
  --reRunIncomplete: oneof<nothing, bool> # Set `reRunIncomplete` set to `false` (default value) for full build re-run. Set it set to `true` to rerun only failed or cancelled jobs in multijob build.
]: any -> record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: table<allowFailure: bool, artifactsCount: int, compilationErrorsCount: int, compilationMessagesCount: int, compilationWarningsCount: int, failedTestsCount: int, messagesCount: int, osType: string, passedTestsCount: int, testsCount: int>, messageExtended: string, messages: table<category: string, created: string, message: string>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/builds")
  let body = {buildId: $buildId, reRunIncomplete: $reRunIncomplete} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel build
#
# DELETE /builds/{accountName}/{projectSlug}/{buildVersion}
# Docs: https://www.appveyor.com/docs/api/projects-builds/#cancel-build
# operationId: cancelBuild
export def "builds cancelBuild" [
  accountName: string
  projectSlug: string
  buildVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/builds/($accountName)/($projectSlug)/($buildVersion)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get collaborators
#
# GET /collaborators
# Docs: https://www.appveyor.com/docs/api/team/#get-collaborators
# operationId: getCollaborators
export def "collaborators list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<created: string, updated: string, accountId: int, accountName: string, email: string, fullName: string, isCollaborator: bool, isOwner: bool, pageSize: int, password: string, roleId: int, roleName: string, twoFactorAuthEnabled: bool, userId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collaborators")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update collaborator
#
# PUT /collaborators
# Docs: https://www.appveyor.com/docs/api/team/#update-collaborator
# operationId: updateCollaborator
export def "collaborators updateCollaborator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  roleId: int
  userId: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collaborators")
  let body = {roleId: $roleId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete collaborator
#
# DELETE /collaborators/{userId}
# Docs: https://www.appveyor.com/docs/api/team/#delete-collaborator
# operationId: deleteCollaborator
export def "collaborators delete" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collaborators/($userId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get collaborator
#
# GET /collaborators/{userId}
# Docs: https://www.appveyor.com/docs/api/team/#get-collaborator
# operationId: getCollaborator
export def "collaborators get" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<roles: table<created: string, updated: string, isSystem: bool, name: string, roleId: int>, user: record<created: string, updated: string, accountId: int, accountName: string, email: string, fullName: string, isCollaborator: bool, isOwner: bool, pageSize: int, password: string, roleId: int, roleName: string, twoFactorAuthEnabled: bool, userId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collaborators/($userId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start deployment
#
# POST /deployments
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#start-deployment
# operationId: startDeployment
export def "deployments startDeployment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  accountName: string
  --buildJobId: string # Optional job id with artifacts if build contains multiple jobs.
  buildVersion: string # Build to deploy
  environmentName: string
  --environmentVariables: record
  projectSlug: string
]: any -> record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list<record>, messageExtended: string, messages: list<record>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, deploymentId: int, finished: string, started: string, status: string, created: string, updated: string, environment: record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, tags: string>, jobs: table<messagesCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployments")
  let body = {accountName: $accountName, buildJobId: $buildJobId, buildVersion: $buildVersion, environmentName: $environmentName, environmentVariables: $environmentVariables, projectSlug: $projectSlug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel deployment
#
# PUT /deployments/stop
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#cancel-deployment
# operationId: cancelDeployment
export def "deployments-stop cancelDeployment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  deploymentId: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployments/stop")
  let body = {deploymentId: $deploymentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get deployment
#
# GET /deployments/{deploymentId}
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#get-deployment
# operationId: getDeployment
export def "deployments get" [
  deploymentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<deployment: record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list, messageExtended: string, messages: list, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, deploymentId: int, finished: string, started: string, status: string, created: string, updated: string, environment: record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record, tags: string>, jobs: list<record>>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deploymentId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get environments
#
# GET /environments
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#get-environments
# operationId: getEnvironments
export def "environments get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<deploymentEnvironmentId: int, name: string, provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/environments")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add environment
#
# POST /environments
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#add-environment
# operationId: addEnvironment
# --settings shape: {environmentVariables?: list, notifications?: list, providerSettings?: list}
export def "environments addEnvironment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string
  provider: string@provider-completer
  settings: record # shape: {environmentVariables?: list, notifications?: list, providerSettings?: list}
]: any -> record<environmentAccessKey: string, projects: table<isSelected: bool, name: string, projectId: int>, selectedProjects: list<int>, settings: record<environmentVariables: list<record>, notifications: list<record>, providerSettings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/environments")
  let body = {name: $name, provider: $provider, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update environment
#
# PUT /environments
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#update-environment
# operationId: updateEnvironment
# --projects item shape: {isSelected: bool, name: string, projectId: int}
# --settings shape: {environmentVariables?: list, notifications?: list, providerSettings?: list}
export def "environments updateEnvironment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --environmentAccessKey: string
  --projects: list # Projects available for selection in UI. Only present in response from getEnvironmentSettings. — item shape: {isSelected: bool, name: string, projectId: int}
  --selectedProjects: list # Project IDs of selected projects
  --settings: record # shape: {environmentVariables?: list, notifications?: list, providerSettings?: list}
]: any -> record<environmentAccessKey: string, projects: table<isSelected: bool, name: string, projectId: int>, selectedProjects: list<int>, settings: record<environmentVariables: list<record>, notifications: list<record>, providerSettings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/environments")
  let body = {environmentAccessKey: $environmentAccessKey, projects: $projects, selectedProjects: $selectedProjects, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete environment
#
# DELETE /environments/{deploymentEnvironmentId}
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#delete-environment
# operationId: deleteEnvironment
export def "environments delete" [
  deploymentEnvironmentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($deploymentEnvironmentId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get environment deployments
#
# GET /environments/{deploymentEnvironmentId}/deployments
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#get-environment-deployments
# operationId: getEnvironmentDeployments
export def "environments-deployments get" [
  deploymentEnvironmentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<deployments: table<build: record, deploymentId: int, finished: string, started: string, status: string, project: record>, environment: record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, tags: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($deploymentEnvironmentId)/deployments")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get environment settings
#
# GET /environments/{deploymentEnvironmentId}/settings
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#get-environment-settings
# operationId: getEnvironmentSettings
export def "environments-settings get" [
  deploymentEnvironmentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<environment: record<environmentAccessKey: string, projects: list<record>, selectedProjects: list<int>, settings: record<environmentVariables: list, notifications: list, providerSettings: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($deploymentEnvironmentId)/settings")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get projects
#
# GET /projects
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-projects
# operationId: getProjects
export def "projects get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add project
#
# POST /projects
# Docs: https://www.appveyor.com/docs/api/projects-builds/#add-project
# operationId: addProject
export def "projects addProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --repositoryAuthentication: string@repositoryAuthentication-completer
  repositoryName: string # URL when repositoryProvider is git, mercurial, subversion username/project when repositoryProvider is gitHub
  --repositoryPassword: string # Required if repositoryAuthentication is credentials (format: password)
  repositoryProvider: string@repositoryProvider-completer
  --repositoryUsername: string # Required if repositoryAuthentication is credentials
]: any -> record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: table<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list, messageExtended: string, messages: list, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list<record>, roleAces: list<record>>, skipBranchesWithoutAppveyorYml: bool, tags: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let body = {repositoryAuthentication: $repositoryAuthentication, repositoryName: $repositoryName, repositoryPassword: $repositoryPassword, repositoryProvider: $repositoryProvider, repositoryUsername: $repositoryUsername} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update project
#
# PUT /projects
# Docs: https://www.appveyor.com/docs/api/projects-builds/#update-project
# operationId: updateProject
# --configuration shape: {afterBuildScripts?: list, afterDeployScripts?: list, afterTestScripts?: list, artifacts?: list, assemblyFileVersionFormat?: string, assemblyInfoFile?: string, assemblyInformationalVersionFormat?: string, assemblyVersionFormat?: string, beforeBuildScripts?: list, beforeDeployScripts?: list, beforePackageScripts?: list, beforeTestScripts?: list, branchesMode?: "exclude"|"include", buildCloud?: list, buildMode?: "msbuild"|"none"|"script", buildScripts?: list, cacheEntries?: list, cloneDepth?: int, cloneFolder?: string, cloneScripts?: list, configuration?: list, configureNuGetAccountSource?: bool, configureNuGetProjectSource?: bool, deployMode?: "providers"|"none"|"script", deployScripts?: list, deployments?: list, disableNuGetPublishForOctopusPackages?: bool, disableNuGetPublishOnPullRequests?: bool, doNotIncrementBuildNumberOnPullRequests?: bool, dotnetCsprojAssemblyVersionFormat?: string, dotnetCsprojFile?: string, dotnetCsprojFileVersionFormat?: string, dotnetCsprojInformationalVersionFormat?: string, dotnetCsprojPackageVersionFormat?: string, dotnetCsprojVersionFormat?: string, environmentVariables?: list, environmentVariablesMatrix?: list, excludeBranches?: list, forceHttpsClone?: bool, hostsEntries?: list, hotFixScripts?: list, includeBranches?: list, includeNuGetReferences?: bool, initScripts?: list, installScripts?: list, matrixAllowFailures?: list, matrixExcept?: list, matrixExclude?: list, matrixFastFinish?: bool, matrixOnly?: list, maxJobs?: int, msBuildInParallel?: bool, msBuildProjectFileName?: string, msBuildVerbosity?: "quiet"|"minimal"|"normal"|"detailed", notifications?: list, onBuildErrorScripts?: list, onBuildFinishScripts?: list, onBuildSuccessScripts?: list, onlyCommitsFiles?: list, operatingSystem?: list, packageAspNetCoreProjects?: bool, packageAzureCloudServiceProjects?: bool, packageDotnetConsoleProjects?: bool, packageNuGetProjects?: bool, packageNuGetSymbols?: bool, packageWebApplicationProjects?: bool, packageWebApplicationProjectsBeanstalk?: bool, packageWebApplicationProjectsOctopus?: bool, packageWebApplicationProjectsXCopy?: bool, patchAssemblyInfo?: bool, patchDotnetCsproj?: bool, platform?: list, services?: list, shallowClone?: bool, skipBranchWithPullRequests?: bool, skipCommitsFiles?: list, skipNonTags?: bool, skipTags?: bool, stacks?: list, testAssemblies?: list, testCategories?: list, testCategoriesMatrix?: list, testCategoriesMode?: "exclude"|"include", testMode?: "auto"|"none"|"script", testScripts?: list, xamarinRegisterAndroidProduct?: bool, xamarinRegisterIosProduct?: bool}
export def "projects updateProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --buildPriority: int
  configuration: record # shape: {afterBuildScripts?: list, afterDeployScripts?: list, afterTestScripts?: list, artifacts?: list, assemblyFileVersionFormat?: string, assemblyInfoFile?: string, assemblyInformationalVersionFormat?: string, assemblyVersionFormat?: string, beforeBuildScripts?: list, beforeDeployScripts?: list, beforePackageScripts?: list, beforeTestScripts?: list, branchesMode?: "exclude"|"include", buildCloud?: list, buildMode?: "msbuild"|"none"|"script", buildScripts?: list, cacheEntries?: list, cloneDepth?: int, cloneFolder?: string, cloneScripts?: list, configuration?: list, configureNuGetAccountSource?: bool, configureNuGetProjectSource?: bool, deployMode?: "providers"|"none"|"script", deployScripts?: list, deployments?: list, disableNuGetPublishForOctopusPackages?: bool, disableNuGetPublishOnPullRequests?: bool, doNotIncrementBuildNumberOnPullRequests?: bool, dotnetCsprojAssemblyVersionFormat?: string, dotnetCsprojFile?: string, dotnetCsprojFileVersionFormat?: string, dotnetCsprojInformationalVersionFormat?: string, dotnetCsprojPackageVersionFormat?: string, dotnetCsprojVersionFormat?: string, environmentVariables?: list, environmentVariablesMatrix?: list, excludeBranches?: list, forceHttpsClone?: bool, hostsEntries?: list, hotFixScripts?: list, includeBranches?: list, includeNuGetReferences?: bool, initScripts?: list, installScripts?: list, matrixAllowFailures?: list, matrixExcept?: list, matrixExclude?: list, matrixFastFinish?: bool, matrixOnly?: list, maxJobs?: int, msBuildInParallel?: bool, msBuildProjectFileName?: string, msBuildVerbosity?: "quiet"|"minimal"|"normal"|"detailed", notifications?: list, onBuildErrorScripts?: list, onBuildFinishScripts?: list, onBuildSuccessScripts?: list, onlyCommitsFiles?: list, operatingSystem?: list, packageAspNetCoreProjects?: bool, packageAzureCloudServiceProjects?: bool, packageDotnetConsoleProjects?: bool, packageNuGetProjects?: bool, packageNuGetSymbols?: bool, packageWebApplicationProjects?: bool, packageWebApplicationProjectsBeanstalk?: bool, packageWebApplicationProjectsOctopus?: bool, packageWebApplicationProjectsXCopy?: bool, patchAssemblyInfo?: bool, patchDotnetCsproj?: bool, platform?: list, services?: list, shallowClone?: bool, skipBranchWithPullRequests?: bool, skipCommitsFiles?: list, skipNonTags?: bool, skipTags?: bool, stacks?: list, testAssemblies?: list, testCategories?: list, testCategoriesMatrix?: list, testCategoriesMode?: "exclude"|"include", testMode?: "auto"|"none"|"script", testScripts?: list, xamarinRegisterAndroidProduct?: bool, xamarinRegisterIosProduct?: bool}
  --customYmlName: string
  --ignoreAppveyorYml: oneof<nothing, bool>
  --nextBuildNumber: int
  --repositoryAuthentication: string@repositoryAuthentication-completer
  --repositoryUsername: string
  --scheduleCrontabExpression: string # Build schedule as an NCrontab Expression.  See https://github.com/atifaziz/NCrontab/wiki/Crontab-Expression
  --sshPublicKey: string
  --statusBadgeId: string
  versionFormat: string
  --webhookId: string
  --webhookUrl: string # format: uri
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let body = {buildPriority: $buildPriority, configuration: $configuration, customYmlName: $customYmlName, ignoreAppveyorYml: $ignoreAppveyorYml, nextBuildNumber: $nextBuildNumber, repositoryAuthentication: $repositoryAuthentication, repositoryUsername: $repositoryUsername, scheduleCrontabExpression: $scheduleCrontabExpression, sshPublicKey: $sshPublicKey, statusBadgeId: $statusBadgeId, versionFormat: $versionFormat, webhookId: $webhookId, webhookUrl: $webhookUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get status badge image for a project with a public repository
#
# GET /projects/status/{badgeRepoProvider}/{repoAccountName}/{repoSlug}
# Docs: https://www.appveyor.com/docs/status-badges/
# operationId: getPublicProjectStatusBadge
export def "projects-status get-by-badgeRepoProvider-repoAccountName-repoSlug" [
  badgeRepoProvider: any
  repoAccountName: any
  repoSlug: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --branch: string # Repository Branch
  --svg: oneof<nothing, bool> # Return an SVG image instead of PNG?  Exclusive with `retina`. (default: false)
  --retina: oneof<nothing, bool> # Return a larger image suitable for retina displays?  Exclusive with `svg`. (default: false)
  --passingText: string # Text to show in badge when build is passing.
  --failingText: string # Text to show in badge when build is failing.
  --pendingText: string # Text to show in badge when build is pending.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "svg" $svg "scalar") (serialize-qp "retina" $retina "scalar") (serialize-qp "passingText" $passingText "scalar") (serialize-qp "failingText" $failingText "scalar") (serialize-qp "pendingText" $pendingText "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/status/($badgeRepoProvider)/($repoAccountName)/($repoSlug)" $qp)
  let accept_val = ($accept | default "image/svg+xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project status badge image
#
# GET /projects/status/{statusBadgeId}
# Docs: https://www.appveyor.com/docs/status-badges/
# operationId: getProjectStatusBadge
export def "projects-status get-by-statusBadgeId" [
  statusBadgeId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --svg: oneof<nothing, bool> # Return an SVG image instead of PNG?  Exclusive with `retina`. (default: false)
  --retina: oneof<nothing, bool> # Return a larger image suitable for retina displays?  Exclusive with `svg`. (default: false)
  --passingText: string # Text to show in badge when build is passing.
  --failingText: string # Text to show in badge when build is failing.
  --pendingText: string # Text to show in badge when build is pending.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "svg" $svg "scalar") (serialize-qp "retina" $retina "scalar") (serialize-qp "passingText" $passingText "scalar") (serialize-qp "failingText" $failingText "scalar") (serialize-qp "pendingText" $pendingText "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/status/($statusBadgeId)" $qp)
  let accept_val = ($accept | default "image/svg+xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project branch status badge image
#
# GET /projects/status/{statusBadgeId}/branch/{buildBranch}
# Docs: https://www.appveyor.com/docs/status-badges/
# operationId: getProjectBranchStatusBadge
export def "projects-status-branch get" [
  statusBadgeId: any
  buildBranch: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --svg: oneof<nothing, bool> # Return an SVG image instead of PNG?  Exclusive with `retina`. (default: false)
  --retina: oneof<nothing, bool> # Return a larger image suitable for retina displays?  Exclusive with `svg`. (default: false)
  --passingText: string # Text to show in badge when build is passing.
  --failingText: string # Text to show in badge when build is failing.
  --pendingText: string # Text to show in badge when build is pending.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "svg" $svg "scalar") (serialize-qp "retina" $retina "scalar") (serialize-qp "passingText" $passingText "scalar") (serialize-qp "failingText" $failingText "scalar") (serialize-qp "pendingText" $pendingText "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/status/($statusBadgeId)/branch/($buildBranch)" $qp)
  let accept_val = ($accept | default "image/svg+xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete project
#
# DELETE /projects/{accountName}/{projectSlug}
# Docs: https://www.appveyor.com/docs/api/projects-builds/#delete-project
# operationId: deleteProject
export def "projects delete" [
  accountName: string
  projectSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($accountName)/($projectSlug)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project last build
#
# GET /projects/{accountName}/{projectSlug}
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-last-build
# operationId: getProjectLastBuild
export def "projects get-by-accountName-projectSlug" [
  accountName: string
  projectSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list<record>, messageExtended: string, messages: list<record>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($accountName)/($projectSlug)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get last successful build artifact
#
# GET /projects/{accountName}/{projectSlug}/artifacts/{artifactFileName}
# Docs: https://www.appveyor.com/docs/packaging-artifacts/#permalink-to-the-last-successful-build-artifact
# operationId: getProjectArtifact
export def "projects-artifacts get" [
  accountName: string
  projectSlug: string
  artifactFileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # Repository Branch
  --tag: string # A git (or other VCS) tag
  --job: string # Name of the build job.
  --all: oneof<nothing, bool> # Include not only `successful`, but also jobs with `failed`, and `cancelled` status. (default: false)
  --pr: oneof<nothing, bool> # Include PR builds in the search results? `true` - take artifact from PR builds only; `false` - do not look for artifact in PR builds; default/unspecified - look for artifact in both PR an non-PR builds.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "job" $job "scalar") (serialize-qp "all" $all "scalar") (serialize-qp "pr" $pr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($accountName)/($projectSlug)/artifacts/($artifactFileName)" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project last branch build
#
# GET /projects/{accountName}/{projectSlug}/branch/{buildBranch}
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-last-branch-build
# operationId: getProjectLastBuildBranch
export def "projects-branch get" [
  accountName: string
  projectSlug: string
  buildBranch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list<record>, messageExtended: string, messages: list<record>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($accountName)/($projectSlug)/branch/($buildBranch)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project build by version
#
# GET /projects/{accountName}/{projectSlug}/build/{buildVersion}
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-build-by-version
# operationId: getProjectBuildByVersion
export def "projects-build get" [
  accountName: string
  projectSlug: string
  buildVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list<record>, messageExtended: string, messages: list<record>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($accountName)/($projectSlug)/build/($buildVersion)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete project build cache
#
# DELETE /projects/{accountName}/{projectSlug}/buildcache
# Docs: https://www.appveyor.com/docs/api/projects-builds/#delete-project-build-cache
# operationId: deleteProjectBuildCache
export def "projects-buildcache delete" [
  accountName: string
  projectSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($accountName)/($projectSlug)/buildcache")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project deployments
#
# GET /projects/{accountName}/{projectSlug}/deployments
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-deployments
# operationId: getProjectDeployments
export def "projects-deployments get" [
  accountName: string
  projectSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --recordsNumber: int # Number of results to include in the response. getProjectDeployments is documented to have a maximum of 20. It currently returns 500 Internal Server Error for recordsNumber <= 5. In the past it has returned 500 Internal Server Error for many different values which did not match the value used by the ci.appveyor.com web interface at the time.  As of 2018-09-08, the value used by the web interface is 10.
]: nothing -> record<deployments: table<build: record, deploymentId: int, finished: string, started: string, status: string, environment: record>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recordsNumber" $recordsNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($accountName)/($projectSlug)/deployments" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project history
#
# GET /projects/{accountName}/{projectSlug}/history
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-history
# operationId: getProjectHistory
export def "projects-history get" [
  accountName: any
  projectSlug: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --recordsNumber: int # Number of results to include in the response. getProjectDeployments is documented to have a maximum of 20. It currently returns 500 Internal Server Error for recordsNumber <= 5. In the past it has returned 500 Internal Server Error for many different values which did not match the value used by the ci.appveyor.com web interface at the time.  As of 2018-09-08, the value used by the web interface is 10.
  --startBuildId: int # Maximum `buildId` to include in the results (exclusive).
  --branch: string # Repository Branch
]: nothing -> record<builds: table<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list, messageExtended: string, messages: list, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recordsNumber" $recordsNumber "scalar") (serialize-qp "startBuildId" $startBuildId "scalar") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($accountName)/($projectSlug)/history" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project settings
#
# GET /projects/{accountName}/{projectSlug}/settings
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-settings
# operationId: getProjectSettings
export def "projects-settings get" [
  accountName: string
  projectSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<buildClouds: table<value: string>, defaultImageName: string, images: table<buildCloudName: string, buildWorkerImageId: int, name: string, osType: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>, settings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($accountName)/($projectSlug)/settings")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update project build number
#
# PUT /projects/{accountName}/{projectSlug}/settings/build-number
# Docs: https://www.appveyor.com/docs/api/projects-builds/#update-project-build-number
# operationId: updateProjectBuildNumber
export def "projects-settings-build-number updateProjectBuildNumber" [
  accountName: string
  projectSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  nextBuildNumber: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($accountName)/($projectSlug)/settings/build-number")
  let body = {nextBuildNumber: $nextBuildNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get project environment variables
#
# GET /projects/{accountName}/{projectSlug}/settings/environment-variables
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-environment-variables
# operationId: getProjectEnvironmentVariables
export def "projects-settings-environment-variables get" [
  accountName: string
  projectSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<name: string, value: record<isEncrypted: bool, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($accountName)/($projectSlug)/settings/environment-variables")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update project environment variables
#
# PUT /projects/{accountName}/{projectSlug}/settings/environment-variables
# Docs: https://www.appveyor.com/docs/api/projects-builds/#update-project-environment-variables
# operationId: updateProjectEnvironmentVariables
export def "projects-settings-environment-variables updateProjectEnvironmentVariables" [
  accountName: string
  projectSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($accountName)/($projectSlug)/settings/environment-variables")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get project settings in YAML
#
# GET /projects/{accountName}/{projectSlug}/settings/yaml
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-settings-in-yaml
# operationId: getProjectSettingsYaml
export def "projects-settings-yaml get" [
  accountName: string
  projectSlug: string
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
  let full_url = (build-url $base $"/projects/($accountName)/($projectSlug)/settings/yaml")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update project settings in YAML
#
# PUT /projects/{accountName}/{projectSlug}/settings/yaml
# Docs: https://www.appveyor.com/docs/api/projects-builds/#update-project-settings-in-yaml
# operationId: updateProjectSettingsYaml
export def "projects-settings-yaml updateProjectSettingsYaml" [
  accountName: string
  projectSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($accountName)/($projectSlug)/settings/yaml")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get roles
#
# GET /roles
# Docs: https://www.appveyor.com/docs/api/team/#get-roles
# operationId: getRoles
export def "roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<created: string, updated: string, isSystem: bool, name: string, roleId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add role
#
# POST /roles
# Docs: https://www.appveyor.com/docs/api/team/#add-role
# operationId: addRole
export def "roles addRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string
]: any -> record<groups: table<name: string, permissions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update role
#
# PUT /roles
# Docs: https://www.appveyor.com/docs/api/team/#update-role
# operationId: updateRole
# --groups item shape: {name: "Account"|"BuildEnvironment"|"Deny"|"Environments"|"Projects"|"Roles"|"User"|"Users", permissions: list}
export def "roles updateRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --groups: list # item shape: {name: "Account"|"BuildEnvironment"|"Deny"|"Environments"|"Projects"|"Roles"|"User"|"Users", permissions: list}
]: any -> record<groups: table<name: string, permissions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles")
  let body = {groups: $groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete role
#
# DELETE /roles/{roleId}
# Docs: https://www.appveyor.com/docs/api/team/#delete-role
# operationId: deleteRole
export def "roles delete" [
  roleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/roles/($roleId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get role
#
# GET /roles/{roleId}
# Docs: https://www.appveyor.com/docs/api/team/#get-role
# operationId: getRole
export def "roles get" [
  roleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<groups: table<name: string, permissions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/roles/($roleId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Join Account
#
# PUT /user/join-account
# operationId: joinAccount
export def "user-join-account joinAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  invitationId: string
]: any -> record<accounts: table<created: string, updated: string, accountId: int, allowCustomBuildEnvironment: bool, blocked: bool, featureFlags: string, gitHubPlan: bool, gitHubPlanOrg: string, isCollaborator: bool, isEnterprisePlan: bool, isOwner: bool, manualPayments: bool, name: string, permissions: list, planEnd: string, planId: string, planStart: string, planStatus: string, roleId: int, roleName: string, timeZoneId: string, unpaid: bool, unverified: bool>, setupRequired: bool, twoFactorAuthRequired: bool, user: record<created: string, updated: string, bitBucketUsername: string, email: string, fullName: string, gitHubUsername: string, gitLabUserId: string, gravatarHash: string, pageSize: int, twoFactorAuthEnabled: bool, userId: int, vsoUsername: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/join-account")
  let body = {invitationId: $invitationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get users
#
# GET /users
# Docs: https://www.appveyor.com/docs/api/team/#get-users
# operationId: getUsers
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<created: string, updated: string, accountId: int, accountName: string, email: string, fullName: string, isCollaborator: bool, isOwner: bool, pageSize: int, password: string, roleId: int, roleName: string, twoFactorAuthEnabled: bool, userId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user
#
# PUT /users
# Docs: https://www.appveyor.com/docs/api/team/#update-user
# operationId: updateUser
export def "users updateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  email: string # format: email
  fullName: string
  --password: string # format: password
  --roleId: int
  --twoFactorAuthEnabled: oneof<nothing, bool>
  --userId: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let body = {email: $email, fullName: $fullName, password: $password, roleId: $roleId, twoFactorAuthEnabled: $twoFactorAuthEnabled, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get user invitations
#
# GET /users/invitations
# operationId: getUserInvitations
export def "users-invitations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<accountId: int, accountName: string, created: string, email: string, roleId: int, roleName: string, userInvitationId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/invitations")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invite user
#
# POST /users/invitations
# operationId: inviteUser
export def "users-invitations inviteUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  email: string # format: email
  roleId: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/invitations")
  let body = {email: $email, roleId: $roleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel user invitation
#
# DELETE /users/invitations/{userInvitationId}
# operationId: cancelUserInvitation
export def "users-invitations cancelUserInvitation" [
  userInvitationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/invitations/($userInvitationId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete user
#
# DELETE /users/{userId}
# Docs: https://www.appveyor.com/docs/api/team/#delete-user
# operationId: deleteUser
export def "users delete" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user
#
# GET /users/{userId}
# Docs: https://www.appveyor.com/docs/api/team/#get-user
# operationId: getUser
export def "users get" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<roles: table<created: string, updated: string, isSystem: bool, name: string, roleId: int>, user: record<created: string, updated: string, accountId: int, accountName: string, email: string, fullName: string, isCollaborator: bool, isOwner: bool, pageSize: int, password: string, roleId: int, roleName: string, twoFactorAuthEnabled: bool, userId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
