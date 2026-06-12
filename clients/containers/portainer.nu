# Auto-generated client for PortainerCE API v2.20.0
# Source: https://app.swaggerhub.com/apiproxy/registry/portainer/portainer-ce/2.20.0
# Auth: --token flag or $env.PORTAINERCE_API_TOKEN

const BASE_URL = "http://localhost/api"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PORTAINERCE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-API-KEY: $token_val}, query: ""} }
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

def base-url-completer [] { ["http://localhost/api" "https://localhost/api"] }
def auth-scheme-completer [] { ["x-api-key" "bearer"] }

# Completers for enum parameters
def method-completer [] { ["file" "repository" "string"] }
def platform-completer [] { ["1" "2"] }
def type-completer [] { ["1" "2" "3"] }
def Platform-completer [] { ["1" "2"] }
def Type-completer [] { ["1" "2" "3"] }
def type-completer-1 [] { ["1" "2"] }
def method-completer-1 [] { ["file" "string"] }
def deploymentType-completer [] { ["0" "1" "2"] }
def type-completer-2 [] { ["1" "2" "3" "4" "5" "6" "7"] }
def type-completer-3 [] { ["1" "2" "3" "4" "5" "6" "7" "8" "9"] }
def method-completer-2 [] { ["file" "repository" "string" "url"] }
def role-completer [] { ["1" "2"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "auth AuthenticateUser" } } | get name | first)
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

# Authenticate
#
# POST /auth
# operationId: AuthenticateUser
export def "auth AuthenticateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  password: string # Password (e.g. mypassword)
  username: string # Username (e.g. admin)
]: any -> record<jwt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth")
  let body = {password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Logout
#
# POST /auth/logout
# operationId: Logout
export def "auth-logout Logout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Authenticate with OAuth
#
# POST /auth/oauth/validate
# operationId: ValidateOAuth
export def "auth-oauth-validate ValidateOAuth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # OAuth code returned from OAuth Provided
]: any -> record<jwt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/oauth/validate")
  let body = {code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an archive with a system data snapshot that could be used to restore the system.
#
# POST /backup
# operationId: Backup
export def "backup Backup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/backup")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List available custom templates
#
# GET /custom_templates
# operationId: CustomTemplateList
export def "custom-templates CustomTemplateList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: list # Template types
  --edge: oneof<nothing, bool> # Filter by edge templates
]: nothing -> table<CreatedByUserId: int, Description: string, EntryPoint: string, GitConfig: record<authentication: record, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, Id: int, Logo: string, Note: string, Platform: int, ProjectPath: string, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list, System: bool, TeamAccesses: list, Type: int, UserAccesses: list>, Title: string, Type: int, edgeTemplate: bool, isComposeFormat: bool, variables: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "csv") (serialize-qp "edge" $edge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a custom template
#
# POST /custom_templates
# DEPRECATED
# operationId: CustomTemplateCreate
@deprecated
export def "custom-templates CustomTemplateCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --method: string@method-completer # method for creating template
  --body: record
]: any -> record<CreatedByUserId: int, Description: string, EntryPoint: string, GitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, Id: int, Logo: string, Note: string, Platform: int, ProjectPath: string, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Title: string, Type: int, edgeTemplate: bool, isComposeFormat: bool, variables: table<defaultValue: string, description: string, label: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "method" $method "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_templates" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a template
#
# DELETE /custom_templates/{id}
# operationId: CustomTemplateDelete
export def "custom-templates CustomTemplateDelete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect a custom template
#
# GET /custom_templates/{id}
# operationId: CustomTemplateInspect
export def "custom-templates CustomTemplateInspect" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<CreatedByUserId: int, Description: string, EntryPoint: string, GitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, Id: int, Logo: string, Note: string, Platform: int, ProjectPath: string, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Title: string, Type: int, edgeTemplate: bool, isComposeFormat: bool, variables: table<defaultValue: string, description: string, label: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a template
#
# PUT /custom_templates/{id}
# operationId: CustomTemplateUpdate
# --variables item shape: {defaultValue?: string, description?: string, label?: string, name?: string}
export def "custom-templates CustomTemplateUpdate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --composeFilePathInRepository: string # Path to the Stack file inside the Git repository (default: docker-compose.yml, e.g. docker-compose.yml)
  description: string # Description of the template (e.g. High performance web server)
  --edgeTemplate: oneof<nothing, bool> # EdgeTemplate indicates if this template purpose for Edge Stack (e.g. false)
  fileContent: string # Content of stack file
  --isComposeFormat: oneof<nothing, bool> # IsComposeFormat indicates if the Kubernetes template is created from a Docker Compose file (e.g. false)
  --logo: string # URL of the template's logo (e.g. https://portainer.io/img/logo.svg)
  --note: string # A note that will be displayed in the UI. Supports HTML content (e.g. This is my <b>custom</b> template)
  --platform: int@platform-completer # Platform associated to the template. Valid values are: 1 - 'linux', 2 - 'windows' Required for Docker stacks (e.g. 1)
  --repositoryAuthentication: oneof<nothing, bool> # Use basic authentication to clone the Git repository (e.g. true)
  --repositoryGitCredentialID: int # GitCredentialID used to identify the bound git credential. Required when RepositoryAuthentication is true and RepositoryUsername/RepositoryPassword are not provided (e.g. 0)
  --repositoryPassword: string # Password used in basic authentication. Required when RepositoryAuthentication is true and RepositoryGitCredentialID is 0 (e.g. myGitPassword)
  --repositoryReferenceName: string # Reference name of a Git repository hosting the Stack file (e.g. refs/heads/master)
  repositoryURL: string # URL of a Git repository hosting the Stack file (e.g. https://github.com/openfaas/faas)
  --repositoryUsername: string # Username used in basic authentication. Required when RepositoryAuthentication is true and RepositoryGitCredentialID is 0 (e.g. myGitUsername)
  title: string # Title of the template (e.g. Nginx)
  --tlsskipVerify: oneof<nothing, bool> # TLSSkipVerify skips SSL verification when cloning the Git repository (e.g. false)
  type: int@type-completer # Type of created stack (1 - swarm, 2 - compose, 3 - kubernetes) (e.g. 1)
  --body-variables: list # Definitions of variables in the stack file — item shape: {defaultValue?: string, description?: string, label?: string, name?: string}
]: any -> record<CreatedByUserId: int, Description: string, EntryPoint: string, GitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, Id: int, Logo: string, Note: string, Platform: int, ProjectPath: string, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Title: string, Type: int, edgeTemplate: bool, isComposeFormat: bool, variables: table<defaultValue: string, description: string, label: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_templates/($id)")
  let body = {composeFilePathInRepository: $composeFilePathInRepository, description: $description, edgeTemplate: $edgeTemplate, fileContent: $fileContent, isComposeFormat: $isComposeFormat, logo: $logo, note: $note, platform: $platform, repositoryAuthentication: $repositoryAuthentication, repositoryGitCredentialID: $repositoryGitCredentialID, repositoryPassword: $repositoryPassword, repositoryReferenceName: $repositoryReferenceName, repositoryURL: $repositoryURL, repositoryUsername: $repositoryUsername, title: $title, tlsskipVerify: $tlsskipVerify, type: $type, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Template stack file content.
#
# GET /custom_templates/{id}/file
# operationId: CustomTemplateFile
export def "custom-templates-file CustomTemplateFile" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fileContent: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_templates/($id)/file")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch the latest config file content based on custom template's git repository configuration
#
# PUT /custom_templates/{id}/git_fetch
# operationId: CustomTemplateGitFetch
export def "custom-templates-git-fetch CustomTemplateGitFetch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fileContent: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/custom_templates/($id)/git_fetch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a custom template
#
# POST /custom_templates/create/file
# operationId: CustomTemplateCreateFile
export def "custom-templates-create-file CustomTemplateCreateFile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Title: string # Title of the template
  Description: string # Description of the template
  Note: string # A note that will be displayed in the UI. Supports HTML content
  Platform: int@Platform-completer # Platform associated to the template (1 - 'linux', 2 - 'windows')
  Type: int@Type-completer # Type of created stack (1 - swarm, 2 - compose, 3 - kubernetes)
  File: path # File
  --Logo: string # URL of the template's logo
  --Variables: string # A json array of variables definitions
]: any -> record<CreatedByUserId: int, Description: string, EntryPoint: string, GitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, Id: int, Logo: string, Note: string, Platform: int, ProjectPath: string, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Title: string, Type: int, edgeTemplate: bool, isComposeFormat: bool, variables: table<defaultValue: string, description: string, label: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_templates/create/file")
  let body = {Title: $Title, Description: $Description, Note: $Note, Platform: $Platform, Type: $Type, File: $File, Logo: $Logo, Variables: $Variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($File | is-not-empty) { $body | upsert File (open -r $File) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Create a custom template
#
# POST /custom_templates/create/repository
# operationId: CustomTemplateCreateRepository
# --variables item shape: {defaultValue?: string, description?: string, label?: string, name?: string}
export def "custom-templates-create-repository CustomTemplateCreateRepository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --composeFilePathInRepository: string # Path to the Stack file inside the Git repository (default: docker-compose.yml, e.g. docker-compose.yml)
  description: string # Description of the template (e.g. High performance web server)
  --edgeTemplate: oneof<nothing, bool> # EdgeTemplate indicates if this template purpose for Edge Stack (e.g. false)
  --isComposeFormat: oneof<nothing, bool> # IsComposeFormat indicates if the Kubernetes template is created from a Docker Compose file (e.g. false)
  --logo: string # URL of the template's logo (e.g. https://portainer.io/img/logo.svg)
  --note: string # A note that will be displayed in the UI. Supports HTML content (e.g. This is my <b>custom</b> template)
  --platform: int@platform-completer # Platform associated to the template. Valid values are: 1 - 'linux', 2 - 'windows' Required for Docker stacks (e.g. 1)
  --repositoryAuthentication: oneof<nothing, bool> # Use basic authentication to clone the Git repository (e.g. true)
  --repositoryPassword: string # Password used in basic authentication. Required when RepositoryAuthentication is true. (e.g. myGitPassword)
  --repositoryReferenceName: string # Reference name of a Git repository hosting the Stack file (e.g. refs/heads/master)
  repositoryURL: string # URL of a Git repository hosting the Stack file (e.g. https://github.com/openfaas/faas)
  --repositoryUsername: string # Username used in basic authentication. Required when RepositoryAuthentication is true. (e.g. myGitUsername)
  title: string # Title of the template (e.g. Nginx)
  --tlsskipVerify: oneof<nothing, bool> # TLSSkipVerify skips SSL verification when cloning the Git repository (e.g. false)
  type: int@type-completer-1 # Type of created stack: * 1 - swarm * 2 - compose * 3 - kubernetes (e.g. 1)
  --body-variables: list # Definitions of variables in the stack file — item shape: {defaultValue?: string, description?: string, label?: string, name?: string}
]: any -> record<CreatedByUserId: int, Description: string, EntryPoint: string, GitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, Id: int, Logo: string, Note: string, Platform: int, ProjectPath: string, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Title: string, Type: int, edgeTemplate: bool, isComposeFormat: bool, variables: table<defaultValue: string, description: string, label: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_templates/create/repository")
  let body = {composeFilePathInRepository: $composeFilePathInRepository, description: $description, edgeTemplate: $edgeTemplate, isComposeFormat: $isComposeFormat, logo: $logo, note: $note, platform: $platform, repositoryAuthentication: $repositoryAuthentication, repositoryPassword: $repositoryPassword, repositoryReferenceName: $repositoryReferenceName, repositoryURL: $repositoryURL, repositoryUsername: $repositoryUsername, title: $title, tlsskipVerify: $tlsskipVerify, type: $type, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a custom template
#
# POST /custom_templates/create/string
# operationId: CustomTemplateCreateString
# --variables item shape: {defaultValue?: string, description?: string, label?: string, name?: string}
export def "custom-templates-create-string CustomTemplateCreateString" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string # Description of the template (e.g. High performance web server)
  --edgeTemplate: oneof<nothing, bool> # EdgeTemplate indicates if this template purpose for Edge Stack (e.g. false)
  fileContent: string # Content of stack file
  --logo: string # URL of the template's logo (e.g. https://portainer.io/img/logo.svg)
  --note: string # A note that will be displayed in the UI. Supports HTML content (e.g. This is my <b>custom</b> template)
  --platform: int@platform-completer # Platform associated to the template. Valid values are: 1 - 'linux', 2 - 'windows' Required for Docker stacks (e.g. 1)
  title: string # Title of the template (e.g. Nginx)
  type: int@type-completer # Type of created stack: * 1 - swarm * 2 - compose * 3 - kubernetes (e.g. 1)
  --body-variables: list # Definitions of variables in the stack file — item shape: {defaultValue?: string, description?: string, label?: string, name?: string}
]: any -> record<CreatedByUserId: int, Description: string, EntryPoint: string, GitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, Id: int, Logo: string, Note: string, Platform: int, ProjectPath: string, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Title: string, Type: int, edgeTemplate: bool, isComposeFormat: bool, variables: table<defaultValue: string, description: string, label: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/custom_templates/create/string")
  let body = {description: $description, edgeTemplate: $edgeTemplate, fileContent: $fileContent, logo: $logo, note: $note, platform: $platform, title: $title, type: $type, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch container gpus data
#
# GET /docker/{environmentId}/containers/{containerId}/gpus
# operationId: dockerContainerGpusInspect
export def "docker-containers-gpus dockerContainerGpusInspect" [
  environmentId: int
  containerId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<gpus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docker/($environmentId)/containers/($containerId)/gpus")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch images
#
# GET /docker/{environmentId}/images
# operationId: dockerImagesList
export def "docker-images dockerImagesList" [
  environmentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --withUsage: oneof<nothing, bool> # Include image usage information
]: nothing -> table<created: int, id: string, nodeName: string, size: int, tags: list<string>, used: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withUsage" $withUsage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docker/($environmentId)/images" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list EdgeGroups
#
# GET /edge_groups
# operationId: EdgeGroupList
export def "edge-groups EdgeGroupList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<Dynamic: bool, Endpoints: list<int>, HasEdgeJob: bool, HasEdgeStack: bool, Id: int, Name: string, PartialMatch: bool, TagIds: list<int>, TrustedEndpoints: list<int>, endpointTypes: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/edge_groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an EdgeGroup
#
# POST /edge_groups
# operationId: EdgeGroupCreate
export def "edge-groups EdgeGroupCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dynamic: oneof<nothing, bool>
  --endpoints: list
  --name: string
  --partialMatch: oneof<nothing, bool>
  --tagIDs: list
]: any -> record<Dynamic: bool, Endpoints: list<int>, Id: int, Name: string, PartialMatch: bool, TagIds: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/edge_groups")
  let body = {dynamic: $dynamic, endpoints: $endpoints, name: $name, partialMatch: $partialMatch, tagIDs: $tagIDs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes an EdgeGroup
#
# DELETE /edge_groups/{id}
# operationId: EdgeGroupDelete
export def "edge-groups EdgeGroupDelete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/edge_groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspects an EdgeGroup
#
# GET /edge_groups/{id}
# operationId: EdgeGroupInspect
export def "edge-groups EdgeGroupInspect" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Dynamic: bool, Endpoints: list<int>, Id: int, Name: string, PartialMatch: bool, TagIds: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/edge_groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates an EdgeGroup
#
# PUT /edge_groups/{id}
# operationId: EgeGroupUpdate
export def "edge-groups EgeGroupUpdate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dynamic: oneof<nothing, bool>
  --endpoints: list
  --name: string
  --partialMatch: oneof<nothing, bool>
  --tagIDs: list
]: any -> record<Dynamic: bool, Endpoints: list<int>, Id: int, Name: string, PartialMatch: bool, TagIds: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/edge_groups/($id)")
  let body = {dynamic: $dynamic, endpoints: $endpoints, name: $name, partialMatch: $partialMatch, tagIDs: $tagIDs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch EdgeJobs list
#
# GET /edge_jobs
# operationId: EdgeJobList
export def "edge-jobs EdgeJobList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<Created: int, CronExpression: string, EdgeGroups: list<int>, Endpoints: record, Id: int, Name: string, Recurring: bool, ScriptPath: string, Version: int, groupLogsCollection: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/edge_jobs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an EdgeJob
#
# POST /edge_jobs
# DEPRECATED
# operationId: EdgeJobCreate
@deprecated
export def "edge-jobs EdgeJobCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --method: string@method-completer-1 # Creation Method
  --body: record
]: any -> record<Dynamic: bool, Endpoints: list<int>, Id: int, Name: string, PartialMatch: bool, TagIds: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "method" $method "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/edge_jobs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an EdgeJob
#
# DELETE /edge_jobs/{id}
# operationId: EdgeJobDelete
export def "edge-jobs EdgeJobDelete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/edge_jobs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect an EdgeJob
#
# GET /edge_jobs/{id}
# operationId: EdgeJobInspect
export def "edge-jobs EdgeJobInspect" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Created: int, CronExpression: string, EdgeGroups: list<int>, Endpoints: record, Id: int, Name: string, Recurring: bool, ScriptPath: string, Version: int, groupLogsCollection: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/edge_jobs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an EdgeJob
#
# POST /edge_jobs/{id}
# operationId: EdgeJobUpdate
export def "edge-jobs EdgeJobUpdate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cronExpression: string
  --edgeGroups: list
  --endpoints: list
  --fileContent: string
  --name: string
  --recurring: oneof<nothing, bool>
]: any -> record<Created: int, CronExpression: string, EdgeGroups: list<int>, Endpoints: record, Id: int, Name: string, Recurring: bool, ScriptPath: string, Version: int, groupLogsCollection: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/edge_jobs/($id)")
  let body = {cronExpression: $cronExpression, edgeGroups: $edgeGroups, endpoints: $endpoints, fileContent: $fileContent, name: $name, recurring: $recurring} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a file of an EdgeJob
#
# GET /edge_jobs/{id}/file
# operationId: EdgeJobFile
export def "edge-jobs-file EdgeJobFile" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<FileContent: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/edge_jobs/($id)/file")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch the list of tasks on an EdgeJob
#
# GET /edge_jobs/{id}/tasks
# operationId: EdgeJobTasksList
export def "edge-jobs-tasks EdgeJobTasksList" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<EndpointId: int, Id: string, LogsStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/edge_jobs/($id)/tasks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Clear the log for a specifc task on an EdgeJob
#
# DELETE /edge_jobs/{id}/tasks/{taskID}/logs
# operationId: EdgeJobTasksClear
export def "edge-jobs-tasks-logs EdgeJobTasksClear" [
  id: int
  taskID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/edge_jobs/($id)/tasks/($taskID)/logs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch the log for a specifc task on an EdgeJob
#
# GET /edge_jobs/{id}/tasks/{taskID}/logs
# operationId: EdgeJobTaskLogsInspect
export def "edge-jobs-tasks-logs EdgeJobTaskLogsInspect" [
  id: int
  taskID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<FileContent: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/edge_jobs/($id)/tasks/($taskID)/logs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Collect the log for a specifc task on an EdgeJob
#
# POST /edge_jobs/{id}/tasks/{taskID}/logs
# operationId: EdgeJobTasksCollect
export def "edge-jobs-tasks-logs EdgeJobTasksCollect" [
  id: int
  taskID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/edge_jobs/($id)/tasks/($taskID)/logs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an EdgeJob from a file
#
# POST /edge_jobs/create/file
# operationId: EdgeJobCreateFile
export def "edge-jobs-create-file EdgeJobCreateFile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: path # Content of the Stack file
  Name: string # Name of the stack
  CronExpression: string # A cron expression to schedule this job
  EdgeGroups: string # JSON stringified array of Edge Groups ids
  Endpoints: string # JSON stringified array of Environment ids
  --Recurring: oneof<nothing, bool> # If recurring
]: any -> record<Dynamic: bool, Endpoints: list<int>, Id: int, Name: string, PartialMatch: bool, TagIds: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/edge_jobs/create/file")
  let body = {file: $file, Name: $Name, CronExpression: $CronExpression, EdgeGroups: $EdgeGroups, Endpoints: $Endpoints, Recurring: $Recurring} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Create an EdgeJob from a text
#
# POST /edge_jobs/create/string
# operationId: EdgeJobCreateString
export def "edge-jobs-create-string EdgeJobCreateString" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cronExpression: string
  --edgeGroups: list
  --endpoints: list
  --fileContent: string
  --name: string
  --recurring: oneof<nothing, bool>
]: any -> record<Dynamic: bool, Endpoints: list<int>, Id: int, Name: string, PartialMatch: bool, TagIds: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/edge_jobs/create/string")
  let body = {cronExpression: $cronExpression, edgeGroups: $edgeGroups, endpoints: $endpoints, fileContent: $fileContent, name: $name, recurring: $recurring} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetches the list of EdgeStacks
#
# GET /edge_stacks
# operationId: EdgeStackList
export def "edge-stacks EdgeStackList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<CreationDate: int, EdgeGroups: list<int>, EntryPoint: string, Id: int, Name: string, NumDeployments: int, ProjectPath: string, Prune: bool, Status: record, Version: int, deploymentType: int, manifestPath: string, useManifestNamespaces: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/edge_stacks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an EdgeStack
#
# POST /edge_stacks
# DEPRECATED
# operationId: EdgeStackCreate
@deprecated
export def "edge-stacks EdgeStackCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --method: string@method-completer # Creation Method
  --body: record
]: any -> record<CreationDate: int, EdgeGroups: list<int>, EntryPoint: string, Id: int, Name: string, NumDeployments: int, ProjectPath: string, Prune: bool, Status: record, Version: int, deploymentType: int, manifestPath: string, useManifestNamespaces: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "method" $method "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/edge_stacks" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an EdgeStack
#
# DELETE /edge_stacks/{id}
# operationId: EdgeStackDelete
export def "edge-stacks EdgeStackDelete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/edge_stacks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect an EdgeStack
#
# GET /edge_stacks/{id}
# operationId: EdgeStackInspect
export def "edge-stacks EdgeStackInspect" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<CreationDate: int, EdgeGroups: list<int>, EntryPoint: string, Id: int, Name: string, NumDeployments: int, ProjectPath: string, Prune: bool, Status: record, Version: int, deploymentType: int, manifestPath: string, useManifestNamespaces: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/edge_stacks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an EdgeStack
#
# PUT /edge_stacks/{id}
# operationId: EdgeStackUpdate
export def "edge-stacks EdgeStackUpdate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deploymentType: int@deploymentType-completer # Deployment type to deploy this stack Valid values are: 0 - 'compose', 1 - 'kubernetes' compose is enabled only for docker environments kubernetes is enabled only for kubernetes environments (e.g. 0)
  --edgeGroups: list
  --stackFileContent: string
  --updateVersion: oneof<nothing, bool>
  --useManifestNamespaces: oneof<nothing, bool> # Uses the manifest's namespaces instead of the default one
]: any -> record<CreationDate: int, EdgeGroups: list<int>, EntryPoint: string, Id: int, Name: string, NumDeployments: int, ProjectPath: string, Prune: bool, Status: record, Version: int, deploymentType: int, manifestPath: string, useManifestNamespaces: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/edge_stacks/($id)")
  let body = {deploymentType: $deploymentType, edgeGroups: $edgeGroups, stackFileContent: $stackFileContent, updateVersion: $updateVersion, useManifestNamespaces: $useManifestNamespaces} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetches the stack file for an EdgeStack
#
# GET /edge_stacks/{id}/file
# operationId: EdgeStackFile
export def "edge-stacks-file EdgeStackFile" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<StackFileContent: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/edge_stacks/($id)/file")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an EdgeStack status
#
# PUT /edge_stacks/{id}/status
# operationId: EdgeStackStatusUpdate
export def "edge-stacks-status EdgeStackStatusUpdate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointID: int
  --body-error: string
  --status: int # Deprecated
  --time: int
]: any -> record<CreationDate: int, EdgeGroups: list<int>, EntryPoint: string, Id: int, Name: string, NumDeployments: int, ProjectPath: string, Prune: bool, Status: record, Version: int, deploymentType: int, manifestPath: string, useManifestNamespaces: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/edge_stacks/($id)/status")
  let body = {endpointID: $endpointID, error: $body_error, status: $status, time: $time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an EdgeStack status
#
# DELETE /edge_stacks/{id}/status/{environmentId}
# DEPRECATED
# operationId: EdgeStackStatusDelete
@deprecated
export def "edge-stacks-status EdgeStackStatusDelete" [
  id: int
  environmentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<CreationDate: int, EdgeGroups: list<int>, EntryPoint: string, Id: int, Name: string, NumDeployments: int, ProjectPath: string, Prune: bool, Status: record, Version: int, deploymentType: int, manifestPath: string, useManifestNamespaces: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/edge_stacks/($id)/status/($environmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an EdgeStack from file
#
# POST /edge_stacks/create/file
# operationId: EdgeStackCreateFile
export def "edge-stacks-create-file EdgeStackCreateFile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dryrun: string # if true, will not create an edge stack, but just will check the settings and return a non-persisted edge stack object
  Name: string # Name of the stack
  file: path # Content of the Stack file
  EdgeGroups: string # JSON stringified array of Edge Groups ids
  DeploymentType: int # deploy type 0 - 'compose', 1 - 'kubernetes', 2 - 'nomad'
  --Registries: string # JSON stringified array of Registry ids to use for this stack
  --UseManifestNamespaces: oneof<nothing, bool> # Uses the manifest's namespaces instead of the default one, relevant only for kube environments
  --PrePullImage: oneof<nothing, bool> # Pre Pull image
  --RetryDeploy: oneof<nothing, bool> # Retry deploy
]: any -> record<CreationDate: int, EdgeGroups: list<int>, EntryPoint: string, Id: int, Name: string, NumDeployments: int, ProjectPath: string, Prune: bool, Status: record, Version: int, deploymentType: int, manifestPath: string, useManifestNamespaces: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dryrun" $dryrun "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/edge_stacks/create/file" $qp)
  let body = {Name: $Name, file: $file, EdgeGroups: $EdgeGroups, DeploymentType: $DeploymentType, Registries: $Registries, UseManifestNamespaces: $UseManifestNamespaces, PrePullImage: $PrePullImage, RetryDeploy: $RetryDeploy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Create an EdgeStack from a git repository
#
# POST /edge_stacks/create/repository
# operationId: EdgeStackCreateRepository
export def "edge-stacks-create-repository EdgeStackCreateRepository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dryrun: string # if true, will not create an edge stack, but just will check the settings and return a non-persisted edge stack object
  --deploymentType: int@deploymentType-completer # Deployment type to deploy this stack Valid values are: 0 - 'compose', 1 - 'kubernetes' compose is enabled only for docker environments kubernetes is enabled only for kubernetes environments (e.g. 0)
  edgeGroups: list # List of identifiers of EdgeGroups (e.g. [1])
  --filePathInRepository: string # Path to the Stack file inside the Git repository (default: docker-compose.yml, e.g. docker-compose.yml)
  name: string # Name of the stack (e.g. myStack)
  --registries: list # List of Registries to use for this stack
  --repositoryAuthentication: oneof<nothing, bool> # Use basic authentication to clone the Git repository (e.g. true)
  --repositoryPassword: string # Password used in basic authentication. Required when RepositoryAuthentication is true. (e.g. myGitPassword)
  --repositoryReferenceName: string # Reference name of a Git repository hosting the Stack file (e.g. refs/heads/master)
  repositoryURL: string # URL of a Git repository hosting the Stack file (e.g. https://github.com/openfaas/faas)
  --repositoryUsername: string # Username used in basic authentication. Required when RepositoryAuthentication is true. (e.g. myGitUsername)
  --tlsskipVerify: oneof<nothing, bool> # TLSSkipVerify skips SSL verification when cloning the Git repository (e.g. false)
  --useManifestNamespaces: oneof<nothing, bool> # Uses the manifest's namespaces instead of the default one
]: any -> record<CreationDate: int, EdgeGroups: list<int>, EntryPoint: string, Id: int, Name: string, NumDeployments: int, ProjectPath: string, Prune: bool, Status: record, Version: int, deploymentType: int, manifestPath: string, useManifestNamespaces: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dryrun" $dryrun "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/edge_stacks/create/repository" $qp)
  let body = {deploymentType: $deploymentType, edgeGroups: $edgeGroups, filePathInRepository: $filePathInRepository, name: $name, registries: $registries, repositoryAuthentication: $repositoryAuthentication, repositoryPassword: $repositoryPassword, repositoryReferenceName: $repositoryReferenceName, repositoryURL: $repositoryURL, repositoryUsername: $repositoryUsername, tlsskipVerify: $tlsskipVerify, useManifestNamespaces: $useManifestNamespaces} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an EdgeStack from a text
#
# POST /edge_stacks/create/string
# operationId: EdgeStackCreateString
export def "edge-stacks-create-string EdgeStackCreateString" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dryrun: string # if true, will not create an edge stack, but just will check the settings and return a non-persisted edge stack object
  --deploymentType: int@deploymentType-completer # Deployment type to deploy this stack Valid values are: 0 - 'compose', 1 - 'kubernetes' compose is enabled only for docker environments kubernetes is enabled only for kubernetes environments (e.g. 0)
  --edgeGroups: list # List of identifiers of EdgeGroups (e.g. [1])
  name: string # Name of the stack (e.g. myStack)
  --registries: list # List of Registries to use for this stack
  stackFileContent: string # Content of the Stack file (e.g. version: 3  services:  web:  image:nginx)
  --useManifestNamespaces: oneof<nothing, bool> # Uses the manifest's namespaces instead of the default one
]: any -> record<CreationDate: int, EdgeGroups: list<int>, EntryPoint: string, Id: int, Name: string, NumDeployments: int, ProjectPath: string, Prune: bool, Status: record, Version: int, deploymentType: int, manifestPath: string, useManifestNamespaces: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dryrun" $dryrun "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/edge_stacks/create/string" $qp)
  let body = {deploymentType: $deploymentType, edgeGroups: $edgeGroups, name: $name, registries: $registries, stackFileContent: $stackFileContent, useManifestNamespaces: $useManifestNamespaces} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetches the list of Edge Templates
#
# GET /edge_templates
# DEPRECATED
# operationId: EdgeTemplateList
@deprecated
export def "edge-templates EdgeTemplateList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<administrator_only: bool, categories: list<string>, command: string, description: string, env: list<record>, hostname: string, id: int, image: string, interactive: bool, labels: list<record>, logo: string, name: string, network: string, note: string, platform: string, ports: list<string>, privileged: bool, registry: string, repository: record<stackfile: string, url: string>, restart_policy: string, stackFile: string, title: string, type: int, volumes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/edge_templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Environment(Endpoint) groups
#
# GET /endpoint_groups
# operationId: EndpointGroupList
export def "endpoint-groups EndpointGroupList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<AuthorizedTeams: list<int>, AuthorizedUsers: list<int>, Description: string, Id: int, Labels: list<record>, Name: string, TagIds: list<int>, Tags: list<string>, TeamAccessPolicies: record, UserAccessPolicies: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/endpoint_groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Environment(Endpoint) Group
#
# POST /endpoint_groups
export def "endpoint-groups post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --associatedEndpoints: list # List of environment(endpoint) identifiers that will be part of this group (e.g. [1, 3])
  --description: string # Environment(Endpoint) group description (e.g. description)
  name: string # Environment(Endpoint) group name (e.g. my-environment-group)
  --tagIDs: list # List of tag identifiers to which this environment(endpoint) group is associated (e.g. [1, 2])
]: any -> record<AuthorizedTeams: list<int>, AuthorizedUsers: list<int>, Description: string, Id: int, Labels: table<name: string, value: string>, Name: string, TagIds: list<int>, Tags: list<string>, TeamAccessPolicies: record, UserAccessPolicies: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/endpoint_groups")
  let body = {associatedEndpoints: $associatedEndpoints, description: $description, name: $name, tagIDs: $tagIDs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an environment(endpoint) group
#
# DELETE /endpoint_groups/{id}
# operationId: EndpointGroupDelete
export def "endpoint-groups EndpointGroupDelete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoint_groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect an Environment(Endpoint) group
#
# GET /endpoint_groups/{id}
export def "endpoint-groups get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<AuthorizedTeams: list<int>, AuthorizedUsers: list<int>, Description: string, Id: int, Labels: table<name: string, value: string>, Name: string, TagIds: list<int>, Tags: list<string>, TeamAccessPolicies: record, UserAccessPolicies: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoint_groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an environment(endpoint) group
#
# PUT /endpoint_groups/{id}
# operationId: EndpointGroupUpdate
export def "endpoint-groups EndpointGroupUpdate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Environment(Endpoint) group description (e.g. description)
  --name: string # Environment(Endpoint) group name (e.g. my-environment-group)
  --tagIDs: list # List of tag identifiers associated to the environment(endpoint) group (e.g. [3, 4])
  --teamAccessPolicies: record
  --userAccessPolicies: record
]: any -> record<AuthorizedTeams: list<int>, AuthorizedUsers: list<int>, Description: string, Id: int, Labels: table<name: string, value: string>, Name: string, TagIds: list<int>, Tags: list<string>, TeamAccessPolicies: record, UserAccessPolicies: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoint_groups/($id)")
  let body = {description: $description, name: $name, tagIDs: $tagIDs, teamAccessPolicies: $teamAccessPolicies, userAccessPolicies: $userAccessPolicies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Removes environment(endpoint) from an environment(endpoint) group
#
# DELETE /endpoint_groups/{id}/endpoints/{endpointId}
# operationId: EndpointGroupDeleteEndpoint
export def "endpoint-groups-endpoints EndpointGroupDeleteEndpoint" [
  id: int
  endpointId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoint_groups/($id)/endpoints/($endpointId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an environment(endpoint) to an environment(endpoint) group
#
# PUT /endpoint_groups/{id}/endpoints/{endpointId}
# operationId: EndpointGroupAddEndpoint
export def "endpoint-groups-endpoints EndpointGroupAddEndpoint" [
  id: int
  endpointId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoint_groups/($id)/endpoints/($endpointId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List environments(endpoints)
#
# GET /endpoints
# operationId: EndpointList
export def "endpoints EndpointList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Start searching from
  --limit: int # Limit results to this value
  --order: int # Order sorted results by desc/asc
  --search: string # Search query
  --groupIds: list # List environments(endpoints) of these groups
  --status: list # List environments(endpoints) by this status
  --types: list # List environments(endpoints) of this type
  --tagIds: list # search environments(endpoints) with these tags (depends on tagsPartialMatch)
  --tagsPartialMatch: oneof<nothing, bool> # If true, will return environment(endpoint) which has one of tagIds, if false (or missing) will return only environments(endpoints) that has all the tags
  --endpointIds: list # will return only these environments(endpoints)
  --provisioned: oneof<nothing, bool> # If true, will return environment(endpoint) that were provisioned
  --agentVersions: list # will return only environments with on of these agent versions
  --edgeAsync: oneof<nothing, bool> # if exists true show only edge async agents, false show only standard edge agents. if missing, will show both types (relevant only for edge agents)
  --edgeDeviceUntrusted: oneof<nothing, bool> # if true, show only untrusted edge agents, if false show only trusted edge agents (relevant only for edge agents)
  --edgeCheckInPassedSeconds: float # if bigger then zero, show only edge agents that checked-in in the last provided seconds (relevant only for edge agents)
  --excludeSnapshots: oneof<nothing, bool> # if true, the snapshot data won't be retrieved
  --name: string # will return only environments(endpoints) with this name
  --edgeStackStatus: string # only applied when edgeStackId exists. Filter the returned environments based on their deployment status in the stack (not the environment status!)
]: nothing -> table<AMTDeviceGUID: string, AuthorizedTeams: list<int>, AuthorizedUsers: list<int>, AzureCredentials: record<ApplicationID: string, AuthenticationKey: string, TenantID: string>, ComposeSyntaxMaxVersion: string, EdgeCheckinInterval: int, EdgeID: string, EdgeKey: string, EnableGPUManagement: bool, Gpus: list<record>, GroupId: int, Heartbeat: bool, Id: int, IsEdgeDevice: bool, Kubernetes: record<Configuration: record, Flags: record, Snapshots: list>, Name: string, PostInitMigrations: record<MigrateGPUs: bool, MigrateIngresses: bool>, PublicURL: string, Snapshots: list<record>, Status: int, TLS: bool, TLSCACert: string, TLSCert: string, TLSConfig: record<TLS: bool, TLSCACert: string, TLSCert: string, TLSKey: string, TLSSkipVerify: bool>, TLSKey: string, TagIds: list<int>, Tags: list<string>, TeamAccessPolicies: record, Type: int, URL: string, UserAccessPolicies: record, UserTrusted: bool, agent: record<version: string>, edge: record<CommandInterval: int, PingInterval: int, SnapshotInterval: int, asyncMode: bool>, lastCheckInDate: int, queryDate: int, securitySettings: record<allowBindMountsForRegularUsers: bool, allowContainerCapabilitiesForRegularUsers: bool, allowDeviceMappingForRegularUsers: bool, allowHostNamespaceForRegularUsers: bool, allowPrivilegedModeForRegularUsers: bool, allowStackManagementForRegularUsers: bool, allowSysctlSettingForRegularUsers: bool, allowVolumeBrowserForRegularUsers: bool, enableHostManagementFeatures: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "groupIds" $groupIds "csv") (serialize-qp "status" $status "csv") (serialize-qp "types" $types "csv") (serialize-qp "tagIds" $tagIds "csv") (serialize-qp "tagsPartialMatch" $tagsPartialMatch "scalar") (serialize-qp "endpointIds" $endpointIds "csv") (serialize-qp "provisioned" $provisioned "scalar") (serialize-qp "agentVersions" $agentVersions "csv") (serialize-qp "edgeAsync" $edgeAsync "scalar") (serialize-qp "edgeDeviceUntrusted" $edgeDeviceUntrusted "scalar") (serialize-qp "edgeCheckInPassedSeconds" $edgeCheckInPassedSeconds "scalar") (serialize-qp "excludeSnapshots" $excludeSnapshots "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "edgeStackStatus" $edgeStackStatus "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/endpoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new environment(endpoint)
#
# POST /endpoints
# operationId: EndpointCreate
export def "endpoints EndpointCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Name: string # Name that will be used to identify this environment(endpoint) (example: my-environment)
  EndpointCreationType: int # Environment(Endpoint) type. Value must be one of: 1 (Local Docker environment), 2 (Agent environment), 3 (Azure environment), 4 (Edge agent environment) or 5 (Local Kubernetes Environment)
  --URL: string # URL or IP address of a Docker host (example: docker.mydomain.tld:2375). Defaults to local if not specified (Linux: /var/run/docker.sock, Windows: //./pipe/docker_engine). Cannot be empty if EndpointCreationType is set to 4 (Edge agent environment)
  --PublicURL: string # URL or IP address where exposed containers will be reachable. Defaults to URL if not specified (example: docker.mydomain.tld:2375)
  --GroupID: int # Environment(Endpoint) group identifier. If not specified will default to 1 (unassigned).
  --TLS: oneof<nothing, bool> # Require TLS to connect against this environment(endpoint). Must be true if EndpointCreationType is set to 2 (Agent environment)
  --TLSSkipVerify: oneof<nothing, bool> # Skip server verification when using TLS. Must be true if EndpointCreationType is set to 2 (Agent environment)
  --TLSSkipClientVerify: oneof<nothing, bool> # Skip client verification when using TLS. Must be true if EndpointCreationType is set to 2 (Agent environment)
  --TLSCACertFile: path # TLS CA certificate file
  --TLSCertFile: path # TLS client certificate file
  --TLSKeyFile: path # TLS client key file
  --AzureApplicationID: string # Azure application ID. Required if environment(endpoint) type is set to 3
  --AzureTenantID: string # Azure tenant ID. Required if environment(endpoint) type is set to 3
  --AzureAuthenticationKey: string # Azure authentication key. Required if environment(endpoint) type is set to 3
  --TagIds: list # List of tag identifiers to which this environment(endpoint) is associated
  --EdgeCheckinInterval: int # The check in interval for edge agent (in seconds)
  EdgeTunnelServerAddress: string # URL or IP address that will be used to establish a reverse tunnel
  --Gpus: string # List of GPUs - json stringified array of {name, value} structs
]: any -> record<AMTDeviceGUID: string, AuthorizedTeams: list<int>, AuthorizedUsers: list<int>, AzureCredentials: record<ApplicationID: string, AuthenticationKey: string, TenantID: string>, ComposeSyntaxMaxVersion: string, EdgeCheckinInterval: int, EdgeID: string, EdgeKey: string, EnableGPUManagement: bool, Gpus: table<name: string, value: string>, GroupId: int, Heartbeat: bool, Id: int, IsEdgeDevice: bool, Kubernetes: record<Configuration: record<AllowNoneIngressClass: bool, EnableResourceOverCommit: bool, IngressAvailabilityPerNamespace: bool, IngressClasses: list, ResourceOverCommitPercentage: int, RestrictDefaultNamespace: bool, StorageClasses: list, UseLoadBalancer: bool, UseServerMetrics: bool>, Flags: record<IsServerIngressClassDetected: bool, IsServerMetricsDetected: bool, IsServerStorageDetected: bool>, Snapshots: list<record>>, Name: string, PostInitMigrations: record<MigrateGPUs: bool, MigrateIngresses: bool>, PublicURL: string, Snapshots: table<ContainerCount: int, DockerSnapshotRaw: record, DockerVersion: string, GpuUseAll: bool, GpuUseList: list, HealthyContainerCount: int, ImageCount: int, NodeCount: int, RunningContainerCount: int, ServiceCount: int, StackCount: int, StoppedContainerCount: int, Swarm: bool, Time: int, TotalCPU: int, TotalMemory: int, UnhealthyContainerCount: int, VolumeCount: int>, Status: int, TLS: bool, TLSCACert: string, TLSCert: string, TLSConfig: record<TLS: bool, TLSCACert: string, TLSCert: string, TLSKey: string, TLSSkipVerify: bool>, TLSKey: string, TagIds: list<int>, Tags: list<string>, TeamAccessPolicies: record, Type: int, URL: string, UserAccessPolicies: record, UserTrusted: bool, agent: record<version: string>, edge: record<CommandInterval: int, PingInterval: int, SnapshotInterval: int, asyncMode: bool>, lastCheckInDate: int, queryDate: int, securitySettings: record<allowBindMountsForRegularUsers: bool, allowContainerCapabilitiesForRegularUsers: bool, allowDeviceMappingForRegularUsers: bool, allowHostNamespaceForRegularUsers: bool, allowPrivilegedModeForRegularUsers: bool, allowStackManagementForRegularUsers: bool, allowSysctlSettingForRegularUsers: bool, allowVolumeBrowserForRegularUsers: bool, enableHostManagementFeatures: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/endpoints")
  let body = {Name: $Name, EndpointCreationType: $EndpointCreationType, URL: $URL, PublicURL: $PublicURL, GroupID: $GroupID, TLS: $TLS, TLSSkipVerify: $TLSSkipVerify, TLSSkipClientVerify: $TLSSkipClientVerify, TLSCACertFile: $TLSCACertFile, TLSCertFile: $TLSCertFile, TLSKeyFile: $TLSKeyFile, AzureApplicationID: $AzureApplicationID, AzureTenantID: $AzureTenantID, AzureAuthenticationKey: $AzureAuthenticationKey, TagIds: $TagIds, EdgeCheckinInterval: $EdgeCheckinInterval, EdgeTunnelServerAddress: $EdgeTunnelServerAddress, Gpus: $Gpus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($TLSCACertFile | is-not-empty) { $body | upsert TLSCACertFile (open -r $TLSCACertFile) } else { $body }
  let body = if ($TLSCertFile | is-not-empty) { $body | upsert TLSCertFile (open -r $TLSCertFile) } else { $body }
  let body = if ($TLSKeyFile | is-not-empty) { $body | upsert TLSKeyFile (open -r $TLSKeyFile) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Remove an environment(endpoint)
#
# DELETE /endpoints/{id}
# operationId: EndpointDelete
export def "endpoints EndpointDelete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect an environment(endpoint)
#
# GET /endpoints/{id}
# operationId: EndpointInspect
export def "endpoints EndpointInspect" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<AMTDeviceGUID: string, AuthorizedTeams: list<int>, AuthorizedUsers: list<int>, AzureCredentials: record<ApplicationID: string, AuthenticationKey: string, TenantID: string>, ComposeSyntaxMaxVersion: string, EdgeCheckinInterval: int, EdgeID: string, EdgeKey: string, EnableGPUManagement: bool, Gpus: table<name: string, value: string>, GroupId: int, Heartbeat: bool, Id: int, IsEdgeDevice: bool, Kubernetes: record<Configuration: record<AllowNoneIngressClass: bool, EnableResourceOverCommit: bool, IngressAvailabilityPerNamespace: bool, IngressClasses: list, ResourceOverCommitPercentage: int, RestrictDefaultNamespace: bool, StorageClasses: list, UseLoadBalancer: bool, UseServerMetrics: bool>, Flags: record<IsServerIngressClassDetected: bool, IsServerMetricsDetected: bool, IsServerStorageDetected: bool>, Snapshots: list<record>>, Name: string, PostInitMigrations: record<MigrateGPUs: bool, MigrateIngresses: bool>, PublicURL: string, Snapshots: table<ContainerCount: int, DockerSnapshotRaw: record, DockerVersion: string, GpuUseAll: bool, GpuUseList: list, HealthyContainerCount: int, ImageCount: int, NodeCount: int, RunningContainerCount: int, ServiceCount: int, StackCount: int, StoppedContainerCount: int, Swarm: bool, Time: int, TotalCPU: int, TotalMemory: int, UnhealthyContainerCount: int, VolumeCount: int>, Status: int, TLS: bool, TLSCACert: string, TLSCert: string, TLSConfig: record<TLS: bool, TLSCACert: string, TLSCert: string, TLSKey: string, TLSSkipVerify: bool>, TLSKey: string, TagIds: list<int>, Tags: list<string>, TeamAccessPolicies: record, Type: int, URL: string, UserAccessPolicies: record, UserTrusted: bool, agent: record<version: string>, edge: record<CommandInterval: int, PingInterval: int, SnapshotInterval: int, asyncMode: bool>, lastCheckInDate: int, queryDate: int, securitySettings: record<allowBindMountsForRegularUsers: bool, allowContainerCapabilitiesForRegularUsers: bool, allowDeviceMappingForRegularUsers: bool, allowHostNamespaceForRegularUsers: bool, allowPrivilegedModeForRegularUsers: bool, allowStackManagementForRegularUsers: bool, allowSysctlSettingForRegularUsers: bool, allowVolumeBrowserForRegularUsers: bool, enableHostManagementFeatures: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an environment(endpoint)
#
# PUT /endpoints/{id}
# operationId: EndpointUpdate
# --gpus item shape: {name?: string, value?: string}
# --kubernetes shape: {Configuration?: record, Flags?: record, Snapshots?: list}
export def "endpoints EndpointUpdate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --azureApplicationID: string # Azure application ID (e.g. eag7cdo9-o09l-9i83-9dO9-f0b23oe78db4)
  --azureAuthenticationKey: string # Azure authentication key (e.g. cOrXoK/1D35w8YQ8nH1/8ZGwzz45JIYD5jxHKXEQknk=)
  --azureTenantID: string # Azure tenant ID (e.g. 34ddc78d-4fel-2358-8cc1-df84c8o839f5)
  --edgeCheckinInterval: int # The check in interval for edge agent (in seconds) (e.g. 5)
  --gpus: list # GPUs information — item shape: {name?: string, value?: string}
  --groupID: int # Group identifier (e.g. 1)
  --kubernetes: record # shape: {Configuration?: record, Flags?: record, Snapshots?: list}
  --name: string # Name that will be used to identify this environment(endpoint) (e.g. my-environment)
  --publicURL: string # URL or IP address where exposed containers will be reachable.\ Defaults to URL if not specified (e.g. docker.mydomain.tld:2375)
  --status: int # The status of the environment(endpoint) (1 - up, 2 - down) (e.g. 1)
  --tagIDs: list # List of tag identifiers to which this environment(endpoint) is associated (e.g. [1, 2])
  --teamAccessPolicies: record
  --tls: oneof<nothing, bool> # Require TLS to connect against this environment(endpoint) (e.g. true)
  --tlsskipClientVerify: oneof<nothing, bool> # Skip client verification when using TLS (e.g. false)
  --tlsskipVerify: oneof<nothing, bool> # Skip server verification when using TLS (e.g. false)
  --body-url: string # URL or IP address of a Docker host (e.g. docker.mydomain.tld:2375)
  --userAccessPolicies: record
]: any -> record<AMTDeviceGUID: string, AuthorizedTeams: list<int>, AuthorizedUsers: list<int>, AzureCredentials: record<ApplicationID: string, AuthenticationKey: string, TenantID: string>, ComposeSyntaxMaxVersion: string, EdgeCheckinInterval: int, EdgeID: string, EdgeKey: string, EnableGPUManagement: bool, Gpus: table<name: string, value: string>, GroupId: int, Heartbeat: bool, Id: int, IsEdgeDevice: bool, Kubernetes: record<Configuration: record<AllowNoneIngressClass: bool, EnableResourceOverCommit: bool, IngressAvailabilityPerNamespace: bool, IngressClasses: list, ResourceOverCommitPercentage: int, RestrictDefaultNamespace: bool, StorageClasses: list, UseLoadBalancer: bool, UseServerMetrics: bool>, Flags: record<IsServerIngressClassDetected: bool, IsServerMetricsDetected: bool, IsServerStorageDetected: bool>, Snapshots: list<record>>, Name: string, PostInitMigrations: record<MigrateGPUs: bool, MigrateIngresses: bool>, PublicURL: string, Snapshots: table<ContainerCount: int, DockerSnapshotRaw: record, DockerVersion: string, GpuUseAll: bool, GpuUseList: list, HealthyContainerCount: int, ImageCount: int, NodeCount: int, RunningContainerCount: int, ServiceCount: int, StackCount: int, StoppedContainerCount: int, Swarm: bool, Time: int, TotalCPU: int, TotalMemory: int, UnhealthyContainerCount: int, VolumeCount: int>, Status: int, TLS: bool, TLSCACert: string, TLSCert: string, TLSConfig: record<TLS: bool, TLSCACert: string, TLSCert: string, TLSKey: string, TLSSkipVerify: bool>, TLSKey: string, TagIds: list<int>, Tags: list<string>, TeamAccessPolicies: record, Type: int, URL: string, UserAccessPolicies: record, UserTrusted: bool, agent: record<version: string>, edge: record<CommandInterval: int, PingInterval: int, SnapshotInterval: int, asyncMode: bool>, lastCheckInDate: int, queryDate: int, securitySettings: record<allowBindMountsForRegularUsers: bool, allowContainerCapabilitiesForRegularUsers: bool, allowDeviceMappingForRegularUsers: bool, allowHostNamespaceForRegularUsers: bool, allowPrivilegedModeForRegularUsers: bool, allowStackManagementForRegularUsers: bool, allowSysctlSettingForRegularUsers: bool, allowVolumeBrowserForRegularUsers: bool, enableHostManagementFeatures: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($id)")
  let body = {azureApplicationID: $azureApplicationID, azureAuthenticationKey: $azureAuthenticationKey, azureTenantID: $azureTenantID, edgeCheckinInterval: $edgeCheckinInterval, gpus: $gpus, groupID: $groupID, kubernetes: $kubernetes, name: $name, publicURL: $publicURL, status: $status, tagIDs: $tagIDs, teamAccessPolicies: $teamAccessPolicies, tls: $tls, tlsskipClientVerify: $tlsskipClientVerify, tlsskipVerify: $tlsskipVerify, url: $body_url, userAccessPolicies: $userAccessPolicies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# De-association an edge environment(endpoint)
#
# PUT /endpoints/{id}/association
# operationId: EndpointAssociationDelete
export def "endpoints-association EndpointAssociationDelete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($id)/association")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a file under a specific path on the file system of an environment (endpoint)
#
# POST /endpoints/{id}/docker/v2/browse/put
export def "endpoints-docker-browse-put post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --volumeID: string # Optional volume identifier to upload the file
  Path: string # The destination path to upload the file to
  file: path # The file to upload
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "volumeID" $volumeID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/endpoints/($id)/docker/v2/browse/put" $qp)
  let body = {Path: $Path, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# fetch docker pull limits
#
# GET /endpoints/{id}/dockerhub/{registryId}
# operationId: endpointDockerhubStatus
export def "endpoints-dockerhub endpointDockerhubStatus" [
  id: int
  registryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<limit: int, remaining: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($id)/dockerhub/($registryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect an EdgeJob Log
#
# POST /endpoints/{id}/edge/jobs/{jobID}/logs
export def "endpoints-edge-jobs-logs post" [
  id: int
  jobID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($id)/edge/jobs/($jobID)/logs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect an Edge Stack for an Environment(Endpoint)
#
# GET /endpoints/{id}/edge/stacks/{stackId}
export def "endpoints-edge-stacks get" [
  id: int
  stackId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dirEntries: table<content: string, isFile: bool, name: string, permissions: int>, edgeUpdateID: int, entryFileName: string, envVars: table<name: string, value: string>, filesystemPath: string, id: int, name: string, namespace: string, prePullImage: bool, rePullImage: bool, readyRePullImage: bool, registryCredentials: table<secret: string, serverURL: string, username: string>, retryDeploy: bool, rollbackTo: int, stackFileContent: string, supportRelativePath: bool, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($id)/edge/stacks/($stackId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get environment(endpoint) status
#
# GET /endpoints/{id}/edge/status
# operationId: EndpointEdgeStatusInspect
export def "endpoints-edge-status EndpointEdgeStatusInspect" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<checkin: int, credentials: string, port: int, schedules: table<CollectLogs: bool, CronExpression: string, Id: int, Script: string, Version: int>, stacks: table<id: int, version: int>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($id)/edge/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# force update a docker service
#
# PUT /endpoints/{id}/forceupdateservice
# operationId: endpointForceUpdateService
export def "endpoints-forceupdateservice endpointForceUpdateService" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pullImage: oneof<nothing, bool> # PullImage if true will pull the image
  --serviceID: string # ServiceId to update
]: any -> record<Warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($id)/forceupdateservice")
  let body = {pullImage: $pullImage, serviceID: $serviceID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Helm Releases
#
# GET /endpoints/{id}/kubernetes/helm
# operationId: HelmList
export def "endpoints-kubernetes-helm HelmList" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namespace: string # specify an optional namespace
  --filter: string # specify an optional filter
  --selector: string # specify an optional selector
]: nothing -> table<app_version: string, chart: string, name: string, namespace: string, revision: string, status: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "selector" $selector "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/endpoints/($id)/kubernetes/helm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Install Helm Chart
#
# POST /endpoints/{id}/kubernetes/helm
# operationId: HelmInstall
export def "endpoints-kubernetes-helm HelmInstall" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chart: string
  --name: string
  --namespace: string
  --repo: string
  --values: string
]: any -> record<chart: record<files: list<record>, lock: record<dependencies: list, digest: string, generated: string>, metadata: record<annotations: record, apiVersion: string, appVersion: string, condition: string, dependencies: list, deprecated: bool, description: string, home: string, icon: string, keywords: list, kubeVersion: string, maintainers: list, name: string, sources: list, tags: string, type: string, version: string>, schema: list<int>, templates: list<record>, values: record>, config: record, hooks: table<delete_policies: list, events: list, kind: string, last_run: record, manifest: string, name: string, path: string, weight: int>, manifest: string, name: string, namespace: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($id)/kubernetes/helm")
  let body = {chart: $chart, name: $name, namespace: $namespace, repo: $repo, values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Helm Release
#
# DELETE /endpoints/{id}/kubernetes/helm/{release}
# operationId: HelmDelete
export def "endpoints-kubernetes-helm HelmDelete" [
  id: int
  release: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namespace: string # An optional namespace
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/endpoints/($id)/kubernetes/helm/($release)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a users helm repositories
#
# GET /endpoints/{id}/kubernetes/helm/repositories
# DEPRECATED
# operationId: HelmUserRepositoriesListDeprecated
@deprecated
export def "endpoints-kubernetes-helm-repositories HelmUserRepositoriesListDeprecated" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<GlobalRepository: string, UserRepositories: table<Id: int, URL: string, UserId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($id)/kubernetes/helm/repositories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a user helm repository
#
# POST /endpoints/{id}/kubernetes/helm/repositories
# DEPRECATED
# operationId: HelmUserRepositoryCreateDeprecated
@deprecated
export def "endpoints-kubernetes-helm-repositories HelmUserRepositoryCreateDeprecated" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string
]: any -> record<Id: int, URL: string, UserId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($id)/kubernetes/helm/repositories")
  let body = {url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Registries on environment
#
# GET /endpoints/{id}/registries
# operationId: endpointRegistriesList
export def "endpoints-registries endpointRegistriesList" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namespace: string # required if kubernetes environment, will show registries by namespace
]: nothing -> table<AccessToken: string, AccessTokenExpiry: int, Authentication: bool, AuthorizedTeams: list<int>, AuthorizedUsers: list<int>, BaseURL: string, Ecr: record<Region: string>, Gitlab: record<InstanceURL: string, ProjectId: int, ProjectPath: string>, Id: int, ManagementConfiguration: record<AccessToken: string, AccessTokenExpiry: int, Authentication: bool, Ecr: record, Password: string, TLSConfig: record, Type: int, Username: string>, Name: string, Password: string, Quay: record<OrganisationName: string, UseOrganisation: bool>, RegistryAccesses: record, TeamAccessPolicies: record, Type: int, URL: string, UserAccessPolicies: record, Username: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/endpoints/($id)/registries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# update registry access for environment
#
# PUT /endpoints/{id}/registries/{registryId}
# operationId: endpointRegistryAccess
export def "endpoints-registries endpointRegistryAccess" [
  id: int
  registryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namespaces: list
  --teamAccessPolicies: record
  --userAccessPolicies: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($id)/registries/($registryId)")
  let body = {namespaces: $namespaces, teamAccessPolicies: $teamAccessPolicies, userAccessPolicies: $userAccessPolicies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update settings for an environment(endpoint)
#
# PUT /endpoints/{id}/settings
# operationId: EndpointSettingsUpdate
# --gpus item shape: {name?: string, value?: string}
export def "endpoints-settings EndpointSettingsUpdate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowBindMountsForRegularUsers: oneof<nothing, bool> # Whether non-administrator should be able to use bind mounts when creating containers (e.g. false)
  --allowContainerCapabilitiesForRegularUsers: oneof<nothing, bool> # Whether non-administrator should be able to use container capabilities (e.g. true)
  --allowDeviceMappingForRegularUsers: oneof<nothing, bool> # Whether non-administrator should be able to use device mapping (e.g. true)
  --allowHostNamespaceForRegularUsers: oneof<nothing, bool> # Whether non-administrator should be able to use the host pid (e.g. true)
  --allowPrivilegedModeForRegularUsers: oneof<nothing, bool> # Whether non-administrator should be able to use privileged mode when creating containers (e.g. false)
  --allowStackManagementForRegularUsers: oneof<nothing, bool> # Whether non-administrator should be able to manage stacks (e.g. true)
  --allowSysctlSettingForRegularUsers: oneof<nothing, bool> # Whether non-administrator should be able to use sysctl settings (e.g. true)
  --allowVolumeBrowserForRegularUsers: oneof<nothing, bool> # Whether non-administrator should be able to browse volumes (e.g. true)
  --enableGPUManagement: oneof<nothing, bool> # e.g. false
  --enableHostManagementFeatures: oneof<nothing, bool> # Whether host management features are enabled (e.g. true)
  --gpus: list # item shape: {name?: string, value?: string}
]: any -> record<AMTDeviceGUID: string, AuthorizedTeams: list<int>, AuthorizedUsers: list<int>, AzureCredentials: record<ApplicationID: string, AuthenticationKey: string, TenantID: string>, ComposeSyntaxMaxVersion: string, EdgeCheckinInterval: int, EdgeID: string, EdgeKey: string, EnableGPUManagement: bool, Gpus: table<name: string, value: string>, GroupId: int, Heartbeat: bool, Id: int, IsEdgeDevice: bool, Kubernetes: record<Configuration: record<AllowNoneIngressClass: bool, EnableResourceOverCommit: bool, IngressAvailabilityPerNamespace: bool, IngressClasses: list, ResourceOverCommitPercentage: int, RestrictDefaultNamespace: bool, StorageClasses: list, UseLoadBalancer: bool, UseServerMetrics: bool>, Flags: record<IsServerIngressClassDetected: bool, IsServerMetricsDetected: bool, IsServerStorageDetected: bool>, Snapshots: list<record>>, Name: string, PostInitMigrations: record<MigrateGPUs: bool, MigrateIngresses: bool>, PublicURL: string, Snapshots: table<ContainerCount: int, DockerSnapshotRaw: record, DockerVersion: string, GpuUseAll: bool, GpuUseList: list, HealthyContainerCount: int, ImageCount: int, NodeCount: int, RunningContainerCount: int, ServiceCount: int, StackCount: int, StoppedContainerCount: int, Swarm: bool, Time: int, TotalCPU: int, TotalMemory: int, UnhealthyContainerCount: int, VolumeCount: int>, Status: int, TLS: bool, TLSCACert: string, TLSCert: string, TLSConfig: record<TLS: bool, TLSCACert: string, TLSCert: string, TLSKey: string, TLSSkipVerify: bool>, TLSKey: string, TagIds: list<int>, Tags: list<string>, TeamAccessPolicies: record, Type: int, URL: string, UserAccessPolicies: record, UserTrusted: bool, agent: record<version: string>, edge: record<CommandInterval: int, PingInterval: int, SnapshotInterval: int, asyncMode: bool>, lastCheckInDate: int, queryDate: int, securitySettings: record<allowBindMountsForRegularUsers: bool, allowContainerCapabilitiesForRegularUsers: bool, allowDeviceMappingForRegularUsers: bool, allowHostNamespaceForRegularUsers: bool, allowPrivilegedModeForRegularUsers: bool, allowStackManagementForRegularUsers: bool, allowSysctlSettingForRegularUsers: bool, allowVolumeBrowserForRegularUsers: bool, enableHostManagementFeatures: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($id)/settings")
  let body = {allowBindMountsForRegularUsers: $allowBindMountsForRegularUsers, allowContainerCapabilitiesForRegularUsers: $allowContainerCapabilitiesForRegularUsers, allowDeviceMappingForRegularUsers: $allowDeviceMappingForRegularUsers, allowHostNamespaceForRegularUsers: $allowHostNamespaceForRegularUsers, allowPrivilegedModeForRegularUsers: $allowPrivilegedModeForRegularUsers, allowStackManagementForRegularUsers: $allowStackManagementForRegularUsers, allowSysctlSettingForRegularUsers: $allowSysctlSettingForRegularUsers, allowVolumeBrowserForRegularUsers: $allowVolumeBrowserForRegularUsers, enableGPUManagement: $enableGPUManagement, enableHostManagementFeatures: $enableHostManagementFeatures, gpus: $gpus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Snapshots an environment(endpoint)
#
# POST /endpoints/{id}/snapshot
# operationId: EndpointSnapshot
export def "endpoints-snapshot EndpointSnapshot" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($id)/snapshot")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or retrieve the endpoint for an EdgeID
#
# POST /endpoints/global-key
# operationId: EndpointCreateGlobalKey
export def "endpoints-global-key EndpointCreateGlobalKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<endpointID: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/endpoints/global-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update relations for a list of environments
#
# PUT /endpoints/relations
# operationId: EndpointUpdateRelations
export def "endpoints-relations EndpointUpdateRelations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --relations: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/endpoints/relations")
  let body = {relations: $relations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Snapshot all environments(endpoints)
#
# POST /endpoints/snapshot
# operationId: EndpointSnapshots
export def "endpoints-snapshot EndpointSnapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/endpoints/snapshot")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Portainer's FDO capabilities
#
# POST /fdo
# operationId: fdoConfigure
export def "fdo fdoConfigure" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: oneof<nothing, bool>
  --ownerPassword: string
  --ownerURL: string
  --ownerUsername: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fdo")
  let body = {enabled: $enabled, ownerPassword: $ownerPassword, ownerURL: $ownerURL, ownerUsername: $ownerUsername} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# configures an FDO device
#
# POST /fdo/configure/{guid}
# operationId: fdoConfigureDevice
export def "fdo-configure fdoConfigureDevice" [
  guid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --edgeID: string
  --edgeKey: string
  --name: string
  --profile: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fdo/configure/($guid)")
  let body = {edgeID: $edgeID, edgeKey: $edgeKey, name: $name, profile: $profile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all known FDO vouchers
#
# GET /fdo/list
# operationId: fdoListAll
export def "fdo-list fdoListAll" [
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
  let full_url = (build-url $base "/fdo/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# retrieves all FDO profiles
#
# GET /fdo/profiles
# operationId: fdoProfileList
export def "fdo-profiles fdoProfileList" [
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
  let full_url = (build-url $base "/fdo/profiles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# creates a new FDO Profile
#
# POST /fdo/profiles
# operationId: createProfile
export def "fdo-profiles createProfile" [
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
  let full_url = (build-url $base "/fdo/profiles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# deletes a FDO Profile
#
# DELETE /fdo/profiles/{id}
# operationId: deleteProfile
export def "fdo-profiles delete" [
  id: int
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
  let full_url = (build-url $base $"/fdo/profiles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# retrieves a given FDO profile information and content
#
# GET /fdo/profiles/{id}
# operationId: fdoProfileInspect
export def "fdo-profiles fdoProfileInspect" [
  id: int
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
  let full_url = (build-url $base $"/fdo/profiles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# updates an existing FDO Profile
#
# PUT /fdo/profiles/{id}
# operationId: updateProfile
export def "fdo-profiles updateProfile" [
  id: int
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
  let full_url = (build-url $base $"/fdo/profiles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# duplicated an existing FDO Profile
#
# POST /fdo/profiles/{id}/duplicate
# operationId: duplicate
export def "fdo-profiles-duplicate duplicate" [
  id: int
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
  let full_url = (build-url $base $"/fdo/profiles/($id)/duplicate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# register an FDO device
#
# POST /fdo/register
# operationId: fdoRegisterDevice
export def "fdo-register fdoRegisterDevice" [
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
  let full_url = (build-url $base "/fdo/register")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# preview the content of target file in the git repository
#
# POST /gitops/repo/file/preview
# operationId: GitOperationRepoFilePreview
export def "gitops-repo-file-preview GitOperationRepoFilePreview" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --password: string # e.g. myGitPassword
  --reference: string # e.g. refs/heads/master
  repository: string # e.g. https://github.com/openfaas/faas
  --targetFile: string # Path to file whose content will be read (e.g. docker-compose.yml)
  --tlsskipVerify: oneof<nothing, bool> # TLSSkipVerify skips SSL verification when cloning the Git repository (e.g. false)
  --username: string # e.g. myGitUsername
]: any -> record<fileContent: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gitops/repo/file/preview")
  let body = {password: $password, reference: $reference, repository: $repository, targetFile: $targetFile, tlsskipVerify: $tlsskipVerify, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of ingress controllers
#
# GET /kubernetes/{id}/ingresscontrollers
# operationId: getKubernetesIngressControllers
export def "kubernetes-ingresscontrollers get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowedOnly: oneof<nothing, bool> # Only return allowed ingress controllers
]: nothing -> table<Availability: bool, ClassName: string, Name: string, New: bool, Type: string, Used: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowedOnly" $allowedOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/kubernetes/($id)/ingresscontrollers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update (block/unblock) ingress controllers
#
# PUT /kubernetes/{id}/ingresscontrollers
# operationId: updateKubernetesIngressControllers
export def "kubernetes-ingresscontrollers updateKubernetesIngressControllers" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/ingresscontrollers")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete kubernetes ingresses
#
# POST /kubernetes/{id}/ingresses/delete
# operationId: deleteKubernetesIngresses
export def "kubernetes-ingresses-delete post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/ingresses/delete")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of nodes with their live metrics
#
# GET /kubernetes/{id}/metrics/nodes
# operationId: getKubernetesMetricsForAllNodes
export def "kubernetes-metrics-nodes list" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<apiVersion: string, continue: string, items: table<annotations: record, apiVersion: string, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list, generateName: string, generation: int, kind: string, labels: record, managedFields: list, name: string, namespace: string, ownerReferences: list, resourceVersion: string, selfLink: string, timestamp: string, uid: string, usage: record, window: record>, kind: string, remainingItemCount: int, resourceVersion: string, selfLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/metrics/nodes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get live metrics for a node
#
# GET /kubernetes/{id}/metrics/nodes/{name}
# operationId: getKubernetesMetricsForNode
export def "kubernetes-metrics-nodes get" [
  id: int
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<annotations: record, apiVersion: string, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, kind: string, labels: record, managedFields: table<apiVersion: string, fieldsType: string, fieldsV1: record, manager: string, operation: string, subresource: string, time: string>, name: string, namespace: string, ownerReferences: table<apiVersion: string, blockOwnerDeletion: bool, controller: bool, kind: string, name: string, uid: string>, resourceVersion: string, selfLink: string, timestamp: string, uid: string, usage: record, window: record<time_Duration: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/metrics/nodes/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of pods with their live metrics
#
# GET /kubernetes/{id}/metrics/pods/{namespace}
# operationId: getKubernetesMetricsForAllPods
export def "kubernetes-metrics-pods list" [
  id: int
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<apiVersion: string, continue: string, items: table<annotations: record, apiVersion: string, containers: list, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list, generateName: string, generation: int, kind: string, labels: record, managedFields: list, name: string, namespace: string, ownerReferences: list, resourceVersion: string, selfLink: string, timestamp: string, uid: string, window: record>, kind: string, remainingItemCount: int, resourceVersion: string, selfLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/metrics/pods/($namespace)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get live metrics for a pod
#
# GET /kubernetes/{id}/metrics/pods/{namespace}/{name}
# operationId: getKubernetesMetricsForPod
export def "kubernetes-metrics-pods get" [
  id: int
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<annotations: record, apiVersion: string, containers: table<name: string, usage: record>, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, kind: string, labels: record, managedFields: table<apiVersion: string, fieldsType: string, fieldsV1: record, manager: string, operation: string, subresource: string, time: string>, name: string, namespace: string, ownerReferences: table<apiVersion: string, blockOwnerDeletion: bool, controller: bool, kind: string, name: string, uid: string>, resourceVersion: string, selfLink: string, timestamp: string, uid: string, window: record<time_Duration: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/metrics/pods/($namespace)/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of kubernetes namespaces
#
# GET /kubernetes/{id}/namespaces
# operationId: getKubernetesNamespaces
export def "kubernetes-namespaces list" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/namespaces")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a kubernetes namespace
#
# POST /kubernetes/{id}/namespaces
# operationId: createKubernetesNamespace
# --ResourceQuota shape: {cpu?: string, enabled?: bool, memory?: string}
export def "kubernetes-namespaces createKubernetesNamespace" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Annotations: record
  --Name: string
  --Owner: string
  --ResourceQuota: record # shape: {cpu?: string, enabled?: bool, memory?: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/namespaces")
  let body = {Annotations: $Annotations, Name: $Name, Owner: $Owner, ResourceQuota: $ResourceQuota} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete kubernetes namespace
#
# DELETE /kubernetes/{id}/namespaces/{namespace}
# operationId: deleteKubernetesNamespace
export def "kubernetes-namespaces delete" [
  id: int
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/namespaces/($namespace)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get kubernetes namespace details
#
# GET /kubernetes/{id}/namespaces/{namespace}
# operationId: getKubernetesNamespace
export def "kubernetes-namespaces get" [
  id: int
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<IsDefault: bool, IsSystem: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/namespaces/($namespace)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a kubernetes namespace
#
# PUT /kubernetes/{id}/namespaces/{namespace}
# operationId: updateKubernetesNamespace
# --ResourceQuota shape: {cpu?: string, enabled?: bool, memory?: string}
export def "kubernetes-namespaces updateKubernetesNamespace" [
  id: int
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Annotations: record
  --Name: string
  --Owner: string
  --ResourceQuota: record # shape: {cpu?: string, enabled?: bool, memory?: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/namespaces/($namespace)")
  let body = {Annotations: $Annotations, Name: $Name, Owner: $Owner, ResourceQuota: $ResourceQuota} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get ConfigMaps and Secrets
#
# GET /kubernetes/{id}/namespaces/{namespace}/configuration
# DEPRECATED
# operationId: getKubernetesConfigMapsAndSecrets
@deprecated
export def "kubernetes-namespaces-configuration get" [
  id: int
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<table<Annotations: record, Applications: list, CreationDate: string, Data: record, IsSecret: bool, Name: string, Namespace: string, SecretType: string, UID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/namespaces/($namespace)/configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list ingress controllers by namespace
#
# GET /kubernetes/{id}/namespaces/{namespace}/ingresscontrollers
# operationId: getKubernetesIngressControllersByNamespace
export def "kubernetes-namespaces-ingresscontrollers get" [
  id: int
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<Availability: bool, ClassName: string, Name: string, New: bool, Type: string, Used: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/namespaces/($namespace)/ingresscontrollers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update (block/unblock) ingress controllers by namespace
#
# PUT /kubernetes/{id}/namespaces/{namespace}/ingresscontrollers
# operationId: updateKubernetesIngressControllersByNamespace
export def "kubernetes-namespaces-ingresscontrollers updateKubernetesIngressControllersByNamespace" [
  id: int
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/namespaces/($namespace)/ingresscontrollers")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get kubernetes ingresses by namespace
#
# GET /kubernetes/{id}/namespaces/{namespace}/ingresses
# operationId: getKubernetesIngresses
export def "kubernetes-namespaces-ingresses get" [
  id: int
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/namespaces/($namespace)/ingresses")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a kubernetes ingress by namespace
#
# POST /kubernetes/{id}/namespaces/{namespace}/ingresses
# operationId: createKubernetesIngress
# --Paths item shape: {Host?: string, IngressName?: string, Path?: string, PathType?: string, Port?: int, ServiceName?: string}
# --TLS item shape: {Hosts?: list, SecretName?: string}
export def "kubernetes-namespaces-ingresses createKubernetesIngress" [
  id: int
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Annotations: record
  --ClassName: string
  --CreationDate: string
  --Hosts: list
  --Labels: record
  --Name: string
  --Namespace: string
  --Paths: list # item shape: {Host?: string, IngressName?: string, Path?: string, PathType?: string, Port?: int, ServiceName?: string}
  --TLS: list # item shape: {Hosts?: list, SecretName?: string}
  --Type: string
  --UID: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/namespaces/($namespace)/ingresses")
  let body = {Annotations: $Annotations, ClassName: $ClassName, CreationDate: $CreationDate, Hosts: $Hosts, Labels: $Labels, Name: $Name, Namespace: $Namespace, Paths: $Paths, TLS: $TLS, Type: $Type, UID: $UID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update kubernetes ingress rule
#
# PUT /kubernetes/{id}/namespaces/{namespace}/ingresses
# operationId: updateKubernetesIngress
# --Paths item shape: {Host?: string, IngressName?: string, Path?: string, PathType?: string, Port?: int, ServiceName?: string}
# --TLS item shape: {Hosts?: list, SecretName?: string}
export def "kubernetes-namespaces-ingresses updateKubernetesIngress" [
  id: int
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Annotations: record
  --ClassName: string
  --CreationDate: string
  --Hosts: list
  --Labels: record
  --Name: string
  --Namespace: string
  --Paths: list # item shape: {Host?: string, IngressName?: string, Path?: string, PathType?: string, Port?: int, ServiceName?: string}
  --TLS: list # item shape: {Hosts?: list, SecretName?: string}
  --Type: string
  --UID: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/namespaces/($namespace)/ingresses")
  let body = {Annotations: $Annotations, ClassName: $ClassName, CreationDate: $CreationDate, Hosts: $Hosts, Labels: $Labels, Name: $Name, Namespace: $Namespace, Paths: $Paths, TLS: $TLS, Type: $Type, UID: $UID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of kubernetes services for a given namespace
#
# GET /kubernetes/{id}/namespaces/{namespace}/services
# operationId: getKubernetesServices
export def "kubernetes-namespaces-services get" [
  id: int
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lookupapplications: oneof<nothing, bool> # Lookup applications associated with each service
]: nothing -> table<allocateLoadBalancerNodePorts: bool, annotations: record, applications: list<record>, clusterIPs: list<string>, creationTimestamp: string, externalIPs: list<string>, externalName: string, ingressStatus: list<record>, labels: record, name: string, namespace: string, ports: list<record>, selector: record, type: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lookupapplications" $lookupapplications "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/kubernetes/($id)/namespaces/($namespace)/services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a kubernetes service
#
# POST /kubernetes/{id}/namespaces/{namespace}/services
# operationId: createKubernetesService
# --applications item shape: {kind?: string, labels?: record, name?: string, namespace?: string, uid?: string}
# --ingressStatus item shape: {Host?: string, IP?: string}
# --ports item shape: {Name?: string, NodePort?: int, Port?: int, Protocol?: string, TargetPort?: string}
export def "kubernetes-namespaces-services createKubernetesService" [
  id: int
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allocateLoadBalancerNodePorts: oneof<nothing, bool>
  --annotations: record
  --applications: list # serviceList screen — item shape: {kind?: string, labels?: record, name?: string, namespace?: string, uid?: string}
  --clusterIPs: list
  --creationTimestamp: string
  --externalIPs: list
  --externalName: string
  --ingressStatus: list # item shape: {Host?: string, IP?: string}
  --labels: record
  --name: string
  --body-namespace: string
  --ports: list # item shape: {Name?: string, NodePort?: int, Port?: int, Protocol?: string, TargetPort?: string}
  --selector: record
  --type: string
  --uid: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/namespaces/($namespace)/services")
  let body = {allocateLoadBalancerNodePorts: $allocateLoadBalancerNodePorts, annotations: $annotations, applications: $applications, clusterIPs: $clusterIPs, creationTimestamp: $creationTimestamp, externalIPs: $externalIPs, externalName: $externalName, ingressStatus: $ingressStatus, labels: $labels, name: $name, namespace: $body_namespace, ports: $ports, selector: $selector, type: $type, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a kubernetes service
#
# PUT /kubernetes/{id}/namespaces/{namespace}/services
# operationId: updateKubernetesService
# --applications item shape: {kind?: string, labels?: record, name?: string, namespace?: string, uid?: string}
# --ingressStatus item shape: {Host?: string, IP?: string}
# --ports item shape: {Name?: string, NodePort?: int, Port?: int, Protocol?: string, TargetPort?: string}
export def "kubernetes-namespaces-services updateKubernetesService" [
  id: int
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allocateLoadBalancerNodePorts: oneof<nothing, bool>
  --annotations: record
  --applications: list # serviceList screen — item shape: {kind?: string, labels?: record, name?: string, namespace?: string, uid?: string}
  --clusterIPs: list
  --creationTimestamp: string
  --externalIPs: list
  --externalName: string
  --ingressStatus: list # item shape: {Host?: string, IP?: string}
  --labels: record
  --name: string
  --body-namespace: string
  --ports: list # item shape: {Name?: string, NodePort?: int, Port?: int, Protocol?: string, TargetPort?: string}
  --selector: record
  --type: string
  --uid: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/namespaces/($namespace)/services")
  let body = {allocateLoadBalancerNodePorts: $allocateLoadBalancerNodePorts, annotations: $annotations, applications: $applications, clusterIPs: $clusterIPs, creationTimestamp: $creationTimestamp, externalIPs: $externalIPs, externalName: $externalName, ingressStatus: $ingressStatus, labels: $labels, name: $name, namespace: $body_namespace, ports: $ports, selector: $selector, type: $type, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Toggle the system state for a namespace
#
# PUT /kubernetes/{id}/namespaces/{namespace}/system
# operationId: KubernetesNamespacesToggleSystem
export def "kubernetes-namespaces-system KubernetesNamespacesToggleSystem" [
  id: int
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --system: oneof<nothing, bool> # Toggle the system state of this namespace to true or false (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/namespaces/($namespace)/system")
  let body = {system: $system} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get CPU and memory limits of all nodes within k8s cluster
#
# GET /kubernetes/{id}/nodes_limits
# operationId: GetKubernetesNodesLimits
export def "kubernetes-nodes-limits GetKubernetesNodesLimits" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/nodes_limits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if RBAC is enabled
#
# GET /kubernetes/{id}/rbac_enabled
# operationId: IsRBACEnabled
export def "kubernetes-rbac-enabled IsRBACEnabled" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/rbac_enabled")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete kubernetes services
#
# POST /kubernetes/{id}/services/delete
# operationId: deleteKubernetesServices
export def "kubernetes-services-delete post" [
  id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kubernetes/($id)/services/delete")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a kubeconfig file enabling client communication with k8s api server
#
# GET /kubernetes/config
# operationId: GetKubernetesConfig
export def "kubernetes-config GetKubernetesConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # will include only these environments(endpoints)
  --excludeIds: list # will exclude these environments(endpoints)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "excludeIds" $excludeIds "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/kubernetes/config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test LDAP connectivity
#
# POST /ldap/check
# operationId: LDAPCheck
# --ldapsettings shape: {AnonymousMode?: bool, AutoCreateUsers?: bool, GroupSearchSettings?: list, Password?: string, ReaderDN?: string, SearchSettings?: list, StartTLS?: bool, TLSConfig?: record, URL?: string}
export def "ldap-check LDAPCheck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ldapsettings: record # shape: {AnonymousMode?: bool, AutoCreateUsers?: bool, GroupSearchSettings?: list, Password?: string, ReaderDN?: string, SearchSettings?: list, StartTLS?: bool, TLSConfig?: record, URL?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ldap/check")
  let body = {ldapsettings: $ldapsettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# fetches the message of the day
#
# GET /motd
# operationId: MOTD
export def "motd MOTD" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ContentLayout: record, Hash: list<int>, Message: string, Style: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/motd")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Portainer's OpenAMT capabilities
#
# POST /open_amt
# operationId: OpenAMTConfigure
export def "open-amt OpenAMTConfigure" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --certFileContent: string
  --certFileName: string
  --certFilePassword: string
  --domainName: string
  --enabled: oneof<nothing, bool>
  --mpspassword: string
  --mpsserver: string
  --mpsuser: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/open_amt")
  let body = {certFileContent: $certFileContent, certFileName: $certFileName, certFilePassword: $certFilePassword, domainName: $domainName, enabled: $enabled, mpspassword: $mpspassword, mpsserver: $mpsserver, mpsuser: $mpsuser} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Activate OpenAMT device and associate to agent endpoint
#
# POST /open_amt/{id}/activate
# operationId: openAMTActivate
export def "open-amt-activate openAMTActivate" [
  id: int
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
  let full_url = (build-url $base $"/open_amt/($id)/activate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch OpenAMT managed devices information for endpoint
#
# GET /open_amt/{id}/devices
# operationId: OpenAMTDevices
export def "open-amt-devices OpenAMTDevices" [
  id: int
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
  let full_url = (build-url $base $"/open_amt/($id)/devices")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Execute out of band action on an AMT managed device
#
# POST /open_amt/{id}/devices/{deviceId}/action
# operationId: DeviceAction
export def "open-amt-devices-action DeviceAction" [
  id: int
  deviceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/open_amt/($id)/devices/($deviceId)/action")
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable features on an AMT managed device
#
# POST /open_amt/{id}/devices_features/{deviceId}
# operationId: DeviceFeatures
# --features shape: {IDER?: bool, KVM?: bool, SOL?: bool, redirection?: bool, userConsent?: string}
export def "open-amt-devices-features DeviceFeatures" [
  id: int
  deviceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --features: record # shape: {IDER?: bool, KVM?: bool, SOL?: bool, redirection?: bool, userConsent?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/open_amt/($id)/devices_features/($deviceId)")
  let body = {features: $features} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Request OpenAMT info from a node
#
# GET /open_amt/{id}/info
# operationId: OpenAMTHostInfo
export def "open-amt-info OpenAMTHostInfo" [
  id: int
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
  let full_url = (build-url $base $"/open_amt/($id)/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Registries
#
# GET /registries
# operationId: RegistryList
export def "registries RegistryList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<AccessToken: string, AccessTokenExpiry: int, Authentication: bool, AuthorizedTeams: list<int>, AuthorizedUsers: list<int>, BaseURL: string, Ecr: record<Region: string>, Gitlab: record<InstanceURL: string, ProjectId: int, ProjectPath: string>, Id: int, ManagementConfiguration: record<AccessToken: string, AccessTokenExpiry: int, Authentication: bool, Ecr: record, Password: string, TLSConfig: record, Type: int, Username: string>, Name: string, Password: string, Quay: record<OrganisationName: string, UseOrganisation: bool>, RegistryAccesses: record, TeamAccessPolicies: record, Type: int, URL: string, UserAccessPolicies: record, Username: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/registries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new registry
#
# POST /registries
# operationId: RegistryCreate
# --ecr shape: {Region?: string}
# --gitlab shape: {InstanceURL?: string, ProjectId?: int, ProjectPath?: string}
# --quay shape: {OrganisationName?: string, UseOrganisation?: bool}
export def "registries RegistryCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authentication: oneof<nothing, bool> # Is authentication against this registry enabled (e.g. false)
  --baseURL: string # BaseURL required for ProGet registry (e.g. registry.mydomain.tld:2375)
  --ecr: record # shape: {Region?: string}
  --gitlab: record # shape: {InstanceURL?: string, ProjectId?: int, ProjectPath?: string}
  name: string # Name that will be used to identify this registry (e.g. my-registry)
  --password: string # Password used to authenticate against this registry. required when Authentication is true (e.g. registry_password)
  --quay: record # shape: {OrganisationName?: string, UseOrganisation?: bool}
  type: int@type-completer-2 # Registry Type. Valid values are: 	1 (Quay.io), 	2 (Azure container registry), 	3 (custom registry), 	4 (Gitlab registry), 	5 (ProGet registry), 	6 (DockerHub) 	7 (ECR) (e.g. 1)
  --body-url: string # URL or IP address of the Docker registry (e.g. registry.mydomain.tld:2375/feed)
  --username: string # Username used to authenticate against this registry. Required when Authentication is true (e.g. registry_user)
]: any -> record<AccessToken: string, AccessTokenExpiry: int, Authentication: bool, AuthorizedTeams: list<int>, AuthorizedUsers: list<int>, BaseURL: string, Ecr: record<Region: string>, Gitlab: record<InstanceURL: string, ProjectId: int, ProjectPath: string>, Id: int, ManagementConfiguration: record<AccessToken: string, AccessTokenExpiry: int, Authentication: bool, Ecr: record<Region: string>, Password: string, TLSConfig: record<TLS: bool, TLSCACert: string, TLSCert: string, TLSKey: string, TLSSkipVerify: bool>, Type: int, Username: string>, Name: string, Password: string, Quay: record<OrganisationName: string, UseOrganisation: bool>, RegistryAccesses: record, TeamAccessPolicies: record, Type: int, URL: string, UserAccessPolicies: record, Username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/registries")
  let body = {authentication: $authentication, baseURL: $baseURL, ecr: $ecr, gitlab: $gitlab, name: $name, password: $password, quay: $quay, type: $type, url: $body_url, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a registry
#
# DELETE /registries/{id}
# operationId: RegistryDelete
export def "registries RegistryDelete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/registries/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect a registry
#
# GET /registries/{id}
# operationId: RegistryInspect
export def "registries RegistryInspect" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<AccessToken: string, AccessTokenExpiry: int, Authentication: bool, AuthorizedTeams: list<int>, AuthorizedUsers: list<int>, BaseURL: string, Ecr: record<Region: string>, Gitlab: record<InstanceURL: string, ProjectId: int, ProjectPath: string>, Id: int, ManagementConfiguration: record<AccessToken: string, AccessTokenExpiry: int, Authentication: bool, Ecr: record<Region: string>, Password: string, TLSConfig: record<TLS: bool, TLSCACert: string, TLSCert: string, TLSKey: string, TLSSkipVerify: bool>, Type: int, Username: string>, Name: string, Password: string, Quay: record<OrganisationName: string, UseOrganisation: bool>, RegistryAccesses: record, TeamAccessPolicies: record, Type: int, URL: string, UserAccessPolicies: record, Username: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/registries/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a registry
#
# PUT /registries/{id}
# operationId: RegistryUpdate
# --ecr shape: {Region?: string}
# --quay shape: {OrganisationName?: string, UseOrganisation?: bool}
export def "registries RegistryUpdate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authentication: oneof<nothing, bool> # Is authentication against this registry enabled (e.g. false)
  --baseURL: string # BaseURL is used for quay registry (e.g. registry.mydomain.tld:2375)
  --ecr: record # shape: {Region?: string}
  name: string # Name that will be used to identify this registry (e.g. my-registry)
  --password: string # Password used to authenticate against this registry. required when Authentication is true (e.g. registry_password)
  --quay: record # shape: {OrganisationName?: string, UseOrganisation?: bool}
  --registryAccesses: record
  --body-url: string # URL or IP address of the Docker registry (e.g. registry.mydomain.tld:2375)
  --username: string # Username used to authenticate against this registry. Required when Authentication is true (e.g. registry_user)
]: any -> record<AccessToken: string, AccessTokenExpiry: int, Authentication: bool, AuthorizedTeams: list<int>, AuthorizedUsers: list<int>, BaseURL: string, Ecr: record<Region: string>, Gitlab: record<InstanceURL: string, ProjectId: int, ProjectPath: string>, Id: int, ManagementConfiguration: record<AccessToken: string, AccessTokenExpiry: int, Authentication: bool, Ecr: record<Region: string>, Password: string, TLSConfig: record<TLS: bool, TLSCACert: string, TLSCert: string, TLSKey: string, TLSSkipVerify: bool>, Type: int, Username: string>, Name: string, Password: string, Quay: record<OrganisationName: string, UseOrganisation: bool>, RegistryAccesses: record, TeamAccessPolicies: record, Type: int, URL: string, UserAccessPolicies: record, Username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/registries/($id)")
  let body = {authentication: $authentication, baseURL: $baseURL, ecr: $ecr, name: $name, password: $password, quay: $quay, registryAccesses: $registryAccesses, url: $body_url, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Configures a registry
#
# POST /registries/{id}/configure
# operationId: RegistryConfigure
export def "registries-configure RegistryConfigure" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authentication: oneof<nothing, bool> # Is authentication against this registry enabled (e.g. false)
  --password: string # Password used to authenticate against this registry. required when Authentication is true (e.g. registry_password)
  --region: string # ECR region
  --tls: oneof<nothing, bool> # Use TLS (e.g. true)
  --tlscacertFile: list # The TLS CA certificate file
  --tlscertFile: list # The TLS client certificate file
  --tlskeyFile: list # The TLS client key file
  --tlsskipVerify: oneof<nothing, bool> # Skip the verification of the server TLS certificate (e.g. false)
  --username: string # Username used to authenticate against this registry. Required when Authentication is true (e.g. registry_user)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/registries/($id)/configure")
  let body = {authentication: $authentication, password: $password, region: $region, tls: $tls, tlscacertFile: $tlscacertFile, tlscertFile: $tlscertFile, tlskeyFile: $tlskeyFile, tlsskipVerify: $tlsskipVerify, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new resource control
#
# POST /resource_controls
# operationId: ResourceControlCreate
export def "resource-controls ResourceControlCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --administratorsOnly: oneof<nothing, bool> # Permit access to resource only to admins (e.g. true)
  --public: oneof<nothing, bool> # Permit access to the associated resource to any user (e.g. true)
  resourceID: string # e.g. 617c5f22bb9b023d6daab7cba43a57576f83492867bc767d1c59416b065e5f08
  --subResourceIDs: list # List of Docker resources that will inherit this access control (e.g. [617c5f22bb9b023d6daab7cba43a57576f83492867bc767d1c59416b065e5f08])
  --teams: list # List of team identifiers with access to the associated resource (e.g. [56, 7])
  type: int@type-completer-3 # Type of Resource. Valid values are: 1 - container, 2 - service 3 - volume, 4 - network, 5 - secret, 6 - stack, 7 - config, 8 - custom template, 9 - azure-container-group (e.g. 1)
  --users: list # List of user identifiers with access to the associated resource (e.g. [1, 4])
]: any -> record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: table<AccessLevel: int, TeamId: int>, Type: int, UserAccesses: table<AccessLevel: int, UserId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/resource_controls")
  let body = {administratorsOnly: $administratorsOnly, public: $public, resourceID: $resourceID, subResourceIDs: $subResourceIDs, teams: $teams, type: $type, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a resource control
#
# DELETE /resource_controls/{id}
# operationId: ResourceControlDelete
export def "resource-controls ResourceControlDelete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/resource_controls/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a resource control
#
# PUT /resource_controls/{id}
# operationId: ResourceControlUpdate
export def "resource-controls ResourceControlUpdate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --administratorsOnly: oneof<nothing, bool> # Permit access to resource only to admins (e.g. true)
  --public: oneof<nothing, bool> # Permit access to the associated resource to any user (e.g. true)
  --teams: list # List of team identifiers with access to the associated resource (e.g. [7])
  --users: list # List of user identifiers with access to the associated resource (e.g. [4])
]: any -> record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: table<AccessLevel: int, TeamId: int>, Type: int, UserAccesses: table<AccessLevel: int, UserId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/resource_controls/($id)")
  let body = {administratorsOnly: $administratorsOnly, public: $public, teams: $teams, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Triggers a system restore using provided backup file
#
# POST /restore
# operationId: Restore
export def "restore Restore" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fileContent: list
  --fileName: string
  --password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restore")
  let body = {fileContent: $fileContent, fileName: $fileName, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List roles
#
# GET /roles
# operationId: RoleList
export def "roles RoleList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<Authorizations: record, Description: string, Id: int, Name: string, Priority: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Portainer settings
#
# GET /settings
# operationId: SettingsInspect
export def "settings SettingsInspect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<AgentSecret: string, AllowBindMountsForRegularUsers: bool, AllowContainerCapabilitiesForRegularUsers: bool, AllowDeviceMappingForRegularUsers: bool, AllowHostNamespaceForRegularUsers: bool, AllowPrivilegedModeForRegularUsers: bool, AllowStackManagementForRegularUsers: bool, AllowVolumeBrowserForRegularUsers: bool, AuthenticationMethod: int, BlackListedLabels: table<name: string, value: string>, DisplayDonationHeader: bool, DisplayExternalContributors: bool, EdgeAgentCheckinInterval: int, EdgePortainerUrl: string, EnableEdgeComputeFeatures: bool, EnableHostManagementFeatures: bool, EnableTelemetry: bool, EnforceEdgeID: bool, FeatureFlagSettings: record, GlobalDeploymentOptions: record<hideStacksFunctionality: bool>, HelmRepositoryURL: string, InternalAuthSettings: record<requiredPasswordLength: int>, IsDockerDesktopExtension: bool, KubeconfigExpiry: string, KubectlShellImage: string, LDAPSettings: record<AnonymousMode: bool, AutoCreateUsers: bool, GroupSearchSettings: list<record>, Password: string, ReaderDN: string, SearchSettings: list<record>, StartTLS: bool, TLSConfig: record<TLS: bool, TLSCACert: string, TLSCert: string, TLSKey: string, TLSSkipVerify: bool>, URL: string>, LogoURL: string, OAuthSettings: record<AccessTokenURI: string, AuthorizationURI: string, ClientID: string, ClientSecret: string, DefaultTeamID: int, KubeSecretKey: list<int>, LogoutURI: string, OAuthAutoCreateUsers: bool, RedirectURI: string, ResourceURI: string, SSO: bool, Scopes: string, UserIdentifier: string>, ShowKomposeBuildOption: bool, SnapshotInterval: string, TemplatesURL: string, TrustOnFirstConnect: bool, UserSessionTimeout: string, edge: record<CommandInterval: int, PingInterval: int, SnapshotInterval: int, asyncMode: bool>, fdoConfiguration: record<enabled: bool, ownerPassword: string, ownerURL: string, ownerUsername: string>, openAMTConfiguration: record<certFileContent: string, certFileName: string, certFilePassword: string, domainName: string, enabled: bool, mpsPassword: string, mpsServer: string, mpsToken: string, mpsUser: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Portainer settings
#
# PUT /settings
# operationId: SettingsUpdate
# --blackListedLabels item shape: {name?: string, value?: string}
# --globalDeploymentOptions shape: {hideStacksFunctionality?: bool}
# --internalAuthSettings shape: {requiredPasswordLength?: int}
# --ldapsettings shape: {AnonymousMode?: bool, AutoCreateUsers?: bool, GroupSearchSettings?: list, Password?: string, ReaderDN?: string, SearchSettings?: list, StartTLS?: bool, TLSConfig?: record, URL?: string}
# --oauthSettings shape: {AccessTokenURI?: string, AuthorizationURI?: string, ClientID?: string, ClientSecret?: string, DefaultTeamID?: int, KubeSecretKey?: list, LogoutURI?: string, OAuthAutoCreateUsers?: bool, RedirectURI?: string, ResourceURI?: string, SSO?: bool, Scopes?: string, UserIdentifier?: string}
export def "settings SettingsUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --EdgePortainerURL: string # EdgePortainerURL is the URL that is exposed to edge agents
  --ShowKomposeBuildOption: oneof<nothing, bool> # Show the Kompose build option (discontinued in 2.18) (e.g. false)
  --authenticationMethod: int # Active authentication method for the Portainer instance. Valid values are: 1 for internal, 2 for LDAP, or 3 for oauth (e.g. 1)
  --blackListedLabels: list # A list of label name & value that will be used to hide containers when querying containers — item shape: {name?: string, value?: string}
  --edgeAgentCheckinInterval: int # e.g. 5
  --enableEdgeComputeFeatures: oneof<nothing, bool> # Whether edge compute features are enabled (e.g. true)
  --enableTelemetry: oneof<nothing, bool> # Whether telemetry is enabled (e.g. false)
  --enforceEdgeID: oneof<nothing, bool> # EnforceEdgeID makes Portainer store the Edge ID instead of accepting anyone (e.g. false)
  --globalDeploymentOptions: record # shape: {hideStacksFunctionality?: bool}
  --helmRepositoryURL: string # Helm repository URL (e.g. https://charts.bitnami.com/bitnami)
  --internalAuthSettings: record # shape: {requiredPasswordLength?: int}
  --kubeconfigExpiry: string # The expiry of a Kubeconfig (default: 0, e.g. 24h)
  --kubectlShellImage: string # Kubectl Shell Image (e.g. portainer/kubectl-shell:latest)
  --ldapsettings: record # shape: {AnonymousMode?: bool, AutoCreateUsers?: bool, GroupSearchSettings?: list, Password?: string, ReaderDN?: string, SearchSettings?: list, StartTLS?: bool, TLSConfig?: record, URL?: string}
  --logoURL: string # URL to a logo that will be displayed on the login page as well as on top of the sidebar. Will use default Portainer logo when value is empty string (e.g. https://mycompany.mydomain.tld/logo.png)
  --oauthSettings: record # shape: {AccessTokenURI?: string, AuthorizationURI?: string, ClientID?: string, ClientSecret?: string, DefaultTeamID?: int, KubeSecretKey?: list, LogoutURI?: string, OAuthAutoCreateUsers?: bool, RedirectURI?: string, ResourceURI?: string, SSO?: bool, Scopes?: string, UserIdentifier?: string}
  --snapshotInterval: string # The interval in which environment(endpoint) snapshots are created (e.g. 5m)
  --templatesURL: string # URL to the templates that will be displayed in the UI when navigating to App Templates (e.g. https://raw.githubusercontent.com/portainer/templates/master/templates.json)
  --trustOnFirstConnect: oneof<nothing, bool> # TrustOnFirstConnect makes Portainer accepting edge agent connection by default (e.g. false)
  --userSessionTimeout: string # The duration of a user session (e.g. 5m)
]: any -> record<AgentSecret: string, AllowBindMountsForRegularUsers: bool, AllowContainerCapabilitiesForRegularUsers: bool, AllowDeviceMappingForRegularUsers: bool, AllowHostNamespaceForRegularUsers: bool, AllowPrivilegedModeForRegularUsers: bool, AllowStackManagementForRegularUsers: bool, AllowVolumeBrowserForRegularUsers: bool, AuthenticationMethod: int, BlackListedLabels: table<name: string, value: string>, DisplayDonationHeader: bool, DisplayExternalContributors: bool, EdgeAgentCheckinInterval: int, EdgePortainerUrl: string, EnableEdgeComputeFeatures: bool, EnableHostManagementFeatures: bool, EnableTelemetry: bool, EnforceEdgeID: bool, FeatureFlagSettings: record, GlobalDeploymentOptions: record<hideStacksFunctionality: bool>, HelmRepositoryURL: string, InternalAuthSettings: record<requiredPasswordLength: int>, IsDockerDesktopExtension: bool, KubeconfigExpiry: string, KubectlShellImage: string, LDAPSettings: record<AnonymousMode: bool, AutoCreateUsers: bool, GroupSearchSettings: list<record>, Password: string, ReaderDN: string, SearchSettings: list<record>, StartTLS: bool, TLSConfig: record<TLS: bool, TLSCACert: string, TLSCert: string, TLSKey: string, TLSSkipVerify: bool>, URL: string>, LogoURL: string, OAuthSettings: record<AccessTokenURI: string, AuthorizationURI: string, ClientID: string, ClientSecret: string, DefaultTeamID: int, KubeSecretKey: list<int>, LogoutURI: string, OAuthAutoCreateUsers: bool, RedirectURI: string, ResourceURI: string, SSO: bool, Scopes: string, UserIdentifier: string>, ShowKomposeBuildOption: bool, SnapshotInterval: string, TemplatesURL: string, TrustOnFirstConnect: bool, UserSessionTimeout: string, edge: record<CommandInterval: int, PingInterval: int, SnapshotInterval: int, asyncMode: bool>, fdoConfiguration: record<enabled: bool, ownerPassword: string, ownerURL: string, ownerUsername: string>, openAMTConfiguration: record<certFileContent: string, certFileName: string, certFilePassword: string, domainName: string, enabled: bool, mpsPassword: string, mpsServer: string, mpsToken: string, mpsUser: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings")
  let body = {EdgePortainerURL: $EdgePortainerURL, ShowKomposeBuildOption: $ShowKomposeBuildOption, authenticationMethod: $authenticationMethod, blackListedLabels: $blackListedLabels, edgeAgentCheckinInterval: $edgeAgentCheckinInterval, enableEdgeComputeFeatures: $enableEdgeComputeFeatures, enableTelemetry: $enableTelemetry, enforceEdgeID: $enforceEdgeID, globalDeploymentOptions: $globalDeploymentOptions, helmRepositoryURL: $helmRepositoryURL, internalAuthSettings: $internalAuthSettings, kubeconfigExpiry: $kubeconfigExpiry, kubectlShellImage: $kubectlShellImage, ldapsettings: $ldapsettings, logoURL: $logoURL, oauthSettings: $oauthSettings, snapshotInterval: $snapshotInterval, templatesURL: $templatesURL, trustOnFirstConnect: $trustOnFirstConnect, userSessionTimeout: $userSessionTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Portainer public settings
#
# GET /settings/public
# operationId: SettingsPublic
export def "settings-public SettingsPublic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<AuthenticationMethod: int, EnableEdgeComputeFeatures: bool, EnableTelemetry: bool, Features: record, GlobalDeploymentOptions: record<hideStacksFunctionality: bool>, IsDockerDesktopExtension: bool, LogoURL: string, OAuthLoginURI: string, OAuthLogoutURI: string, RequiredPasswordLength: int, ShowKomposeBuildOption: bool, TeamSync: bool, edge: record<CommandInterval: int, PingInterval: int, SnapshotInterval: int, checkinInterval: int>, isAMTEnabled: bool, isFDOEnabled: bool, kubeconfigExpiry: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/public")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect the ssl settings
#
# GET /ssl
# operationId: SSLInspect
export def "ssl SSLInspect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<certPath: string, httpEnabled: bool, keyPath: string, selfSigned: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ssl")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the ssl settings
#
# PUT /ssl
# operationId: SSLUpdate
export def "ssl SSLUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cert: string # SSL Certificates
  --httpenabled: oneof<nothing, bool>
  --key: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ssl")
  let body = {cert: $cert, httpenabled: $httpenabled, key: $key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List stacks
#
# GET /stacks
# operationId: StackList
export def "stacks StackList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filters: string # Filters to process on the stack list. Encoded as JSON (a map[string]string). For example, {'SwarmID': 'jpofkc0i9uo9wtx1zesuk649w'} will only return stacks that are part of the specified Swarm cluster. Available filters: EndpointID, SwarmID.
]: nothing -> table<AdditionalFiles: list<string>, AutoUpdate: record<forcePullImage: bool, forceUpdate: bool, interval: string, jobID: string, webhook: string>, EndpointId: int, EntryPoint: string, Env: list<record>, Id: int, Name: string, Option: record<prune: bool>, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list, System: bool, TeamAccesses: list, Type: int, UserAccesses: list>, Status: int, SwarmId: string, Type: int, createdBy: string, creationDate: int, fromAppTemplate: bool, gitConfig: record<authentication: record, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, isComposeFormat: bool, namespace: string, projectPath: string, updateDate: int, updatedBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stacks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deploy a new stack
#
# POST /stacks
# DEPRECATED
# operationId: StackCreate
@deprecated
export def "stacks StackCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: int@type-completer # Stack deployment type. Possible values: 1 (Swarm stack), 2 (Compose stack) or 3 (Kubernetes stack).
  --method: string@method-completer-2 # Stack deployment method. Possible values: file, string, repository or url.
  --endpointId: int # Identifier of the environment(endpoint) that will be used to deploy the stack
  --body: record
]: any -> record<AdditionalFiles: list<string>, AutoUpdate: record<forcePullImage: bool, forceUpdate: bool, interval: string, jobID: string, webhook: string>, EndpointId: int, EntryPoint: string, Env: table<name: string, value: string>, Id: int, Name: string, Option: record<prune: bool>, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Status: int, SwarmId: string, Type: int, createdBy: string, creationDate: int, fromAppTemplate: bool, gitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, isComposeFormat: bool, namespace: string, projectPath: string, updateDate: int, updatedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "method" $method "scalar") (serialize-qp "endpointId" $endpointId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stacks" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a stack
#
# DELETE /stacks/{id}
# operationId: StackDelete
export def "stacks StackDelete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --external: oneof<nothing, bool> # Set to true to delete an external stack. Only external Swarm stacks are supported
  --endpointId: int # Environment identifier
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "external" $external "scalar") (serialize-qp "endpointId" $endpointId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stacks/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect a stack
#
# GET /stacks/{id}
# operationId: StackInspect
export def "stacks StackInspect" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<AdditionalFiles: list<string>, AutoUpdate: record<forcePullImage: bool, forceUpdate: bool, interval: string, jobID: string, webhook: string>, EndpointId: int, EntryPoint: string, Env: table<name: string, value: string>, Id: int, Name: string, Option: record<prune: bool>, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Status: int, SwarmId: string, Type: int, createdBy: string, creationDate: int, fromAppTemplate: bool, gitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, isComposeFormat: bool, namespace: string, projectPath: string, updateDate: int, updatedBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stacks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a stack
#
# PUT /stacks/{id}
# operationId: StackUpdate
# --env item shape: {name?: string, value?: string}
export def "stacks StackUpdate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # Environment identifier
  --env: list # A list of environment(endpoint) variables used during stack deployment — item shape: {name?: string, value?: string}
  --prune: oneof<nothing, bool> # Prune services that are no longer referenced (only available for Swarm stacks) (e.g. true)
  --pullImage: oneof<nothing, bool> # Force a pulling to current image with the original tag though the image is already the latest (e.g. false)
  --stackFileContent: string # New content of the Stack file (e.g. version: 3  services:  web:  image:nginx)
]: any -> record<AdditionalFiles: list<string>, AutoUpdate: record<forcePullImage: bool, forceUpdate: bool, interval: string, jobID: string, webhook: string>, EndpointId: int, EntryPoint: string, Env: table<name: string, value: string>, Id: int, Name: string, Option: record<prune: bool>, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Status: int, SwarmId: string, Type: int, createdBy: string, creationDate: int, fromAppTemplate: bool, gitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, isComposeFormat: bool, namespace: string, projectPath: string, updateDate: int, updatedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stacks/($id)" $qp)
  let body = {env: $env, prune: $prune, pullImage: $pullImage, stackFileContent: $stackFileContent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Associate an orphaned stack to a new environment(endpoint)
#
# PUT /stacks/{id}/associate
# operationId: StackAssociate
export def "stacks-associate StackAssociate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # Environment identifier
  --swarmId: int # Swarm identifier
  --orphanedRunning: oneof<nothing, bool> # Indicates whether the stack is orphaned
]: nothing -> record<AdditionalFiles: list<string>, AutoUpdate: record<forcePullImage: bool, forceUpdate: bool, interval: string, jobID: string, webhook: string>, EndpointId: int, EntryPoint: string, Env: table<name: string, value: string>, Id: int, Name: string, Option: record<prune: bool>, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Status: int, SwarmId: string, Type: int, createdBy: string, creationDate: int, fromAppTemplate: bool, gitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, isComposeFormat: bool, namespace: string, projectPath: string, updateDate: int, updatedBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar") (serialize-qp "swarmId" $swarmId "scalar") (serialize-qp "orphanedRunning" $orphanedRunning "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stacks/($id)/associate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the content of the Stack file for the specified stack
#
# GET /stacks/{id}/file
# operationId: StackFileInspect
export def "stacks-file StackFileInspect" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<StackFileContent: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stacks/($id)/file")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a stack's Git configs
#
# POST /stacks/{id}/git
# operationId: StackUpdateGit
# --autoUpdate shape: {forcePullImage?: bool, forceUpdate?: bool, interval?: string, jobID?: string, webhook?: string}
# --env item shape: {name?: string, value?: string}
export def "stacks-git StackUpdateGit" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # Stacks created before version 1.18.0 might not have an associated environment(endpoint) identifier. Use this optional parameter to set the environment(endpoint) identifier used by the stack.
  --autoUpdate: record # shape: {forcePullImage?: bool, forceUpdate?: bool, interval?: string, jobID?: string, webhook?: string}
  --env: list # item shape: {name?: string, value?: string}
  --prune: oneof<nothing, bool>
  --repositoryAuthentication: oneof<nothing, bool>
  --repositoryPassword: string
  --repositoryReferenceName: string
  --repositoryUsername: string
  --tlsskipVerify: oneof<nothing, bool>
]: any -> record<AdditionalFiles: list<string>, AutoUpdate: record<forcePullImage: bool, forceUpdate: bool, interval: string, jobID: string, webhook: string>, EndpointId: int, EntryPoint: string, Env: table<name: string, value: string>, Id: int, Name: string, Option: record<prune: bool>, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Status: int, SwarmId: string, Type: int, createdBy: string, creationDate: int, fromAppTemplate: bool, gitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, isComposeFormat: bool, namespace: string, projectPath: string, updateDate: int, updatedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stacks/($id)/git" $qp)
  let body = {autoUpdate: $autoUpdate, env: $env, prune: $prune, repositoryAuthentication: $repositoryAuthentication, repositoryPassword: $repositoryPassword, repositoryReferenceName: $repositoryReferenceName, repositoryUsername: $repositoryUsername, tlsskipVerify: $tlsskipVerify} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Redeploy a stack
#
# PUT /stacks/{id}/git/redeploy
# operationId: StackGitRedeploy
# --env item shape: {name?: string, value?: string}
export def "stacks-git-redeploy StackGitRedeploy" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # Stacks created before version 1.18.0 might not have an associated environment(endpoint) identifier. Use this optional parameter to set the environment(endpoint) identifier used by the stack.
  --env: list # item shape: {name?: string, value?: string}
  --prune: oneof<nothing, bool>
  --pullImage: oneof<nothing, bool> # Force a pulling to current image with the original tag though the image is already the latest (e.g. false)
  --repositoryAuthentication: oneof<nothing, bool>
  --repositoryPassword: string
  --repositoryReferenceName: string
  --repositoryUsername: string
  --stackName: string
]: any -> record<AdditionalFiles: list<string>, AutoUpdate: record<forcePullImage: bool, forceUpdate: bool, interval: string, jobID: string, webhook: string>, EndpointId: int, EntryPoint: string, Env: table<name: string, value: string>, Id: int, Name: string, Option: record<prune: bool>, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Status: int, SwarmId: string, Type: int, createdBy: string, creationDate: int, fromAppTemplate: bool, gitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, isComposeFormat: bool, namespace: string, projectPath: string, updateDate: int, updatedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stacks/($id)/git/redeploy" $qp)
  let body = {env: $env, prune: $prune, pullImage: $pullImage, repositoryAuthentication: $repositoryAuthentication, repositoryPassword: $repositoryPassword, repositoryReferenceName: $repositoryReferenceName, repositoryUsername: $repositoryUsername, stackName: $stackName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Migrate a stack to another environment(endpoint)
#
# POST /stacks/{id}/migrate
# operationId: StackMigrate
export def "stacks-migrate StackMigrate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # Stacks created before version 1.18.0 might not have an associated environment(endpoint) identifier. Use this optional parameter to set the environment(endpoint) identifier used by the stack.
  endpointID: int # Environment(Endpoint) identifier of the target environment(endpoint) where the stack will be relocated (e.g. 2)
  --name: string # If provided will rename the migrated stack (e.g. new-stack)
  --swarmID: string # Swarm cluster identifier, must match the identifier of the cluster where the stack will be relocated (e.g. jpofkc0i9uo9wtx1zesuk649w)
]: any -> record<AdditionalFiles: list<string>, AutoUpdate: record<forcePullImage: bool, forceUpdate: bool, interval: string, jobID: string, webhook: string>, EndpointId: int, EntryPoint: string, Env: table<name: string, value: string>, Id: int, Name: string, Option: record<prune: bool>, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Status: int, SwarmId: string, Type: int, createdBy: string, creationDate: int, fromAppTemplate: bool, gitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, isComposeFormat: bool, namespace: string, projectPath: string, updateDate: int, updatedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stacks/($id)/migrate" $qp)
  let body = {endpointID: $endpointID, name: $name, swarmID: $swarmID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Starts a stopped Stack
#
# POST /stacks/{id}/start
# operationId: StackStart
export def "stacks-start StackStart" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # Environment identifier
]: nothing -> record<AdditionalFiles: list<string>, AutoUpdate: record<forcePullImage: bool, forceUpdate: bool, interval: string, jobID: string, webhook: string>, EndpointId: int, EntryPoint: string, Env: table<name: string, value: string>, Id: int, Name: string, Option: record<prune: bool>, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Status: int, SwarmId: string, Type: int, createdBy: string, creationDate: int, fromAppTemplate: bool, gitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, isComposeFormat: bool, namespace: string, projectPath: string, updateDate: int, updatedBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stacks/($id)/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stops a stopped Stack
#
# POST /stacks/{id}/stop
# operationId: StackStop
export def "stacks-stop StackStop" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # Environment identifier
]: nothing -> record<AdditionalFiles: list<string>, AutoUpdate: record<forcePullImage: bool, forceUpdate: bool, interval: string, jobID: string, webhook: string>, EndpointId: int, EntryPoint: string, Env: table<name: string, value: string>, Id: int, Name: string, Option: record<prune: bool>, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Status: int, SwarmId: string, Type: int, createdBy: string, creationDate: int, fromAppTemplate: bool, gitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, isComposeFormat: bool, namespace: string, projectPath: string, updateDate: int, updatedBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stacks/($id)/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deploy a new kubernetes stack from a git repository
#
# POST /stacks/create/kubernetes/repository
# operationId: StackCreateKubernetesGit
# --autoUpdate shape: {forcePullImage?: bool, forceUpdate?: bool, interval?: string, jobID?: string, webhook?: string}
export def "stacks-create-kubernetes-repository StackCreateKubernetesGit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # Identifier of the environment that will be used to deploy the stack
  --additionalFiles: list
  --autoUpdate: record # shape: {forcePullImage?: bool, forceUpdate?: bool, interval?: string, jobID?: string, webhook?: string}
  --composeFormat: oneof<nothing, bool>
  --manifestFile: string
  --namespace: string
  --repositoryAuthentication: oneof<nothing, bool>
  --repositoryPassword: string
  --repositoryReferenceName: string
  --repositoryURL: string
  --repositoryUsername: string
  --stackName: string
  --tlsskipVerify: oneof<nothing, bool> # TLSSkipVerify skips SSL verification when cloning the Git repository (e.g. false)
]: any -> record<AdditionalFiles: list<string>, AutoUpdate: record<forcePullImage: bool, forceUpdate: bool, interval: string, jobID: string, webhook: string>, EndpointId: int, EntryPoint: string, Env: table<name: string, value: string>, Id: int, Name: string, Option: record<prune: bool>, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Status: int, SwarmId: string, Type: int, createdBy: string, creationDate: int, fromAppTemplate: bool, gitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, isComposeFormat: bool, namespace: string, projectPath: string, updateDate: int, updatedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stacks/create/kubernetes/repository" $qp)
  let body = {additionalFiles: $additionalFiles, autoUpdate: $autoUpdate, composeFormat: $composeFormat, manifestFile: $manifestFile, namespace: $namespace, repositoryAuthentication: $repositoryAuthentication, repositoryPassword: $repositoryPassword, repositoryReferenceName: $repositoryReferenceName, repositoryURL: $repositoryURL, repositoryUsername: $repositoryUsername, stackName: $stackName, tlsskipVerify: $tlsskipVerify} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deploy a new kubernetes stack from a file
#
# POST /stacks/create/kubernetes/string
# operationId: StackCreateKubernetesFile
export def "stacks-create-kubernetes-string StackCreateKubernetesFile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # Identifier of the environment that will be used to deploy the stack
  --composeFormat: oneof<nothing, bool>
  --fromAppTemplate: oneof<nothing, bool> # Whether the stack is from a app template (e.g. false)
  --namespace: string
  --stackFileContent: string
  --stackName: string
]: any -> record<AdditionalFiles: list<string>, AutoUpdate: record<forcePullImage: bool, forceUpdate: bool, interval: string, jobID: string, webhook: string>, EndpointId: int, EntryPoint: string, Env: table<name: string, value: string>, Id: int, Name: string, Option: record<prune: bool>, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Status: int, SwarmId: string, Type: int, createdBy: string, creationDate: int, fromAppTemplate: bool, gitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, isComposeFormat: bool, namespace: string, projectPath: string, updateDate: int, updatedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stacks/create/kubernetes/string" $qp)
  let body = {composeFormat: $composeFormat, fromAppTemplate: $fromAppTemplate, namespace: $namespace, stackFileContent: $stackFileContent, stackName: $stackName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deploy a new kubernetes stack from a url
#
# POST /stacks/create/kubernetes/url
# operationId: StackCreateKubernetesUrl
export def "stacks-create-kubernetes-url StackCreateKubernetesUrl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # Identifier of the environment that will be used to deploy the stack
  --composeFormat: oneof<nothing, bool>
  --manifestURL: string
  --namespace: string
  --stackName: string
]: any -> record<AdditionalFiles: list<string>, AutoUpdate: record<forcePullImage: bool, forceUpdate: bool, interval: string, jobID: string, webhook: string>, EndpointId: int, EntryPoint: string, Env: table<name: string, value: string>, Id: int, Name: string, Option: record<prune: bool>, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Status: int, SwarmId: string, Type: int, createdBy: string, creationDate: int, fromAppTemplate: bool, gitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, isComposeFormat: bool, namespace: string, projectPath: string, updateDate: int, updatedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stacks/create/kubernetes/url" $qp)
  let body = {composeFormat: $composeFormat, manifestURL: $manifestURL, namespace: $namespace, stackName: $stackName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deploy a new compose stack from a file
#
# POST /stacks/create/standalone/file
# operationId: StackCreateDockerStandaloneFile
export def "stacks-create-standalone-file StackCreateDockerStandaloneFile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # Identifier of the environment that will be used to deploy the stack
  Name: string # Name of the stack
  --Env: string # Environment variables passed during deployment, represented as a JSON array [{'name': 'name', 'value': 'value'}].
  --file: path # Stack file
]: any -> record<AdditionalFiles: list<string>, AutoUpdate: record<forcePullImage: bool, forceUpdate: bool, interval: string, jobID: string, webhook: string>, EndpointId: int, EntryPoint: string, Env: table<name: string, value: string>, Id: int, Name: string, Option: record<prune: bool>, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Status: int, SwarmId: string, Type: int, createdBy: string, creationDate: int, fromAppTemplate: bool, gitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, isComposeFormat: bool, namespace: string, projectPath: string, updateDate: int, updatedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stacks/create/standalone/file" $qp)
  let body = {Name: $Name, Env: $Env, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Deploy a new compose stack from repository
#
# POST /stacks/create/standalone/repository
# operationId: StackCreateDockerStandaloneRepository
# --autoUpdate shape: {forcePullImage?: bool, forceUpdate?: bool, interval?: string, jobID?: string, webhook?: string}
# --env item shape: {name?: string, value?: string}
export def "stacks-create-standalone-repository StackCreateDockerStandaloneRepository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # Identifier of the environment that will be used to deploy the stack
  --additionalFiles: list # Applicable when deploying with multiple stack files (e.g. [[nz.compose.yml,  uat.compose.yml]])
  --autoUpdate: record # shape: {forcePullImage?: bool, forceUpdate?: bool, interval?: string, jobID?: string, webhook?: string}
  --composeFile: string # Path to the Stack file inside the Git repository (default: docker-compose.yml, e.g. docker-compose.yml)
  --env: list # A list of environment variables used during stack deployment — item shape: {name?: string, value?: string}
  --fromAppTemplate: oneof<nothing, bool> # Whether the stack is from a app template (e.g. false)
  name: string # Name of the stack (e.g. myStack)
  --repositoryAuthentication: oneof<nothing, bool> # Use basic authentication to clone the Git repository (e.g. true)
  --repositoryPassword: string # Password used in basic authentication. Required when RepositoryAuthentication is true. (e.g. myGitPassword)
  --repositoryReferenceName: string # Reference name of a Git repository hosting the Stack file (e.g. refs/heads/master)
  repositoryURL: string # URL of a Git repository hosting the Stack file (e.g. https://github.com/openfaas/faas)
  --repositoryUsername: string # Username used in basic authentication. Required when RepositoryAuthentication is true. (e.g. myGitUsername)
  --tlsskipVerify: oneof<nothing, bool> # TLSSkipVerify skips SSL verification when cloning the Git repository (e.g. false)
]: any -> record<AdditionalFiles: list<string>, AutoUpdate: record<forcePullImage: bool, forceUpdate: bool, interval: string, jobID: string, webhook: string>, EndpointId: int, EntryPoint: string, Env: table<name: string, value: string>, Id: int, Name: string, Option: record<prune: bool>, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Status: int, SwarmId: string, Type: int, createdBy: string, creationDate: int, fromAppTemplate: bool, gitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, isComposeFormat: bool, namespace: string, projectPath: string, updateDate: int, updatedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stacks/create/standalone/repository" $qp)
  let body = {additionalFiles: $additionalFiles, autoUpdate: $autoUpdate, composeFile: $composeFile, env: $env, fromAppTemplate: $fromAppTemplate, name: $name, repositoryAuthentication: $repositoryAuthentication, repositoryPassword: $repositoryPassword, repositoryReferenceName: $repositoryReferenceName, repositoryURL: $repositoryURL, repositoryUsername: $repositoryUsername, tlsskipVerify: $tlsskipVerify} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deploy a new compose stack from a text
#
# POST /stacks/create/standalone/string
# operationId: StackCreateDockerStandaloneString
# --env item shape: {name?: string, value?: string}
export def "stacks-create-standalone-string StackCreateDockerStandaloneString" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # Identifier of the environment that will be used to deploy the stack
  --env: list # A list of environment variables used during stack deployment — item shape: {name?: string, value?: string}
  --fromAppTemplate: oneof<nothing, bool> # Whether the stack is from a app template (e.g. false)
  name: string # Name of the stack (e.g. myStack)
  stackFileContent: string # Content of the Stack file (e.g. version: 3  services:  web:  image:nginx)
]: any -> record<AdditionalFiles: list<string>, AutoUpdate: record<forcePullImage: bool, forceUpdate: bool, interval: string, jobID: string, webhook: string>, EndpointId: int, EntryPoint: string, Env: table<name: string, value: string>, Id: int, Name: string, Option: record<prune: bool>, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Status: int, SwarmId: string, Type: int, createdBy: string, creationDate: int, fromAppTemplate: bool, gitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, isComposeFormat: bool, namespace: string, projectPath: string, updateDate: int, updatedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stacks/create/standalone/string" $qp)
  let body = {env: $env, fromAppTemplate: $fromAppTemplate, name: $name, stackFileContent: $stackFileContent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deploy a new swarm stack from a file
#
# POST /stacks/create/swarm/file
# operationId: StackCreateDockerSwarmFile
export def "stacks-create-swarm-file StackCreateDockerSwarmFile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # Identifier of the environment that will be used to deploy the stack
  --Name: string # Name of the stack
  --SwarmID: string # Swarm cluster identifier.
  --Env: string # Environment variables passed during deployment, represented as a JSON array [{'name': 'name', 'value': 'value'}]. Optional
  --file: path # Stack file
]: any -> record<AdditionalFiles: list<string>, AutoUpdate: record<forcePullImage: bool, forceUpdate: bool, interval: string, jobID: string, webhook: string>, EndpointId: int, EntryPoint: string, Env: table<name: string, value: string>, Id: int, Name: string, Option: record<prune: bool>, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Status: int, SwarmId: string, Type: int, createdBy: string, creationDate: int, fromAppTemplate: bool, gitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, isComposeFormat: bool, namespace: string, projectPath: string, updateDate: int, updatedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stacks/create/swarm/file" $qp)
  let body = {Name: $Name, SwarmID: $SwarmID, Env: $Env, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Deploy a new swarm stack from a git repository
#
# POST /stacks/create/swarm/repository
# operationId: StackCreateDockerSwarmRepository
# --autoUpdate shape: {forcePullImage?: bool, forceUpdate?: bool, interval?: string, jobID?: string, webhook?: string}
# --env item shape: {name?: string, value?: string}
export def "stacks-create-swarm-repository StackCreateDockerSwarmRepository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # Identifier of the environment that will be used to deploy the stack
  --additionalFiles: list # Applicable when deploying with multiple stack files (e.g. [[nz.compose.yml,  uat.compose.yml]])
  --autoUpdate: record # shape: {forcePullImage?: bool, forceUpdate?: bool, interval?: string, jobID?: string, webhook?: string}
  --composeFile: string # Path to the Stack file inside the Git repository (default: docker-compose.yml, e.g. docker-compose.yml)
  --env: list # A list of environment variables used during stack deployment — item shape: {name?: string, value?: string}
  --fromAppTemplate: oneof<nothing, bool> # Whether the stack is from a app template (e.g. false)
  name: string # Name of the stack (e.g. myStack)
  --repositoryAuthentication: oneof<nothing, bool> # Use basic authentication to clone the Git repository (e.g. true)
  --repositoryPassword: string # Password used in basic authentication. Required when RepositoryAuthentication is true. (e.g. myGitPassword)
  --repositoryReferenceName: string # Reference name of a Git repository hosting the Stack file (e.g. refs/heads/master)
  repositoryURL: string # URL of a Git repository hosting the Stack file (e.g. https://github.com/openfaas/faas)
  --repositoryUsername: string # Username used in basic authentication. Required when RepositoryAuthentication is true. (e.g. myGitUsername)
  swarmID: string # Swarm cluster identifier (e.g. jpofkc0i9uo9wtx1zesuk649w)
  --tlsskipVerify: oneof<nothing, bool> # TLSSkipVerify skips SSL verification when cloning the Git repository (e.g. false)
]: any -> record<AdditionalFiles: list<string>, AutoUpdate: record<forcePullImage: bool, forceUpdate: bool, interval: string, jobID: string, webhook: string>, EndpointId: int, EntryPoint: string, Env: table<name: string, value: string>, Id: int, Name: string, Option: record<prune: bool>, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Status: int, SwarmId: string, Type: int, createdBy: string, creationDate: int, fromAppTemplate: bool, gitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, isComposeFormat: bool, namespace: string, projectPath: string, updateDate: int, updatedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stacks/create/swarm/repository" $qp)
  let body = {additionalFiles: $additionalFiles, autoUpdate: $autoUpdate, composeFile: $composeFile, env: $env, fromAppTemplate: $fromAppTemplate, name: $name, repositoryAuthentication: $repositoryAuthentication, repositoryPassword: $repositoryPassword, repositoryReferenceName: $repositoryReferenceName, repositoryURL: $repositoryURL, repositoryUsername: $repositoryUsername, swarmID: $swarmID, tlsskipVerify: $tlsskipVerify} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deploy a new swarm stack from a text
#
# POST /stacks/create/swarm/string
# operationId: StackCreateDockerSwarmString
# --env item shape: {name?: string, value?: string}
export def "stacks-create-swarm-string StackCreateDockerSwarmString" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # Identifier of the environment that will be used to deploy the stack
  --env: list # A list of environment variables used during stack deployment — item shape: {name?: string, value?: string}
  --fromAppTemplate: oneof<nothing, bool> # Whether the stack is from a app template (e.g. false)
  name: string # Name of the stack (e.g. myStack)
  stackFileContent: string # Content of the Stack file (e.g. version: 3  services:  web:  image:nginx)
  swarmID: string # Swarm cluster identifier (e.g. jpofkc0i9uo9wtx1zesuk649w)
]: any -> record<AdditionalFiles: list<string>, AutoUpdate: record<forcePullImage: bool, forceUpdate: bool, interval: string, jobID: string, webhook: string>, EndpointId: int, EntryPoint: string, Env: table<name: string, value: string>, Id: int, Name: string, Option: record<prune: bool>, ResourceControl: record<AccessLevel: int, AdministratorsOnly: bool, Id: int, OwnerId: int, Public: bool, ResourceId: string, SubResourceIds: list<string>, System: bool, TeamAccesses: list<record>, Type: int, UserAccesses: list<record>>, Status: int, SwarmId: string, Type: int, createdBy: string, creationDate: int, fromAppTemplate: bool, gitConfig: record<authentication: record<gitCredentialID: int, password: string, username: string>, configFilePath: string, configHash: string, referenceName: string, tlsskipVerify: bool, url: string>, isComposeFormat: bool, namespace: string, projectPath: string, updateDate: int, updatedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stacks/create/swarm/string" $qp)
  let body = {env: $env, fromAppTemplate: $fromAppTemplate, name: $name, stackFileContent: $stackFileContent, swarmID: $swarmID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Kubernetes stacks by name
#
# DELETE /stacks/name/{name}
# operationId: StackDeleteKubernetesByName
export def "stacks-name StackDeleteKubernetesByName" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --external: oneof<nothing, bool> # Set to true to delete an external stack. Only external Swarm stacks are supported
  --endpointId: int # Environment identifier
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "external" $external "scalar") (serialize-qp "endpointId" $endpointId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stacks/name/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Webhook for triggering stack updates from git
#
# POST /stacks/webhooks/{webhookID}
# operationId: WebhookInvoke
export def "stacks-webhooks WebhookInvoke" [
  webhookID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stacks/webhooks/($webhookID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check Portainer status
#
# GET /status
# DEPRECATED
# operationId: StatusInspect
@deprecated
export def "status StatusInspect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Version: string, demoEnvironment: record<enabled: bool, environments: list<int>, users: list<int>>, instanceID: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the count of nodes
#
# GET /status/nodes
# DEPRECATED
# operationId: statusNodesCount
@deprecated
export def "status-nodes statusNodesCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<nodes: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/status/nodes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check for portainer updates
#
# GET /status/version
# DEPRECATED
# operationId: Version
@deprecated
export def "status-version Version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<LatestVersion: string, ServerEdition: string, UpdateAvailable: bool, build: record<buildNumber: string, env: list<string>, gitCommit: string, goVersion: string, imageTag: string, nodejsVersion: string, webpackVersion: string, yarnVersion: string>, databaseVersion: string, serverVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/status/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve system info
#
# GET /system/info
# operationId: systemInfo
export def "system-info systemInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<agents: int, edgeAgents: int, platform: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the count of nodes
#
# GET /system/nodes
# operationId: systemNodesCount
export def "system-nodes systemNodesCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<nodes: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/nodes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check Portainer status
#
# GET /system/status
# operationId: systemStatus
export def "system-status systemStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Version: string, demoEnvironment: record<enabled: bool, environments: list<int>, users: list<int>>, instanceID: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upgrade Portainer to BE
#
# POST /system/upgrade
# operationId: systemUpgrade
export def "system-upgrade systemUpgrade" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/upgrade")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check for portainer updates
#
# GET /system/version
# operationId: systemVersion
export def "system-version systemVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<LatestVersion: string, ServerEdition: string, UpdateAvailable: bool, build: record<buildNumber: string, env: list<string>, gitCommit: string, goVersion: string, imageTag: string, nodejsVersion: string, webpackVersion: string, yarnVersion: string>, databaseVersion: string, serverVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List tags
#
# GET /tags
# operationId: TagList
export def "tags TagList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<EndpointGroups: record, Endpoints: record, Name: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new tag
#
# POST /tags
# operationId: TagCreate
export def "tags TagCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # e.g. org/acme
]: any -> record<EndpointGroups: record, Endpoints: record, Name: string, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tags")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a tag
#
# DELETE /tags/{id}
# operationId: TagDelete
export def "tags TagDelete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List team memberships
#
# GET /team_memberships
# operationId: TeamMembershipList
export def "team-memberships TeamMembershipList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<Id: int, Role: int, TeamID: int, UserID: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/team_memberships")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new team membership
#
# POST /team_memberships
# operationId: TeamMembershipCreate
export def "team-memberships TeamMembershipCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  role: int@role-completer # Role for the user inside the team (1 for leader and 2 for regular member) (e.g. 1)
  teamID: int # Team identifier (e.g. 1)
  userID: int # User identifier (e.g. 1)
]: any -> record<Id: int, Role: int, TeamID: int, UserID: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/team_memberships")
  let body = {role: $role, teamID: $teamID, userID: $userID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a team membership
#
# DELETE /team_memberships/{id}
# operationId: TeamMembershipDelete
export def "team-memberships TeamMembershipDelete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team_memberships/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a team membership
#
# PUT /team_memberships/{id}
# operationId: TeamMembershipUpdate
export def "team-memberships TeamMembershipUpdate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  role: int@role-completer # Role for the user inside the team (1 for leader and 2 for regular member) (e.g. 1)
  teamID: int # Team identifier (e.g. 1)
  userID: int # User identifier (e.g. 1)
]: any -> record<Id: int, Role: int, TeamID: int, UserID: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team_memberships/($id)")
  let body = {role: $role, teamID: $teamID, userID: $userID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List teams
#
# GET /teams
# operationId: TeamList
export def "teams TeamList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --onlyLedTeams: oneof<nothing, bool> # Only list teams that the user is leader of
  --environmentId: int # Identifier of the environment(endpoint) that will be used to filter the authorized teams
]: nothing -> table<Id: int, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "onlyLedTeams" $onlyLedTeams "scalar") (serialize-qp "environmentId" $environmentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new team
#
# POST /teams
# operationId: TeamCreate
export def "teams TeamCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name (e.g. developers)
  --teamLeaders: list # TeamLeaders (e.g. [3, 5])
]: any -> record<Id: int, Name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/teams")
  let body = {name: $name, teamLeaders: $teamLeaders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a team
#
# DELETE /teams/{id}
# operationId: TeamDelete
export def "teams TeamDelete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect a team
#
# GET /teams/{id}
# operationId: TeamInspect
export def "teams TeamInspect" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Id: int, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a team
#
# PUT /teams/{id}
# operationId: TeamUpdate
export def "teams TeamUpdate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name (e.g. developers)
]: any -> record<Id: int, Name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List team memberships
#
# GET /teams/{id}/memberships
# operationId: TeamMemberships
export def "teams-memberships TeamMemberships" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<Id: int, Role: int, TeamID: int, UserID: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)/memberships")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List available templates
#
# GET /templates
# operationId: TemplateList
export def "templates TemplateList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<templates: table<administrator_only: bool, categories: list, command: string, description: string, env: list, hostname: string, id: int, image: string, interactive: bool, labels: list, logo: string, name: string, network: string, note: string, platform: string, ports: list, privileged: bool, registry: string, repository: record, restart_policy: string, stackFile: string, title: string, type: int, volumes: list>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a template's file
#
# POST /templates/{id}/file
# operationId: TemplateFile
export def "templates-file TemplateFile" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fileContent: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($id)/file")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a template's file
#
# POST /templates/file
# DEPRECATED
# operationId: TemplateFileOld
@deprecated
export def "templates-file TemplateFileOld" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  composeFilePathInRepository: string # Path to the file inside the git repository (e.g. ./subfolder/docker-compose.yml)
  repositoryURL: string # URL of a git repository where the file is stored (e.g. https://github.com/portainer/portainer-compose)
]: any -> record<fileContent: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/file")
  let body = {composeFilePathInRepository: $composeFilePathInRepository, repositoryURL: $repositoryURL} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search Helm Charts
#
# GET /templates/helm
# operationId: HelmRepoSearch
export def "templates-helm HelmRepoSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --repo: string # Helm repository URL
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "repo" $repo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/templates/helm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show Helm Chart Information
#
# GET /templates/helm/{command}
# operationId: HelmShow
export def "templates-helm HelmShow" [
  command: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --repo: string # Helm repository URL
  --chart: string # Chart name
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "repo" $repo "scalar") (serialize-qp "chart" $chart "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/templates/helm/($command)" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload TLS files
#
# POST /upload/tls/{certificate}
# operationId: UploadTLS
export def "upload-tls UploadTLS" [
  certificate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  folder: string # Folder where the TLS file will be stored. Will be created if not existing
  file: path # The file to upload
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/upload/tls/($certificate)")
  let body = {folder: $folder, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List users
#
# GET /users
# operationId: UserList
export def "users UserList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environmentId: int # Identifier of the environment(endpoint) that will be used to filter the authorized users
]: nothing -> table<Id: int, Role: int, ThemeSettings: record<color: string>, TokenIssueAt: int, UseCache: bool, UserTheme: string, Username: string, endpointAuthorizations: record, portainerAuthorizations: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environmentId" $environmentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new user
#
# POST /users
# operationId: UserCreate
export def "users UserCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  password: string # e.g. cg9Wgky3
  role: int@role-completer # User role (1 for administrator account and 2 for regular account) (e.g. 2)
  username: string # e.g. bob
]: any -> record<Id: int, Role: int, ThemeSettings: record<color: string>, TokenIssueAt: int, UseCache: bool, UserTheme: string, Username: string, endpointAuthorizations: record, portainerAuthorizations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let body = {password: $password, role: $role, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a user
#
# DELETE /users/{id}
# operationId: UserDelete
export def "users UserDelete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect a user
#
# GET /users/{id}
# operationId: UserInspect
export def "users UserInspect" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Id: int, Role: int, ThemeSettings: record<color: string>, TokenIssueAt: int, UseCache: bool, UserTheme: string, Username: string, endpointAuthorizations: record, portainerAuthorizations: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user
#
# PUT /users/{id}
# operationId: UserUpdate
# --theme shape: {color?: "dark"|"light"|"highcontrast"|"auto"}
export def "users UserUpdate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  newPassword: string # e.g. asfj2emv
  password: string # e.g. cg9Wgky3
  role: int@role-completer # User role (1 for administrator account and 2 for regular account) (e.g. 2)
  --theme: record # shape: {color?: "dark"|"light"|"highcontrast"|"auto"}
  --useCache: oneof<nothing, bool> # e.g. true
  username: string # e.g. bob
]: any -> record<Id: int, Role: int, ThemeSettings: record<color: string>, TokenIssueAt: int, UseCache: bool, UserTheme: string, Username: string, endpointAuthorizations: record, portainerAuthorizations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)")
  let body = {newPassword: $newPassword, password: $password, role: $role, theme: $theme, useCache: $useCache, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a users helm repositories
#
# GET /users/{id}/helm/repositories
# operationId: HelmUserRepositoriesList
export def "users-helm-repositories HelmUserRepositoriesList" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<GlobalRepository: string, UserRepositories: table<Id: int, URL: string, UserId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/helm/repositories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a user helm repository
#
# POST /users/{id}/helm/repositories
# operationId: HelmUserRepositoryCreate
export def "users-helm-repositories HelmUserRepositoryCreate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string
]: any -> record<Id: int, URL: string, UserId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/helm/repositories")
  let body = {url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a users helm repositoryies
#
# DELETE /users/{id}/helm/repositories/{repositoryID}
# operationId: HelmUserRepositoryDelete
export def "users-helm-repositories HelmUserRepositoryDelete" [
  id: int
  repositoryID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/helm/repositories/($repositoryID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect a user memberships
#
# GET /users/{id}/memberships
# operationId: UserMembershipsInspect
export def "users-memberships UserMembershipsInspect" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Id: int, Role: int, TeamID: int, UserID: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/memberships")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update password for a user
#
# PUT /users/{id}/passwd
# operationId: UserUpdatePassword
export def "users-passwd UserUpdatePassword" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  newPassword: string # New Password (e.g. new_passwd)
  password: string # Current Password (e.g. passwd)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/passwd")
  let body = {newPassword: $newPassword, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all API keys for a user
#
# GET /users/{id}/tokens
# operationId: UserGetAPIKeys
export def "users-tokens UserGetAPIKeys" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<dateCreated: int, description: string, digest: string, id: int, lastUsed: int, prefix: string, userId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate an API key for a user
#
# POST /users/{id}/tokens
# operationId: UserGenerateAPIKey
export def "users-tokens UserGenerateAPIKey" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string # e.g. github-api-key
  password: string # e.g. password
]: any -> record<apiKey: record<dateCreated: int, description: string, digest: string, id: int, lastUsed: int, prefix: string, userId: int>, rawAPIKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/tokens")
  let body = {description: $description, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an api-key associated to a user
#
# DELETE /users/{id}/tokens/{keyID}
# operationId: UserRemoveAPIKey
export def "users-tokens UserRemoveAPIKey" [
  id: int
  keyID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/tokens/($keyID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check administrator account existence
#
# GET /users/admin/check
# operationId: UserAdminCheck
export def "users-admin-check UserAdminCheck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/admin/check")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initialize administrator account
#
# POST /users/admin/init
# operationId: UserAdminInit
export def "users-admin-init UserAdminInit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  password: string # Password for the admin user (e.g. admin-password)
  username: string # Username for the admin user (e.g. admin)
]: any -> record<Id: int, Role: int, ThemeSettings: record<color: string>, TokenIssueAt: int, UseCache: bool, UserTheme: string, Username: string, endpointAuthorizations: record, portainerAuthorizations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/admin/init")
  let body = {password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Inspect the current user user
#
# GET /users/me
# operationId: CurrentUserInspect
export def "users-me CurrentUserInspect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Id: int, Role: int, ThemeSettings: record<color: string>, TokenIssueAt: int, UseCache: bool, UserTheme: string, Username: string, endpointAuthorizations: record, portainerAuthorizations: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List webhooks
#
# GET /webhooks
export def "webhooks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filters: string # Filters (json-string) (e.g. {"EndpointID":1,"ResourceID":"abc12345-abcd-2345-ab12-58005b4a0260"})
]: nothing -> table<EndpointId: int, Id: int, RegistryId: int, ResourceId: string, Token: string, Type: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a webhook
#
# POST /webhooks
export def "webhooks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointID: int # Environment(Endpoint) identifier. Reference the environment(endpoint) that will be used for deployment (e.g. 1)
  --registryID: int # Registry Identifier (e.g. 1)
  --resourceID: string
  --webhookType: int # Type of webhook (1 - service)
]: any -> record<EndpointId: int, Id: int, RegistryId: int, ResourceId: string, Token: string, Type: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let body = {endpointID: $endpointID, registryID: $registryID, resourceID: $resourceID, webhookType: $webhookType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a webhook
#
# DELETE /webhooks/{id}
export def "webhooks delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Execute a webhook
#
# POST /webhooks/{id}
export def "webhooks post-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PUT /webhooks/{id}
export def "webhooks put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --registryID: int # Registry Identifier
]: any -> record<EndpointId: int, Id: int, RegistryId: int, ResourceId: string, Token: string, Type: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($id)")
  let body = {registryID: $registryID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Attach a websocket
#
# GET /websocket/attach
export def "websocket-attach get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # environment(endpoint) ID of the environment(endpoint) where the resource is located
  --nodeName: string # node name
  --qp-token: string # JWT token used for authentication against this environment(endpoint)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar") (serialize-qp "nodeName" $nodeName "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/websocket/attach" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Execute a websocket
#
# GET /websocket/exec
export def "websocket-exec get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # environment(endpoint) ID of the environment(endpoint) where the resource is located
  --nodeName: string # node name
  --qp-token: string # JWT token used for authentication against this environment(endpoint)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar") (serialize-qp "nodeName" $nodeName "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/websocket/exec" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Execute a websocket on kubectl shell pod
#
# GET /websocket/kubernetes-shell
export def "websocket-kubernetes-shell get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # environment(endpoint) ID of the environment(endpoint) where the resource is located
  --qp-token: string # JWT token used for authentication against this environment(endpoint)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/websocket/kubernetes-shell" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Execute a websocket on pod
#
# GET /websocket/pod
export def "websocket-pod get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpointId: int # environment(endpoint) ID of the environment(endpoint) where the resource is located
  --namespace: string # namespace where the container is located
  --podName: string # name of the pod containing the container
  --containerName: string # name of the container
  --command: string # command to execute in the container
  --qp-token: string # JWT token used for authentication against this environment(endpoint)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpointId" $endpointId "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "podName" $podName "scalar") (serialize-qp "containerName" $containerName "scalar") (serialize-qp "command" $command "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/websocket/pod" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
