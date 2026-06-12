# Auto-generated client for Consolidate Services vversion not set
# Source: https://raw.githubusercontent.com/argoproj/argo-cd/master/assets/swagger.json
# Auth: --token flag or $env.CONSOLIDATE_SERVICES_TOKEN

const BASE_URL = "https://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CONSOLIDATE_SERVICES_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://localhost"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account ListAccounts" } } | get name | first)
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

# ListAccounts returns the list of accounts
#
# GET /api/v1/account
# operationId: AccountService_ListAccounts
export def "account ListAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<items: table<capabilities: list, enabled: bool, name: string, tokens: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CanI checks if the current account has permission to perform an action
#
# GET /api/v1/account/can-i/{resource}/{action}/{subresource}
# operationId: AccountService_CanI
export def "account-can-i CanI" [
  resource: string
  action: string
  subresource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/account/can-i/($resource)/($action)/($subresource)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# UpdatePassword updates an account's password to a new value
#
# PUT /api/v1/account/password
# operationId: AccountService_UpdatePassword
export def "account-password UpdatePassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --currentPassword: string
  --name: string
  --newPassword: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/account/password")
  let body = {currentPassword: $currentPassword, name: $name, newPassword: $newPassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GetAccount returns an account
#
# GET /api/v1/account/{name}
# operationId: AccountService_GetAccount
export def "account GetAccount" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<capabilities: list<string>, enabled: bool, name: string, tokens: table<expiresAt: int, id: string, issuedAt: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/account/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CreateToken creates a token
#
# POST /api/v1/account/{name}/token
# operationId: AccountService_CreateToken
export def "account-token CreateToken" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiresIn: int # format: int64
  --id: string
  --body-name: string
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/account/($name)/token")
  let body = {expiresIn: $expiresIn, id: $id, name: $body_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DeleteToken deletes a token
#
# DELETE /api/v1/account/{name}/token/{id}
# operationId: AccountService_DeleteToken
export def "account-token DeleteToken" [
  name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/account/($name)/token/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List returns list of applications
#
# GET /api/v1/applications
# operationId: ApplicationService_List
export def "applications List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # the application's name.
  --refresh: string # forces application reconciliation if set to 'hard'.
  --projects: list # the project names to restrict returned list applications.
  --resourceVersion: string # when specified with a watch call, shows changes that occur after that particular version of a resource.
  --selector: string # the selector to restrict returned list to applications only with matched labels.
  --repo: string # the repoURL to restrict returned list applications.
  --appNamespace: string # the application's namespace.
  --project: list # the project names to restrict returned list applications (legacy name for backwards-compatibility).
]: nothing -> record<items: table<metadata: record, operation: record, spec: record, status: record>, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string, shardInfo: record<selector: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "refresh" $refresh "scalar") (serialize-qp "projects" $projects "multi") (serialize-qp "resourceVersion" $resourceVersion "scalar") (serialize-qp "selector" $selector "scalar") (serialize-qp "repo" $repo "scalar") (serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/applications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create creates an application
#
# POST /api/v1/applications
# operationId: ApplicationService_Create
# --metadata shape: {annotations?: record, creationTimestamp?: string, deletionGracePeriodSeconds?: int, deletionTimestamp?: string, finalizers?: list, generateName?: string, generation?: int, labels?: record, managedFields?: list, name?: string, namespace?: string, ownerReferences?: list, resourceVersion?: string, selfLink?: string, uid?: string}
# --operation shape: {info?: list, initiatedBy?: record, retry?: record, sync?: record}
# --spec shape: {destination?: record, ignoreDifferences?: list, info?: list, project?: string, revisionHistoryLimit?: int, source?: record, sourceHydrator?: record, sources?: list, syncPolicy?: record}
# --status shape: {conditions?: list, controllerNamespace?: string, health?: record, history?: list, observedAt?: string, operationState?: record, reconciledAt?: string, resourceHealthSource?: string, resources?: list, sourceHydrator?: record, sourceType?: string, sourceTypes?: list, summary?: record, sync?: record}
export def "applications Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upsert: oneof<nothing, bool>
  --validate: oneof<nothing, bool>
  --metadata: record # ObjectMeta is metadata that all persisted resources must have, which includes all objects users must create. — shape: {annotations?: record, creationTimestamp?: string, deletionGracePeriodSeconds?: int, deletionTimestamp?: string, finalizers?: list, generateName?: string, generation?: int, labels?: record, managedFields?: list, name?: string, namespace?: string, ownerReferences?: list, resourceVersion?: string, selfLink?: string, uid?: string}
  --operation: record # shape: {info?: list, initiatedBy?: record, retry?: record, sync?: record}
  --spec: record # ApplicationSpec represents desired application state. Contains link to repository with application definition and additional parameters link definition revision. — shape: {destination?: record, ignoreDifferences?: list, info?: list, project?: string, revisionHistoryLimit?: int, source?: record, sourceHydrator?: record, sources?: list, syncPolicy?: record}
  --status: record # shape: {conditions?: list, controllerNamespace?: string, health?: record, history?: list, observedAt?: string, operationState?: record, reconciledAt?: string, resourceHealthSource?: string, resources?: list, sourceHydrator?: record, sourceType?: string, sourceTypes?: list, summary?: record, sync?: record}
]: any -> record<metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, operation: record<info: list<record>, initiatedBy: record<automated: bool, username: string>, retry: record<backoff: record, limit: int, refresh: bool>, sync: record<autoHealAttemptsCount: int, dryRun: bool, manifests: list, prune: bool, resources: list, revision: string, revisions: list, source: record, sources: list, syncOptions: list, syncStrategy: record>>, spec: record<destination: record<name: string, namespace: string, server: string>, ignoreDifferences: list<record>, info: list<record>, project: string, revisionHistoryLimit: int, source: record<chart: string, directory: record, helm: record, kustomize: record, name: string, path: string, plugin: record, ref: string, repoURL: string, tagPrefix: string, targetRevision: string>, sourceHydrator: record<drySource: record, hydrateTo: record, syncSource: record>, sources: list<record>, syncPolicy: record<automated: record, managedNamespaceMetadata: record, retry: record, syncOptions: list>>, status: record<conditions: list<record>, controllerNamespace: string, health: record<lastTransitionTime: string, message: string, status: string>, history: list<record>, observedAt: string, operationState: record<finishedAt: string, message: string, operation: record, phase: string, retryCount: int, startedAt: string, syncResult: record>, reconciledAt: string, resourceHealthSource: string, resources: list<record>, sourceHydrator: record<currentOperation: record, lastComparedDryRevision: string, lastSuccessfulOperation: record>, sourceType: string, sourceTypes: list<string>, summary: record<externalURLs: list, images: list, isAppOfApps: bool>, sync: record<comparedTo: record, revision: string, revisions: list, status: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upsert" $upsert "scalar") (serialize-qp "validate" $validate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/applications" $qp)
  let body = {metadata: $metadata, operation: $operation, spec: $spec, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GetManifestsWithFiles returns application manifests using provided files to generate them
#
# POST /api/v1/applications/manifestsWithFiles
# operationId: ApplicationService_GetManifestsWithFiles
# --chunk shape: {chunk?: string}
# --query shape: {appNamespace?: string, checksum?: string, name?: string, project?: string}
export def "applications-manifests-with-files GetManifestsWithFiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chunk: record # shape: {chunk?: string}
  --body-query: record # shape: {appNamespace?: string, checksum?: string, name?: string, project?: string}
]: any -> record<commands: list<string>, manifests: list<string>, namespace: string, revision: string, server: string, sourceIntegrityResult: record<checks: list<record>>, sourceType: string, verifyResult: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/applications/manifestsWithFiles")
  let body = {chunk: $chunk, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ServerSideDiff performs server-side diff calculation using dry-run apply
#
# GET /api/v1/applications/{appName}/server-side-diff
# operationId: ApplicationService_ServerSideDiff
export def "applications-server-side-diff ServerSideDiff" [
  appName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appNamespace: string
  --project: string
  --targetManifests: list
]: nothing -> record<items: table<diff: string, group: string, hook: bool, kind: string, liveState: string, modified: bool, name: string, namespace: string, normalizedLiveState: string, predictedLiveState: string, resourceVersion: string, targetState: string>, modified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "targetManifests" $targetManifests "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($appName)/server-side-diff" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update updates an application
#
# PUT /api/v1/applications/{application.metadata.name}
# operationId: ApplicationService_Update
# --metadata shape: {annotations?: record, creationTimestamp?: string, deletionGracePeriodSeconds?: int, deletionTimestamp?: string, finalizers?: list, generateName?: string, generation?: int, labels?: record, managedFields?: list, name?: string, namespace?: string, ownerReferences?: list, resourceVersion?: string, selfLink?: string, uid?: string}
# --operation shape: {info?: list, initiatedBy?: record, retry?: record, sync?: record}
# --spec shape: {destination?: record, ignoreDifferences?: list, info?: list, project?: string, revisionHistoryLimit?: int, source?: record, sourceHydrator?: record, sources?: list, syncPolicy?: record}
# --status shape: {conditions?: list, controllerNamespace?: string, health?: record, history?: list, observedAt?: string, operationState?: record, reconciledAt?: string, resourceHealthSource?: string, resources?: list, sourceHydrator?: record, sourceType?: string, sourceTypes?: list, summary?: record, sync?: record}
export def "applications Update" [
  application.metadata.name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --validate: oneof<nothing, bool>
  --project: string
  --metadata: record # ObjectMeta is metadata that all persisted resources must have, which includes all objects users must create. — shape: {annotations?: record, creationTimestamp?: string, deletionGracePeriodSeconds?: int, deletionTimestamp?: string, finalizers?: list, generateName?: string, generation?: int, labels?: record, managedFields?: list, name?: string, namespace?: string, ownerReferences?: list, resourceVersion?: string, selfLink?: string, uid?: string}
  --operation: record # shape: {info?: list, initiatedBy?: record, retry?: record, sync?: record}
  --spec: record # ApplicationSpec represents desired application state. Contains link to repository with application definition and additional parameters link definition revision. — shape: {destination?: record, ignoreDifferences?: list, info?: list, project?: string, revisionHistoryLimit?: int, source?: record, sourceHydrator?: record, sources?: list, syncPolicy?: record}
  --status: record # shape: {conditions?: list, controllerNamespace?: string, health?: record, history?: list, observedAt?: string, operationState?: record, reconciledAt?: string, resourceHealthSource?: string, resources?: list, sourceHydrator?: record, sourceType?: string, sourceTypes?: list, summary?: record, sync?: record}
]: any -> record<metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, operation: record<info: list<record>, initiatedBy: record<automated: bool, username: string>, retry: record<backoff: record, limit: int, refresh: bool>, sync: record<autoHealAttemptsCount: int, dryRun: bool, manifests: list, prune: bool, resources: list, revision: string, revisions: list, source: record, sources: list, syncOptions: list, syncStrategy: record>>, spec: record<destination: record<name: string, namespace: string, server: string>, ignoreDifferences: list<record>, info: list<record>, project: string, revisionHistoryLimit: int, source: record<chart: string, directory: record, helm: record, kustomize: record, name: string, path: string, plugin: record, ref: string, repoURL: string, tagPrefix: string, targetRevision: string>, sourceHydrator: record<drySource: record, hydrateTo: record, syncSource: record>, sources: list<record>, syncPolicy: record<automated: record, managedNamespaceMetadata: record, retry: record, syncOptions: list>>, status: record<conditions: list<record>, controllerNamespace: string, health: record<lastTransitionTime: string, message: string, status: string>, history: list<record>, observedAt: string, operationState: record<finishedAt: string, message: string, operation: record, phase: string, retryCount: int, startedAt: string, syncResult: record>, reconciledAt: string, resourceHealthSource: string, resources: list<record>, sourceHydrator: record<currentOperation: record, lastComparedDryRevision: string, lastSuccessfulOperation: record>, sourceType: string, sourceTypes: list<string>, summary: record<externalURLs: list, images: list, isAppOfApps: bool>, sync: record<comparedTo: record, revision: string, revisions: list, status: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "validate" $validate "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($application.metadata.name)" $qp)
  let body = {metadata: $metadata, operation: $operation, spec: $spec, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ManagedResources returns list of managed resources
#
# GET /api/v1/applications/{applicationName}/managed-resources
# operationId: ApplicationService_ManagedResources
export def "applications-managed-resources ManagedResources" [
  applicationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string
  --name: string
  --version: string
  --group: string
  --kind: string
  --appNamespace: string
  --project: string
]: nothing -> record<items: table<diff: string, group: string, hook: bool, kind: string, liveState: string, modified: bool, name: string, namespace: string, normalizedLiveState: string, predictedLiveState: string, resourceVersion: string, targetState: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($applicationName)/managed-resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ResourceTree returns resource tree
#
# GET /api/v1/applications/{applicationName}/resource-tree
# operationId: ApplicationService_ResourceTree
export def "applications-resource-tree ResourceTree" [
  applicationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string
  --name: string
  --version: string
  --group: string
  --kind: string
  --appNamespace: string
  --project: string
]: nothing -> record<hosts: table<labels: record, name: string, resourcesInfo: list, systemInfo: record>, nodes: table<createdAt: string, health: record, images: list, info: list, networkingInfo: record, parentRefs: list, resourceVersion: string>, orphanedNodes: table<createdAt: string, health: record, images: list, info: list, networkingInfo: record, parentRefs: list, resourceVersion: string>, shardsCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($applicationName)/resource-tree" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get returns an application by name
#
# GET /api/v1/applications/{name}
# operationId: ApplicationService_Get
export def "applications Get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --refresh: string # forces application reconciliation if set to 'hard'.
  --projects: list # the project names to restrict returned list applications.
  --resourceVersion: string # when specified with a watch call, shows changes that occur after that particular version of a resource.
  --selector: string # the selector to restrict returned list to applications only with matched labels.
  --repo: string # the repoURL to restrict returned list applications.
  --appNamespace: string # the application's namespace.
  --project: list # the project names to restrict returned list applications (legacy name for backwards-compatibility).
]: nothing -> record<metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, operation: record<info: list<record>, initiatedBy: record<automated: bool, username: string>, retry: record<backoff: record, limit: int, refresh: bool>, sync: record<autoHealAttemptsCount: int, dryRun: bool, manifests: list, prune: bool, resources: list, revision: string, revisions: list, source: record, sources: list, syncOptions: list, syncStrategy: record>>, spec: record<destination: record<name: string, namespace: string, server: string>, ignoreDifferences: list<record>, info: list<record>, project: string, revisionHistoryLimit: int, source: record<chart: string, directory: record, helm: record, kustomize: record, name: string, path: string, plugin: record, ref: string, repoURL: string, tagPrefix: string, targetRevision: string>, sourceHydrator: record<drySource: record, hydrateTo: record, syncSource: record>, sources: list<record>, syncPolicy: record<automated: record, managedNamespaceMetadata: record, retry: record, syncOptions: list>>, status: record<conditions: list<record>, controllerNamespace: string, health: record<lastTransitionTime: string, message: string, status: string>, history: list<record>, observedAt: string, operationState: record<finishedAt: string, message: string, operation: record, phase: string, retryCount: int, startedAt: string, syncResult: record>, reconciledAt: string, resourceHealthSource: string, resources: list<record>, sourceHydrator: record<currentOperation: record, lastComparedDryRevision: string, lastSuccessfulOperation: record>, sourceType: string, sourceTypes: list<string>, summary: record<externalURLs: list, images: list, isAppOfApps: bool>, sync: record<comparedTo: record, revision: string, revisions: list, status: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "refresh" $refresh "scalar") (serialize-qp "projects" $projects "multi") (serialize-qp "resourceVersion" $resourceVersion "scalar") (serialize-qp "selector" $selector "scalar") (serialize-qp "repo" $repo "scalar") (serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete deletes an application
#
# DELETE /api/v1/applications/{name}
# operationId: ApplicationService_Delete
export def "applications Delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cascade: oneof<nothing, bool>
  --propagationPolicy: string
  --appNamespace: string
  --project: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cascade" $cascade "scalar") (serialize-qp "propagationPolicy" $propagationPolicy "scalar") (serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch patch an application
#
# PATCH /api/v1/applications/{name}
# operationId: ApplicationService_Patch
export def "applications Patch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appNamespace: string
  --body-name: string
  --patch: string
  --patchType: string
  --project: string
]: any -> record<metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, operation: record<info: list<record>, initiatedBy: record<automated: bool, username: string>, retry: record<backoff: record, limit: int, refresh: bool>, sync: record<autoHealAttemptsCount: int, dryRun: bool, manifests: list, prune: bool, resources: list, revision: string, revisions: list, source: record, sources: list, syncOptions: list, syncStrategy: record>>, spec: record<destination: record<name: string, namespace: string, server: string>, ignoreDifferences: list<record>, info: list<record>, project: string, revisionHistoryLimit: int, source: record<chart: string, directory: record, helm: record, kustomize: record, name: string, path: string, plugin: record, ref: string, repoURL: string, tagPrefix: string, targetRevision: string>, sourceHydrator: record<drySource: record, hydrateTo: record, syncSource: record>, sources: list<record>, syncPolicy: record<automated: record, managedNamespaceMetadata: record, retry: record, syncOptions: list>>, status: record<conditions: list<record>, controllerNamespace: string, health: record<lastTransitionTime: string, message: string, status: string>, history: list<record>, observedAt: string, operationState: record<finishedAt: string, message: string, operation: record, phase: string, retryCount: int, startedAt: string, syncResult: record>, reconciledAt: string, resourceHealthSource: string, resources: list<record>, sourceHydrator: record<currentOperation: record, lastComparedDryRevision: string, lastSuccessfulOperation: record>, sourceType: string, sourceTypes: list<string>, summary: record<externalURLs: list, images: list, isAppOfApps: bool>, sync: record<comparedTo: record, revision: string, revisions: list, status: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/applications/($name)")
  let body = {appNamespace: $appNamespace, name: $body_name, patch: $patch, patchType: $patchType, project: $project} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ListResourceEvents returns a list of event resources
#
# GET /api/v1/applications/{name}/events
# operationId: ApplicationService_ListResourceEvents
export def "applications-events ListResourceEvents" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resourceNamespace: string
  --resourceName: string
  --resourceUID: string
  --appNamespace: string
  --project: string
]: nothing -> record<items: table<action: string, count: int, eventTime: record, firstTimestamp: string, involvedObject: record, lastTimestamp: string, message: string, metadata: record, reason: string, related: record, reportingComponent: string, reportingInstance: string, series: record, source: record, type: string>, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string, shardInfo: record<selector: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceNamespace" $resourceNamespace "scalar") (serialize-qp "resourceName" $resourceName "scalar") (serialize-qp "resourceUID" $resourceUID "scalar") (serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($name)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListLinks returns the list of all application deep links
#
# GET /api/v1/applications/{name}/links
# operationId: ApplicationService_ListLinks
export def "applications-links ListLinks" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string
  --project: string
]: nothing -> record<items: table<description: string, iconClass: string, title: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($name)/links" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PodLogs returns stream of log entries for the specified pod. Pod
#
# GET /api/v1/applications/{name}/logs
# operationId: ApplicationService_PodLogs2
export def "applications-logs PodLogs2" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string
  --podName: string
  --container: string
  --sinceSeconds: string # format: int64
  --sinceTimeseconds: string # Represents seconds of UTC time since Unix epoch 1970-01-01T00:00:00Z. Must be from 0001-01-01T00:00:00Z to 9999-12-31T23:59:59Z inclusive. (format: int64)
  --sinceTimenanos: int # Non-negative fractions of a second at nanosecond resolution. Negative second values with fractions must still have non-negative nanos values that count forward in time. Must be from 0 to 999,999,999 inclusive. This field may be limited in precision depending on context. (format: int32)
  --tailLines: string # format: int64
  --follow: oneof<nothing, bool>
  --untilTime: string
  --filter: string
  --kind: string
  --group: string
  --resourceName: string
  --previous: oneof<nothing, bool>
  --appNamespace: string
  --project: string
  --matchCase: oneof<nothing, bool>
]: nothing -> record<error: record<details: list<record>, grpc_code: int, http_code: int, http_status: string, message: string>, result: record<content: string, last: bool, podName: string, timeStamp: string, timeStampStr: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "podName" $podName "scalar") (serialize-qp "container" $container "scalar") (serialize-qp "sinceSeconds" $sinceSeconds "scalar") (serialize-qp "sinceTime.seconds" $sinceTimeseconds "scalar") (serialize-qp "sinceTime.nanos" $sinceTimenanos "scalar") (serialize-qp "tailLines" $tailLines "scalar") (serialize-qp "follow" $follow "scalar") (serialize-qp "untilTime" $untilTime "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "resourceName" $resourceName "scalar") (serialize-qp "previous" $previous "scalar") (serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "matchCase" $matchCase "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($name)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GetManifests returns application manifests
#
# GET /api/v1/applications/{name}/manifests
# operationId: ApplicationService_GetManifests
export def "applications-manifests GetManifests" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string
  --appNamespace: string
  --project: string
  --sourcePositions: list
  --revisions: list
  --noCache: oneof<nothing, bool>
]: nothing -> record<commands: list<string>, manifests: list<string>, namespace: string, revision: string, server: string, sourceIntegrityResult: record<checks: list<record>>, sourceType: string, verifyResult: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "revision" $revision "scalar") (serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "sourcePositions" $sourcePositions "multi") (serialize-qp "revisions" $revisions "multi") (serialize-qp "noCache" $noCache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($name)/manifests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# TerminateOperation terminates the currently running operation
#
# DELETE /api/v1/applications/{name}/operation
# operationId: ApplicationService_TerminateOperation
export def "applications-operation TerminateOperation" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appNamespace: string
  --project: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($name)/operation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PodLogs returns stream of log entries for the specified pod. Pod
#
# GET /api/v1/applications/{name}/pods/{podName}/logs
# operationId: ApplicationService_PodLogs
export def "applications-pods-logs PodLogs" [
  name: string
  podName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string
  --container: string
  --sinceSeconds: string # format: int64
  --sinceTimeseconds: string # Represents seconds of UTC time since Unix epoch 1970-01-01T00:00:00Z. Must be from 0001-01-01T00:00:00Z to 9999-12-31T23:59:59Z inclusive. (format: int64)
  --sinceTimenanos: int # Non-negative fractions of a second at nanosecond resolution. Negative second values with fractions must still have non-negative nanos values that count forward in time. Must be from 0 to 999,999,999 inclusive. This field may be limited in precision depending on context. (format: int32)
  --tailLines: string # format: int64
  --follow: oneof<nothing, bool>
  --untilTime: string
  --filter: string
  --kind: string
  --group: string
  --resourceName: string
  --previous: oneof<nothing, bool>
  --appNamespace: string
  --project: string
  --matchCase: oneof<nothing, bool>
]: nothing -> record<error: record<details: list<record>, grpc_code: int, http_code: int, http_status: string, message: string>, result: record<content: string, last: bool, podName: string, timeStamp: string, timeStampStr: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "container" $container "scalar") (serialize-qp "sinceSeconds" $sinceSeconds "scalar") (serialize-qp "sinceTime.seconds" $sinceTimeseconds "scalar") (serialize-qp "sinceTime.nanos" $sinceTimenanos "scalar") (serialize-qp "tailLines" $tailLines "scalar") (serialize-qp "follow" $follow "scalar") (serialize-qp "untilTime" $untilTime "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "resourceName" $resourceName "scalar") (serialize-qp "previous" $previous "scalar") (serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "matchCase" $matchCase "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($name)/pods/($podName)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GetResource returns single application resource
#
# GET /api/v1/applications/{name}/resource
# operationId: ApplicationService_GetResource
export def "applications-resource GetResource" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string
  --resourceName: string
  --version: string
  --group: string
  --kind: string
  --appNamespace: string
  --project: string
]: nothing -> record<manifest: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "resourceName" $resourceName "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($name)/resource" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PatchResource patch single application resource
#
# POST /api/v1/applications/{name}/resource
# operationId: ApplicationService_PatchResource
export def "applications-resource PatchResource" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string
  --resourceName: string
  --version: string
  --group: string
  --kind: string
  --patchType: string
  --appNamespace: string
  --project: string
  --body: record
]: any -> record<manifest: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "resourceName" $resourceName "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "patchType" $patchType "scalar") (serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($name)/resource" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DeleteResource deletes a single application resource
#
# DELETE /api/v1/applications/{name}/resource
# operationId: ApplicationService_DeleteResource
export def "applications-resource DeleteResource" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string
  --resourceName: string
  --version: string
  --group: string
  --kind: string
  --force: oneof<nothing, bool>
  --orphan: oneof<nothing, bool>
  --appNamespace: string
  --project: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "resourceName" $resourceName "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "force" $force "scalar") (serialize-qp "orphan" $orphan "scalar") (serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($name)/resource" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListResourceActions returns list of resource actions
#
# GET /api/v1/applications/{name}/resource/actions
# operationId: ApplicationService_ListResourceActions
export def "applications-resource-actions ListResourceActions" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string
  --resourceName: string
  --version: string
  --group: string
  --kind: string
  --appNamespace: string
  --project: string
]: nothing -> record<actions: table<disabled: bool, displayName: string, iconClass: string, name: string, params: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "resourceName" $resourceName "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($name)/resource/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# RunResourceAction runs a resource action
#
# POST /api/v1/applications/{name}/resource/actions
# operationId: ApplicationService_RunResourceAction
export def "applications-resource-actions RunResourceAction" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string
  --resourceName: string
  --version: string
  --group: string
  --kind: string
  --appNamespace: string
  --project: string
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "resourceName" $resourceName "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($name)/resource/actions" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# RunResourceActionV2 runs a resource action with parameters
#
# POST /api/v1/applications/{name}/resource/actions/v2
# operationId: ApplicationService_RunResourceActionV2
# --resourceActionParameters item shape: {name?: string, value?: string}
export def "applications-resource-actions RunResourceActionV2" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string
  --appNamespace: string
  --group: string
  --kind: string
  --body-name: string
  --namespace: string
  --project: string
  --resourceActionParameters: list # item shape: {name?: string, value?: string}
  --resourceName: string
  --version: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/applications/($name)/resource/actions/v2")
  let body = {action: $action, appNamespace: $appNamespace, group: $group, kind: $kind, name: $body_name, namespace: $namespace, project: $project, resourceActionParameters: $resourceActionParameters, resourceName: $resourceName, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ListResourceLinks returns the list of all resource deep links
#
# GET /api/v1/applications/{name}/resource/links
# operationId: ApplicationService_ListResourceLinks
export def "applications-resource-links ListResourceLinks" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string
  --resourceName: string
  --version: string
  --group: string
  --kind: string
  --appNamespace: string
  --project: string
]: nothing -> record<items: table<description: string, iconClass: string, title: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "resourceName" $resourceName "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($name)/resource/links" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the chart metadata (description, maintainers, home) for a specific revision of the application
#
# GET /api/v1/applications/{name}/revisions/{revision}/chartdetails
# operationId: ApplicationService_RevisionChartDetails
export def "applications-revisions-chartdetails RevisionChartDetails" [
  name: string
  revision: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appNamespace: string # the application's namespace.
  --project: string
  --sourceIndex: int # source index (for multi source apps). (format: int32)
  --versionId: int # versionId from historical data (for multi source apps). (format: int32)
]: nothing -> record<description: string, home: string, maintainers: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "sourceIndex" $sourceIndex "scalar") (serialize-qp "versionId" $versionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($name)/revisions/($revision)/chartdetails" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the meta-data (author, date, tags, message) for a specific revision of the application
#
# GET /api/v1/applications/{name}/revisions/{revision}/metadata
# operationId: ApplicationService_RevisionMetadata
export def "applications-revisions-metadata RevisionMetadata" [
  name: string
  revision: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appNamespace: string # the application's namespace.
  --project: string
  --sourceIndex: int # source index (for multi source apps). (format: int32)
  --versionId: int # versionId from historical data (for multi source apps). (format: int32)
]: nothing -> record<author: string, date: string, message: string, references: table<commit: record>, signatureInfo: string, sourceIntegrityResult: record<checks: list<record>>, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "sourceIndex" $sourceIndex "scalar") (serialize-qp "versionId" $versionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($name)/revisions/($revision)/metadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the chart metadata (description, maintainers, home) for a specific revision of the application
#
# GET /api/v1/applications/{name}/revisions/{revision}/ocimetadata
# operationId: ApplicationService_GetOCIMetadata
export def "applications-revisions-ocimetadata GetOCIMetadata" [
  name: string
  revision: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appNamespace: string # the application's namespace.
  --project: string
  --sourceIndex: int # source index (for multi source apps). (format: int32)
  --versionId: int # versionId from historical data (for multi source apps). (format: int32)
]: nothing -> record<authors: string, createdAt: string, description: string, docsUrl: string, imageUrl: string, sourceUrl: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "sourceIndex" $sourceIndex "scalar") (serialize-qp "versionId" $versionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($name)/revisions/($revision)/ocimetadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rollback syncs an application to its target state
#
# POST /api/v1/applications/{name}/rollback
# operationId: ApplicationService_Rollback
export def "applications-rollback Rollback" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appNamespace: string
  --dryRun: oneof<nothing, bool>
  --id: int # format: int64
  --body-name: string
  --project: string
  --prune: oneof<nothing, bool>
]: any -> record<metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, operation: record<info: list<record>, initiatedBy: record<automated: bool, username: string>, retry: record<backoff: record, limit: int, refresh: bool>, sync: record<autoHealAttemptsCount: int, dryRun: bool, manifests: list, prune: bool, resources: list, revision: string, revisions: list, source: record, sources: list, syncOptions: list, syncStrategy: record>>, spec: record<destination: record<name: string, namespace: string, server: string>, ignoreDifferences: list<record>, info: list<record>, project: string, revisionHistoryLimit: int, source: record<chart: string, directory: record, helm: record, kustomize: record, name: string, path: string, plugin: record, ref: string, repoURL: string, tagPrefix: string, targetRevision: string>, sourceHydrator: record<drySource: record, hydrateTo: record, syncSource: record>, sources: list<record>, syncPolicy: record<automated: record, managedNamespaceMetadata: record, retry: record, syncOptions: list>>, status: record<conditions: list<record>, controllerNamespace: string, health: record<lastTransitionTime: string, message: string, status: string>, history: list<record>, observedAt: string, operationState: record<finishedAt: string, message: string, operation: record, phase: string, retryCount: int, startedAt: string, syncResult: record>, reconciledAt: string, resourceHealthSource: string, resources: list<record>, sourceHydrator: record<currentOperation: record, lastComparedDryRevision: string, lastSuccessfulOperation: record>, sourceType: string, sourceTypes: list<string>, summary: record<externalURLs: list, images: list, isAppOfApps: bool>, sync: record<comparedTo: record, revision: string, revisions: list, status: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/applications/($name)/rollback")
  let body = {appNamespace: $appNamespace, dryRun: $dryRun, id: $id, name: $body_name, project: $project, prune: $prune} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UpdateSpec updates an application spec
#
# PUT /api/v1/applications/{name}/spec
# operationId: ApplicationService_UpdateSpec
# --destination shape: {name?: string, namespace?: string, server?: string}
# --ignoreDifferences item shape: {group?: string, jqPathExpressions?: list, jsonPointers?: list, kind?: string, managedFieldsManagers?: list, name?: string, namespace?: string}
# --info item shape: {name?: string, value?: string}
# --source shape: {chart?: string, directory?: record, helm?: record, kustomize?: record, name?: string, path?: string, plugin?: record, ref?: string, repoURL?: string, tagPrefix?: string, targetRevision?: string}
# --sourceHydrator shape: {drySource?: record, hydrateTo?: record, syncSource?: record}
# --sources item shape: {chart?: string, directory?: record, helm?: record, kustomize?: record, name?: string, path?: string, plugin?: record, ref?: string, repoURL?: string, tagPrefix?: string, targetRevision?: string}
# --syncPolicy shape: {automated?: record, managedNamespaceMetadata?: record, retry?: record, syncOptions?: list}
export def "applications-spec UpdateSpec" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --validate: oneof<nothing, bool>
  --appNamespace: string
  --project: string
  --destination: record # shape: {name?: string, namespace?: string, server?: string}
  --ignoreDifferences: list # item shape: {group?: string, jqPathExpressions?: list, jsonPointers?: list, kind?: string, managedFieldsManagers?: list, name?: string, namespace?: string}
  --info: list # item shape: {name?: string, value?: string}
  --project: string # Project is a reference to the project this application belongs to. The empty string means that application belongs to the 'default' project.
  --revisionHistoryLimit: int # RevisionHistoryLimit limits the number of items kept in the application's revision history, which is used for informational purposes as well as for rollbacks to previous versions. This should only be changed in exceptional circumstances. Setting to zero will store no history. This will reduce storage used. Increasing will increase the space used to store the history, so we do not recommend increasing it. Default is 10. (format: int64)
  --body-source: record # shape: {chart?: string, directory?: record, helm?: record, kustomize?: record, name?: string, path?: string, plugin?: record, ref?: string, repoURL?: string, tagPrefix?: string, targetRevision?: string}
  --sourceHydrator: record # SourceHydrator specifies a dry "don't repeat yourself" source for manifests, a sync source from which to sync hydrated manifests, and an optional hydrateTo location to act as a "staging" aread for hydrated manifests. — shape: {drySource?: record, hydrateTo?: record, syncSource?: record}
  --sources: list # item shape: {chart?: string, directory?: record, helm?: record, kustomize?: record, name?: string, path?: string, plugin?: record, ref?: string, repoURL?: string, tagPrefix?: string, targetRevision?: string}
  --syncPolicy: record # shape: {automated?: record, managedNamespaceMetadata?: record, retry?: record, syncOptions?: list}
]: any -> record<destination: record<name: string, namespace: string, server: string>, ignoreDifferences: table<group: string, jqPathExpressions: list, jsonPointers: list, kind: string, managedFieldsManagers: list, name: string, namespace: string>, info: table<name: string, value: string>, project: string, revisionHistoryLimit: int, source: record<chart: string, directory: record<exclude: string, include: string, jsonnet: record, recurse: bool>, helm: record<apiVersions: list, fileParameters: list, ignoreMissingValueFiles: bool, kubeVersion: string, namespace: string, parameters: list, passCredentials: bool, releaseName: string, skipCrds: bool, skipSchemaValidation: bool, skipTests: bool, valueFiles: list, values: string, valuesObject: record, version: string>, kustomize: record<apiVersions: list, commonAnnotations: record, commonAnnotationsEnvsubst: bool, commonLabels: record, components: list, forceCommonAnnotations: bool, forceCommonLabels: bool, ignoreMissingComponents: bool, images: list, kubeVersion: string, labelIncludeTemplates: bool, labelWithoutSelector: bool, namePrefix: string, nameSuffix: string, namespace: string, patches: list, replicas: list, version: string>, name: string, path: string, plugin: record<env: list, name: string, parameters: list>, ref: string, repoURL: string, tagPrefix: string, targetRevision: string>, sourceHydrator: record<drySource: record<directory: record, helm: record, kustomize: record, path: string, plugin: record, repoURL: string, targetRevision: string>, hydrateTo: record<targetBranch: string>, syncSource: record<path: string, repoURL: string, targetBranch: string>>, sources: table<chart: string, directory: record, helm: record, kustomize: record, name: string, path: string, plugin: record, ref: string, repoURL: string, tagPrefix: string, targetRevision: string>, syncPolicy: record<automated: record<allowEmpty: bool, enabled: bool, prune: bool, selfHeal: bool>, managedNamespaceMetadata: record<annotations: record, labels: record>, retry: record<backoff: record, limit: int, refresh: bool>, syncOptions: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "validate" $validate "scalar") (serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($name)/spec" $qp)
  let body = {destination: $destination, ignoreDifferences: $ignoreDifferences, info: $info, project: $project, revisionHistoryLimit: $revisionHistoryLimit, source: $body_source, sourceHydrator: $sourceHydrator, sources: $sources, syncPolicy: $syncPolicy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sync syncs an application to its target state
#
# POST /api/v1/applications/{name}/sync
# operationId: ApplicationService_Sync
# --infos item shape: {name?: string, value?: string}
# --resources item shape: {group?: string, kind?: string, name?: string, namespace?: string}
# --retryStrategy shape: {backoff?: record, limit?: int, refresh?: bool}
# --strategy shape: {apply?: record, hook?: record}
# --syncOptions shape: {items?: list}
export def "applications-sync Sync" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appNamespace: string
  --dryRun: oneof<nothing, bool>
  --infos: list # item shape: {name?: string, value?: string}
  --manifests: list
  --body-name: string
  --project: string
  --prune: oneof<nothing, bool>
  --resources: list # item shape: {group?: string, kind?: string, name?: string, namespace?: string}
  --retryStrategy: record # shape: {backoff?: record, limit?: int, refresh?: bool}
  --revision: string
  --revisions: list
  --sourcePositions: list
  --strategy: record # shape: {apply?: record, hook?: record}
  --syncOptions: record # shape: {items?: list}
]: any -> record<metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, operation: record<info: list<record>, initiatedBy: record<automated: bool, username: string>, retry: record<backoff: record, limit: int, refresh: bool>, sync: record<autoHealAttemptsCount: int, dryRun: bool, manifests: list, prune: bool, resources: list, revision: string, revisions: list, source: record, sources: list, syncOptions: list, syncStrategy: record>>, spec: record<destination: record<name: string, namespace: string, server: string>, ignoreDifferences: list<record>, info: list<record>, project: string, revisionHistoryLimit: int, source: record<chart: string, directory: record, helm: record, kustomize: record, name: string, path: string, plugin: record, ref: string, repoURL: string, tagPrefix: string, targetRevision: string>, sourceHydrator: record<drySource: record, hydrateTo: record, syncSource: record>, sources: list<record>, syncPolicy: record<automated: record, managedNamespaceMetadata: record, retry: record, syncOptions: list>>, status: record<conditions: list<record>, controllerNamespace: string, health: record<lastTransitionTime: string, message: string, status: string>, history: list<record>, observedAt: string, operationState: record<finishedAt: string, message: string, operation: record, phase: string, retryCount: int, startedAt: string, syncResult: record>, reconciledAt: string, resourceHealthSource: string, resources: list<record>, sourceHydrator: record<currentOperation: record, lastComparedDryRevision: string, lastSuccessfulOperation: record>, sourceType: string, sourceTypes: list<string>, summary: record<externalURLs: list, images: list, isAppOfApps: bool>, sync: record<comparedTo: record, revision: string, revisions: list, status: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/applications/($name)/sync")
  let body = {appNamespace: $appNamespace, dryRun: $dryRun, infos: $infos, manifests: $manifests, name: $body_name, project: $project, prune: $prune, resources: $resources, retryStrategy: $retryStrategy, revision: $revision, revisions: $revisions, sourcePositions: $sourcePositions, strategy: $strategy, syncOptions: $syncOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get returns sync windows of the application
#
# GET /api/v1/applications/{name}/syncwindows
# operationId: ApplicationService_GetApplicationSyncWindows
export def "applications-syncwindows GetApplicationSyncWindows" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appNamespace: string
  --project: string
]: nothing -> record<activeWindows: table<duration: string, kind: string, manualSync: bool, schedule: string>, assignedWindows: table<duration: string, kind: string, manualSync: bool, schedule: string>, canSync: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($name)/syncwindows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List returns list of applicationset
#
# GET /api/v1/applicationsets
# operationId: ApplicationSetService_List
export def "applicationsets List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --projects: list # the project names to restrict returned list applicationsets.
  --selector: string # the selector to restrict returned list to applications only with matched labels.
  --appsetNamespace: string # The application set namespace. Default empty is argocd control plane namespace.
]: nothing -> record<items: table<metadata: record, spec: record, status: record>, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string, shardInfo: record<selector: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projects" $projects "multi") (serialize-qp "selector" $selector "scalar") (serialize-qp "appsetNamespace" $appsetNamespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/applicationsets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create creates an applicationset
#
# POST /api/v1/applicationsets
# operationId: ApplicationSetService_Create
# --metadata shape: {annotations?: record, creationTimestamp?: string, deletionGracePeriodSeconds?: int, deletionTimestamp?: string, finalizers?: list, generateName?: string, generation?: int, labels?: record, managedFields?: list, name?: string, namespace?: string, ownerReferences?: list, resourceVersion?: string, selfLink?: string, uid?: string}
# --spec shape: {applyNestedSelectors?: bool, generators?: list, goTemplate?: bool, goTemplateOptions?: list, ignoreApplicationDifferences?: list, preservedFields?: record, strategy?: record, syncPolicy?: record, template?: record, templatePatch?: string}
# --status shape: {applicationStatus?: list, conditions?: list, health?: record, resources?: list, resourcesCount?: int}
export def "applicationsets Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upsert: oneof<nothing, bool>
  --dryRun: oneof<nothing, bool>
  --metadata: record # ObjectMeta is metadata that all persisted resources must have, which includes all objects users must create. — shape: {annotations?: record, creationTimestamp?: string, deletionGracePeriodSeconds?: int, deletionTimestamp?: string, finalizers?: list, generateName?: string, generation?: int, labels?: record, managedFields?: list, name?: string, namespace?: string, ownerReferences?: list, resourceVersion?: string, selfLink?: string, uid?: string}
  --spec: record # ApplicationSetSpec represents a class of application set state. — shape: {applyNestedSelectors?: bool, generators?: list, goTemplate?: bool, goTemplateOptions?: list, ignoreApplicationDifferences?: list, preservedFields?: record, strategy?: record, syncPolicy?: record, template?: record, templatePatch?: string}
  --status: record # shape: {applicationStatus?: list, conditions?: list, health?: record, resources?: list, resourcesCount?: int}
]: any -> record<metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<applyNestedSelectors: bool, generators: list<record>, goTemplate: bool, goTemplateOptions: list<string>, ignoreApplicationDifferences: list<record>, preservedFields: record<annotations: list, labels: list>, strategy: record<deletionOrder: string, rollingSync: record, type: string>, syncPolicy: record<applicationsSync: string, preserveResourcesOnDeletion: bool>, template: record<metadata: record, spec: record>, templatePatch: string>, status: record<applicationStatus: list<record>, conditions: list<record>, health: record<lastTransitionTime: string, message: string, status: string>, resources: list<record>, resourcesCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upsert" $upsert "scalar") (serialize-qp "dryRun" $dryRun "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/applicationsets" $qp)
  let body = {metadata: $metadata, spec: $spec, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate generates
#
# POST /api/v1/applicationsets/generate
# operationId: ApplicationSetService_Generate
# --applicationSet shape: {metadata?: record, spec?: record, status?: record}
export def "applicationsets-generate Generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --applicationSet: record # shape: {metadata?: record, spec?: record, status?: record}
]: any -> record<applications: table<metadata: record, operation: record, spec: record, status: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/applicationsets/generate")
  let body = {applicationSet: $applicationSet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get returns an applicationset by name
#
# GET /api/v1/applicationsets/{name}
# operationId: ApplicationSetService_Get
export def "applicationsets Get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appsetNamespace: string # The application set namespace. Default empty is argocd control plane namespace.
]: nothing -> record<metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<applyNestedSelectors: bool, generators: list<record>, goTemplate: bool, goTemplateOptions: list<string>, ignoreApplicationDifferences: list<record>, preservedFields: record<annotations: list, labels: list>, strategy: record<deletionOrder: string, rollingSync: record, type: string>, syncPolicy: record<applicationsSync: string, preserveResourcesOnDeletion: bool>, template: record<metadata: record, spec: record>, templatePatch: string>, status: record<applicationStatus: list<record>, conditions: list<record>, health: record<lastTransitionTime: string, message: string, status: string>, resources: list<record>, resourcesCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appsetNamespace" $appsetNamespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applicationsets/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete deletes an application set
#
# DELETE /api/v1/applicationsets/{name}
# operationId: ApplicationSetService_Delete
export def "applicationsets Delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appsetNamespace: string # The application set namespace. Default empty is argocd control plane namespace.
]: nothing -> record<applicationset: record<metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list, generateName: string, generation: int, labels: record, managedFields: list, name: string, namespace: string, ownerReferences: list, resourceVersion: string, selfLink: string, uid: string>, spec: record<applyNestedSelectors: bool, generators: list, goTemplate: bool, goTemplateOptions: list, ignoreApplicationDifferences: list, preservedFields: record, strategy: record, syncPolicy: record, template: record, templatePatch: string>, status: record<applicationStatus: list, conditions: list, health: record, resources: list, resourcesCount: int>>, project: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appsetNamespace" $appsetNamespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applicationsets/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListResourceEvents returns a list of event resources
#
# GET /api/v1/applicationsets/{name}/events
# operationId: ApplicationSetService_ListResourceEvents
export def "applicationsets-events ListResourceEvents" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appsetNamespace: string # The application set namespace. Default empty is argocd control plane namespace.
]: nothing -> record<items: table<action: string, count: int, eventTime: record, firstTimestamp: string, involvedObject: record, lastTimestamp: string, message: string, metadata: record, reason: string, related: record, reportingComponent: string, reportingInstance: string, series: record, source: record, type: string>, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string, shardInfo: record<selector: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appsetNamespace" $appsetNamespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applicationsets/($name)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ResourceTree returns resource tree
#
# GET /api/v1/applicationsets/{name}/resource-tree
# operationId: ApplicationSetService_ResourceTree
export def "applicationsets-resource-tree ResourceTree" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appsetNamespace: string # The application set namespace. Default empty is argocd control plane namespace.
]: nothing -> record<nodes: table<createdAt: string, health: record, images: list, info: list, networkingInfo: record, parentRefs: list, resourceVersion: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appsetNamespace" $appsetNamespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applicationsets/($name)/resource-tree" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all available repository certificates
#
# GET /api/v1/certificates
# operationId: CertificateService_ListCertificates
export def "certificates ListCertificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hostNamePattern: string # A file-glob pattern (not regular expression) the host name has to match.
  --certType: string # The type of the certificate to match (ssh or https).
  --certSubType: string # The sub type of the certificate to match (protocol dependent, usually only used for ssh certs).
]: nothing -> record<items: table<certData: string, certInfo: string, certSubType: string, certType: string, serverName: string>, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string, shardInfo: record<selector: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hostNamePattern" $hostNamePattern "scalar") (serialize-qp "certType" $certType "scalar") (serialize-qp "certSubType" $certSubType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/certificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates repository certificates on the server
#
# POST /api/v1/certificates
# operationId: CertificateService_CreateCertificate
# --items item shape: {certData?: string, certInfo?: string, certSubType?: string, certType?: string, serverName?: string}
# --metadata shape: {continue?: string, remainingItemCount?: int, resourceVersion?: string, selfLink?: string, shardInfo?: record}
export def "certificates CreateCertificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upsert: oneof<nothing, bool> # Whether to upsert already existing certificates.
  --items: list # item shape: {certData?: string, certInfo?: string, certSubType?: string, certType?: string, serverName?: string}
  --metadata: record # ListMeta describes metadata that synthetic resources must have, including lists and various status objects. A resource may have only one of {ObjectMeta, ListMeta}. — shape: {continue?: string, remainingItemCount?: int, resourceVersion?: string, selfLink?: string, shardInfo?: record}
]: any -> record<items: table<certData: string, certInfo: string, certSubType: string, certType: string, serverName: string>, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string, shardInfo: record<selector: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upsert" $upsert "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/certificates" $qp)
  let body = {items: $items, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the certificates that match the RepositoryCertificateQuery
#
# DELETE /api/v1/certificates
# operationId: CertificateService_DeleteCertificate
export def "certificates DeleteCertificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hostNamePattern: string # A file-glob pattern (not regular expression) the host name has to match.
  --certType: string # The type of the certificate to match (ssh or https).
  --certSubType: string # The sub type of the certificate to match (protocol dependent, usually only used for ssh certs).
]: nothing -> record<items: table<certData: string, certInfo: string, certSubType: string, certType: string, serverName: string>, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string, shardInfo: record<selector: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hostNamePattern" $hostNamePattern "scalar") (serialize-qp "certType" $certType "scalar") (serialize-qp "certSubType" $certSubType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/certificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List returns list of clusters
#
# GET /api/v1/clusters
# operationId: ClusterService_List
export def "clusters List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --server: string
  --name: string
  --idtype: string # type is the type of the specified cluster identifier ( "server" - default, "name" ).
  --idvalue: string # value holds the cluster server URL or cluster name.
]: nothing -> record<items: table<annotations: record, clusterResources: bool, config: record, connectionState: record, info: record, labels: record, name: string, namespaces: list, project: string, refreshRequestedAt: string, server: string, serverVersion: string, shard: int>, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string, shardInfo: record<selector: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "server" $server "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "id.type" $idtype "scalar") (serialize-qp "id.value" $idvalue "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/clusters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create creates a cluster
#
# POST /api/v1/clusters
# operationId: ClusterService_Create
# --config shape: {awsAuthConfig?: record, bearerToken?: string, disableCompression?: bool, execProviderConfig?: record, password?: string, proxyUrl?: string, tlsClientConfig?: record, username?: string}
# --connectionState shape: {attemptedAt?: string, message?: string, status?: string}
# --info shape: {apiVersions?: list, applicationsCount?: int, cacheInfo?: record, connectionState?: record, serverVersion?: string}
export def "clusters Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upsert: oneof<nothing, bool>
  --annotations: record
  --clusterResources: oneof<nothing, bool> # Indicates if cluster level resources should be managed. This setting is used only if cluster is connected in a namespaced mode.
  --config: record # ClusterConfig is the configuration attributes. This structure is subset of the go-client rest.Config with annotations added for marshalling. — shape: {awsAuthConfig?: record, bearerToken?: string, disableCompression?: bool, execProviderConfig?: record, password?: string, proxyUrl?: string, tlsClientConfig?: record, username?: string}
  --connectionState: record # shape: {attemptedAt?: string, message?: string, status?: string}
  --info: record # shape: {apiVersions?: list, applicationsCount?: int, cacheInfo?: record, connectionState?: record, serverVersion?: string}
  --labels: record
  --name: string
  --namespaces: list # Holds list of namespaces which are accessible in that cluster. Cluster level resources will be ignored if namespace list is not empty.
  --project: string
  --refreshRequestedAt: string # Time is a wrapper around time.Time which supports correct marshaling to YAML and JSON.  Wrappers are provided for many of the factory methods that the time package offers.  +protobuf.options.marshal=false +protobuf.as=Timestamp +protobuf.options.(gogoproto.goproto_stringer)=false (format: date-time)
  --server: string
  --serverVersion: string
  --shard: int # Shard contains optional shard number. Calculated on the fly by the application controller if not specified. (format: int64)
]: any -> record<annotations: record, clusterResources: bool, config: record<awsAuthConfig: record<clusterName: string, profile: string, roleARN: string>, bearerToken: string, disableCompression: bool, execProviderConfig: record<apiVersion: string, args: list, command: string, config: record, env: record, installHint: string, provideClusterInfo: bool>, password: string, proxyUrl: string, tlsClientConfig: record<caData: string, certData: string, insecure: bool, keyData: string, serverName: string>, username: string>, connectionState: record<attemptedAt: string, message: string, status: string>, info: record<apiVersions: list<string>, applicationsCount: int, cacheInfo: record<apisCount: int, lastCacheSyncTime: string, resourcesCount: int>, connectionState: record<attemptedAt: string, message: string, status: string>, serverVersion: string>, labels: record, name: string, namespaces: list<string>, project: string, refreshRequestedAt: string, server: string, serverVersion: string, shard: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upsert" $upsert "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/clusters" $qp)
  let body = {annotations: $annotations, clusterResources: $clusterResources, config: $config, connectionState: $connectionState, info: $info, labels: $labels, name: $name, namespaces: $namespaces, project: $project, refreshRequestedAt: $refreshRequestedAt, server: $server, serverVersion: $serverVersion, shard: $shard} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get returns a cluster by server address
#
# GET /api/v1/clusters/{id.value}
# operationId: ClusterService_Get
export def "clusters Get" [
  id.value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --server: string
  --name: string
  --idtype: string # type is the type of the specified cluster identifier ( "server" - default, "name" ).
]: nothing -> record<annotations: record, clusterResources: bool, config: record<awsAuthConfig: record<clusterName: string, profile: string, roleARN: string>, bearerToken: string, disableCompression: bool, execProviderConfig: record<apiVersion: string, args: list, command: string, config: record, env: record, installHint: string, provideClusterInfo: bool>, password: string, proxyUrl: string, tlsClientConfig: record<caData: string, certData: string, insecure: bool, keyData: string, serverName: string>, username: string>, connectionState: record<attemptedAt: string, message: string, status: string>, info: record<apiVersions: list<string>, applicationsCount: int, cacheInfo: record<apisCount: int, lastCacheSyncTime: string, resourcesCount: int>, connectionState: record<attemptedAt: string, message: string, status: string>, serverVersion: string>, labels: record, name: string, namespaces: list<string>, project: string, refreshRequestedAt: string, server: string, serverVersion: string, shard: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "server" $server "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "id.type" $idtype "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/clusters/($id.value)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update updates a cluster
#
# PUT /api/v1/clusters/{id.value}
# operationId: ClusterService_Update
# --config shape: {awsAuthConfig?: record, bearerToken?: string, disableCompression?: bool, execProviderConfig?: record, password?: string, proxyUrl?: string, tlsClientConfig?: record, username?: string}
# --connectionState shape: {attemptedAt?: string, message?: string, status?: string}
# --info shape: {apiVersions?: list, applicationsCount?: int, cacheInfo?: record, connectionState?: record, serverVersion?: string}
export def "clusters Update" [
  id.value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updatedFields: list
  --idtype: string # type is the type of the specified cluster identifier ( "server" - default, "name" ).
  --annotations: record
  --clusterResources: oneof<nothing, bool> # Indicates if cluster level resources should be managed. This setting is used only if cluster is connected in a namespaced mode.
  --config: record # ClusterConfig is the configuration attributes. This structure is subset of the go-client rest.Config with annotations added for marshalling. — shape: {awsAuthConfig?: record, bearerToken?: string, disableCompression?: bool, execProviderConfig?: record, password?: string, proxyUrl?: string, tlsClientConfig?: record, username?: string}
  --connectionState: record # shape: {attemptedAt?: string, message?: string, status?: string}
  --info: record # shape: {apiVersions?: list, applicationsCount?: int, cacheInfo?: record, connectionState?: record, serverVersion?: string}
  --labels: record
  --name: string
  --namespaces: list # Holds list of namespaces which are accessible in that cluster. Cluster level resources will be ignored if namespace list is not empty.
  --project: string
  --refreshRequestedAt: string # Time is a wrapper around time.Time which supports correct marshaling to YAML and JSON.  Wrappers are provided for many of the factory methods that the time package offers.  +protobuf.options.marshal=false +protobuf.as=Timestamp +protobuf.options.(gogoproto.goproto_stringer)=false (format: date-time)
  --server: string
  --serverVersion: string
  --shard: int # Shard contains optional shard number. Calculated on the fly by the application controller if not specified. (format: int64)
]: any -> record<annotations: record, clusterResources: bool, config: record<awsAuthConfig: record<clusterName: string, profile: string, roleARN: string>, bearerToken: string, disableCompression: bool, execProviderConfig: record<apiVersion: string, args: list, command: string, config: record, env: record, installHint: string, provideClusterInfo: bool>, password: string, proxyUrl: string, tlsClientConfig: record<caData: string, certData: string, insecure: bool, keyData: string, serverName: string>, username: string>, connectionState: record<attemptedAt: string, message: string, status: string>, info: record<apiVersions: list<string>, applicationsCount: int, cacheInfo: record<apisCount: int, lastCacheSyncTime: string, resourcesCount: int>, connectionState: record<attemptedAt: string, message: string, status: string>, serverVersion: string>, labels: record, name: string, namespaces: list<string>, project: string, refreshRequestedAt: string, server: string, serverVersion: string, shard: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedFields" $updatedFields "multi") (serialize-qp "id.type" $idtype "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/clusters/($id.value)" $qp)
  let body = {annotations: $annotations, clusterResources: $clusterResources, config: $config, connectionState: $connectionState, info: $info, labels: $labels, name: $name, namespaces: $namespaces, project: $project, refreshRequestedAt: $refreshRequestedAt, server: $server, serverVersion: $serverVersion, shard: $shard} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete deletes a cluster
#
# DELETE /api/v1/clusters/{id.value}
# operationId: ClusterService_Delete
export def "clusters Delete" [
  id.value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --server: string
  --name: string
  --idtype: string # type is the type of the specified cluster identifier ( "server" - default, "name" ).
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "server" $server "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "id.type" $idtype "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/clusters/($id.value)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# InvalidateCache invalidates cluster cache
#
# POST /api/v1/clusters/{id.value}/invalidate-cache
# operationId: ClusterService_InvalidateCache
export def "clusters-invalidate-cache InvalidateCache" [
  id.value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<annotations: record, clusterResources: bool, config: record<awsAuthConfig: record<clusterName: string, profile: string, roleARN: string>, bearerToken: string, disableCompression: bool, execProviderConfig: record<apiVersion: string, args: list, command: string, config: record, env: record, installHint: string, provideClusterInfo: bool>, password: string, proxyUrl: string, tlsClientConfig: record<caData: string, certData: string, insecure: bool, keyData: string, serverName: string>, username: string>, connectionState: record<attemptedAt: string, message: string, status: string>, info: record<apiVersions: list<string>, applicationsCount: int, cacheInfo: record<apisCount: int, lastCacheSyncTime: string, resourcesCount: int>, connectionState: record<attemptedAt: string, message: string, status: string>, serverVersion: string>, labels: record, name: string, namespaces: list<string>, project: string, refreshRequestedAt: string, server: string, serverVersion: string, shard: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($id.value)/invalidate-cache")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# RotateAuth rotates the bearer token used for a cluster
#
# POST /api/v1/clusters/{id.value}/rotate-auth
# operationId: ClusterService_RotateAuth
export def "clusters-rotate-auth RotateAuth" [
  id.value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/clusters/($id.value)/rotate-auth")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all available repository certificates
#
# GET /api/v1/gpgkeys
# operationId: GPGKeyService_List
export def "gpgkeys List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --keyID: string # The GPG key ID to query for.
]: nothing -> record<items: table<fingerprint: string, keyData: string, keyID: string, owner: string, subType: string, trust: string>, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string, shardInfo: record<selector: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keyID" $keyID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/gpgkeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create one or more GPG public keys in the server's configuration
#
# POST /api/v1/gpgkeys
# operationId: GPGKeyService_Create
export def "gpgkeys Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upsert: oneof<nothing, bool> # Whether to upsert already existing public keys.
  --fingerprint: string
  --keyData: string
  --keyID: string
  --owner: string
  --subType: string
  --trust: string
]: any -> record<created: record<items: list<record>, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string, shardInfo: record>>, skipped: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upsert" $upsert "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/gpgkeys" $qp)
  let body = {fingerprint: $fingerprint, keyData: $keyData, keyID: $keyID, owner: $owner, subType: $subType, trust: $trust} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete specified GPG public key from the server's configuration
#
# DELETE /api/v1/gpgkeys
# operationId: GPGKeyService_Delete
export def "gpgkeys Delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --keyID: string # The GPG key ID to query for.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keyID" $keyID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/gpgkeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about specified GPG public key from the server
#
# GET /api/v1/gpgkeys/{keyID}
# operationId: GPGKeyService_Get
export def "gpgkeys Get" [
  keyID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<fingerprint: string, keyData: string, keyID: string, owner: string, subType: string, trust: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/gpgkeys/($keyID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List returns list of services
#
# GET /api/v1/notifications/services
# operationId: NotificationService_ListServices
export def "notifications-services ListServices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<items: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/notifications/services")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List returns list of templates
#
# GET /api/v1/notifications/templates
# operationId: NotificationService_ListTemplates
export def "notifications-templates ListTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<items: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/notifications/templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List returns list of triggers
#
# GET /api/v1/notifications/triggers
# operationId: NotificationService_ListTriggers
export def "notifications-triggers ListTriggers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<items: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/notifications/triggers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List returns list of projects
#
# GET /api/v1/projects
# operationId: ProjectService_List
export def "projects List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
]: nothing -> record<items: table<metadata: record, spec: record, status: record>, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string, shardInfo: record<selector: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new project
#
# POST /api/v1/projects
# operationId: ProjectService_Create
# --project shape: {metadata?: record, spec?: record, status?: record}
export def "projects Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --project: record # shape: {metadata?: record, spec?: record, status?: record}
  --upsert: oneof<nothing, bool>
]: any -> record<metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<clusterResourceBlacklist: list<record>, clusterResourceWhitelist: list<record>, description: string, destinationServiceAccounts: list<record>, destinations: list<record>, namespaceResourceBlacklist: list<record>, namespaceResourceWhitelist: list<record>, orphanedResources: record<ignore: list, warn: bool>, permitOnlyProjectScopedClusters: bool, roles: list<record>, signatureKeys: list<record>, sourceIntegrity: record<git: record>, sourceNamespaces: list<string>, sourceRepos: list<string>, syncWindows: list<record>>, status: record<jwtTokensByRole: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/projects")
  let body = {project: $project, upsert: $upsert} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get returns a project by name
#
# GET /api/v1/projects/{name}
# operationId: ProjectService_Get
export def "projects Get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<clusterResourceBlacklist: list<record>, clusterResourceWhitelist: list<record>, description: string, destinationServiceAccounts: list<record>, destinations: list<record>, namespaceResourceBlacklist: list<record>, namespaceResourceWhitelist: list<record>, orphanedResources: record<ignore: list, warn: bool>, permitOnlyProjectScopedClusters: bool, roles: list<record>, signatureKeys: list<record>, sourceIntegrity: record<git: record>, sourceNamespaces: list<string>, sourceRepos: list<string>, syncWindows: list<record>>, status: record<jwtTokensByRole: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete deletes a project
#
# DELETE /api/v1/projects/{name}
# operationId: ProjectService_Delete
export def "projects Delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GetDetailedProject returns a project that include project, global project and scoped resources by name
#
# GET /api/v1/projects/{name}/detailed
# operationId: ProjectService_GetDetailedProject
export def "projects-detailed GetDetailedProject" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<clusters: table<annotations: record, clusterResources: bool, config: record, connectionState: record, info: record, labels: record, name: string, namespaces: list, project: string, refreshRequestedAt: string, server: string, serverVersion: string, shard: int>, globalProjects: table<metadata: record, spec: record, status: record>, project: record<metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list, generateName: string, generation: int, labels: record, managedFields: list, name: string, namespace: string, ownerReferences: list, resourceVersion: string, selfLink: string, uid: string>, spec: record<clusterResourceBlacklist: list, clusterResourceWhitelist: list, description: string, destinationServiceAccounts: list, destinations: list, namespaceResourceBlacklist: list, namespaceResourceWhitelist: list, orphanedResources: record, permitOnlyProjectScopedClusters: bool, roles: list, signatureKeys: list, sourceIntegrity: record, sourceNamespaces: list, sourceRepos: list, syncWindows: list>, status: record<jwtTokensByRole: record>>, repositories: table<azureActiveDirectoryEndpoint: string, azureServicePrincipalClientId: string, azureServicePrincipalClientSecret: string, azureServicePrincipalTenantId: string, bearerToken: string, connectionState: record, depth: int, enableLfs: bool, enableOCI: bool, forceHttpBasicAuth: bool, gcpServiceAccountKey: string, githubAppEnterpriseBaseUrl: string, githubAppID: int, githubAppInstallationID: int, githubAppPrivateKey: string, inheritedCreds: bool, insecure: bool, insecureIgnoreHostKey: bool, insecureOCIForceHttp: bool, name: string, noProxy: string, password: string, project: string, proxy: string, repo: string, sshPrivateKey: string, tlsClientCertData: string, tlsClientCertKey: string, type: string, useAzureWorkloadIdentity: bool, username: string, webhookManifestCacheWarmDisabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($name)/detailed")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListEvents returns a list of project events
#
# GET /api/v1/projects/{name}/events
# operationId: ProjectService_ListEvents
export def "projects-events ListEvents" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<items: table<action: string, count: int, eventTime: record, firstTimestamp: string, involvedObject: record, lastTimestamp: string, message: string, metadata: record, reason: string, related: record, reportingComponent: string, reportingInstance: string, series: record, source: record, type: string>, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string, shardInfo: record<selector: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($name)/events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get returns a virtual project by name
#
# GET /api/v1/projects/{name}/globalprojects
# operationId: ProjectService_GetGlobalProjects
export def "projects-globalprojects GetGlobalProjects" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<items: table<metadata: record, spec: record, status: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($name)/globalprojects")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListLinks returns all deep links for the particular project
#
# GET /api/v1/projects/{name}/links
# operationId: ProjectService_ListLinks
export def "projects-links ListLinks" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<items: table<description: string, iconClass: string, title: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($name)/links")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GetSchedulesState returns true if there are any active sync syncWindows
#
# GET /api/v1/projects/{name}/syncwindows
# operationId: ProjectService_GetSyncWindowsState
export def "projects-syncwindows GetSyncWindowsState" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<windows: table<andOperator: bool, applications: list, clusters: list, description: string, duration: string, kind: string, manualSync: bool, namespaces: list, schedule: string, syncOverrun: bool, timeZone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($name)/syncwindows")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update updates a project
#
# PUT /api/v1/projects/{project.metadata.name}
# operationId: ProjectService_Update
# --project shape: {metadata?: record, spec?: record, status?: record}
export def "projects Update" [
  project.metadata.name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --project: record # shape: {metadata?: record, spec?: record, status?: record}
]: any -> record<metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<clusterResourceBlacklist: list<record>, clusterResourceWhitelist: list<record>, description: string, destinationServiceAccounts: list<record>, destinations: list<record>, namespaceResourceBlacklist: list<record>, namespaceResourceWhitelist: list<record>, orphanedResources: record<ignore: list, warn: bool>, permitOnlyProjectScopedClusters: bool, roles: list<record>, signatureKeys: list<record>, sourceIntegrity: record<git: record>, sourceNamespaces: list<string>, sourceRepos: list<string>, syncWindows: list<record>>, status: record<jwtTokensByRole: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project.metadata.name)")
  let body = {project: $project} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new project token
#
# POST /api/v1/projects/{project}/roles/{role}/token
# operationId: ProjectService_CreateToken
export def "projects-roles-token CreateToken" [
  project: string
  role: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --expiresIn: int # format: int64
  --id: string
  --body-project: string
  --body-role: string
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project)/roles/($role)/token")
  let body = {description: $description, expiresIn: $expiresIn, id: $id, project: $body_project, role: $body_role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a new project token
#
# DELETE /api/v1/projects/{project}/roles/{role}/token/{iat}
# operationId: ProjectService_DeleteToken
export def "projects-roles-token DeleteToken" [
  project: string
  role: string
  iat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/projects/($project)/roles/($role)/token/($iat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListRepositoryCredentials gets a list of all configured repository credential sets
#
# GET /api/v1/repocreds
# operationId: RepoCredsService_ListRepositoryCredentials
export def "repocreds ListRepositoryCredentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-url: string # Repo URL for query.
]: nothing -> record<items: table<azureActiveDirectoryEndpoint: string, azureServicePrincipalClientId: string, azureServicePrincipalClientSecret: string, azureServicePrincipalTenantId: string, bearerToken: string, enableOCI: bool, forceHttpBasicAuth: bool, gcpServiceAccountKey: string, githubAppEnterpriseBaseUrl: string, githubAppID: int, githubAppInstallationID: int, githubAppPrivateKey: string, insecureOCIForceHttp: bool, noProxy: string, password: string, proxy: string, sshPrivateKey: string, tlsClientCertData: string, tlsClientCertKey: string, type: string, url: string, useAzureWorkloadIdentity: bool, username: string>, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string, shardInfo: record<selector: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $qp_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/repocreds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CreateRepositoryCredentials creates a new repository credential set
#
# POST /api/v1/repocreds
# operationId: RepoCredsService_CreateRepositoryCredentials
export def "repocreds CreateRepositoryCredentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upsert: oneof<nothing, bool> # Whether to create in upsert mode.
  --azureActiveDirectoryEndpoint: string
  --azureServicePrincipalClientId: string
  --azureServicePrincipalClientSecret: string
  --azureServicePrincipalTenantId: string
  --bearerToken: string
  --enableOCI: oneof<nothing, bool>
  --forceHttpBasicAuth: oneof<nothing, bool>
  --gcpServiceAccountKey: string
  --githubAppEnterpriseBaseUrl: string
  --githubAppID: int # format: int64
  --githubAppInstallationID: int # format: int64
  --githubAppPrivateKey: string
  --insecureOCIForceHttp: oneof<nothing, bool> # InsecureOCIForceHttp specifies whether the connection to the repository uses TLS at _all_. If true, no TLS. This flag is applicable for OCI repos only.
  --noProxy: string
  --password: string
  --proxy: string
  --sshPrivateKey: string
  --tlsClientCertData: string
  --tlsClientCertKey: string
  --type: string # Type specifies the type of the repoCreds. Can be either "git", "helm" or "oci". "git" is assumed if empty or absent.
  --body-url: string
  --useAzureWorkloadIdentity: oneof<nothing, bool>
  --username: string
]: any -> record<azureActiveDirectoryEndpoint: string, azureServicePrincipalClientId: string, azureServicePrincipalClientSecret: string, azureServicePrincipalTenantId: string, bearerToken: string, enableOCI: bool, forceHttpBasicAuth: bool, gcpServiceAccountKey: string, githubAppEnterpriseBaseUrl: string, githubAppID: int, githubAppInstallationID: int, githubAppPrivateKey: string, insecureOCIForceHttp: bool, noProxy: string, password: string, proxy: string, sshPrivateKey: string, tlsClientCertData: string, tlsClientCertKey: string, type: string, url: string, useAzureWorkloadIdentity: bool, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upsert" $upsert "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/repocreds" $qp)
  let body = {azureActiveDirectoryEndpoint: $azureActiveDirectoryEndpoint, azureServicePrincipalClientId: $azureServicePrincipalClientId, azureServicePrincipalClientSecret: $azureServicePrincipalClientSecret, azureServicePrincipalTenantId: $azureServicePrincipalTenantId, bearerToken: $bearerToken, enableOCI: $enableOCI, forceHttpBasicAuth: $forceHttpBasicAuth, gcpServiceAccountKey: $gcpServiceAccountKey, githubAppEnterpriseBaseUrl: $githubAppEnterpriseBaseUrl, githubAppID: $githubAppID, githubAppInstallationID: $githubAppInstallationID, githubAppPrivateKey: $githubAppPrivateKey, insecureOCIForceHttp: $insecureOCIForceHttp, noProxy: $noProxy, password: $password, proxy: $proxy, sshPrivateKey: $sshPrivateKey, tlsClientCertData: $tlsClientCertData, tlsClientCertKey: $tlsClientCertKey, type: $type, url: $body_url, useAzureWorkloadIdentity: $useAzureWorkloadIdentity, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UpdateRepositoryCredentials updates a repository credential set
#
# PUT /api/v1/repocreds/{creds.url}
# operationId: RepoCredsService_UpdateRepositoryCredentials
export def "repocreds UpdateRepositoryCredentials" [
  creds.url: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --azureActiveDirectoryEndpoint: string
  --azureServicePrincipalClientId: string
  --azureServicePrincipalClientSecret: string
  --azureServicePrincipalTenantId: string
  --bearerToken: string
  --enableOCI: oneof<nothing, bool>
  --forceHttpBasicAuth: oneof<nothing, bool>
  --gcpServiceAccountKey: string
  --githubAppEnterpriseBaseUrl: string
  --githubAppID: int # format: int64
  --githubAppInstallationID: int # format: int64
  --githubAppPrivateKey: string
  --insecureOCIForceHttp: oneof<nothing, bool> # InsecureOCIForceHttp specifies whether the connection to the repository uses TLS at _all_. If true, no TLS. This flag is applicable for OCI repos only.
  --noProxy: string
  --password: string
  --proxy: string
  --sshPrivateKey: string
  --tlsClientCertData: string
  --tlsClientCertKey: string
  --type: string # Type specifies the type of the repoCreds. Can be either "git", "helm" or "oci". "git" is assumed if empty or absent.
  --body-url: string
  --useAzureWorkloadIdentity: oneof<nothing, bool>
  --username: string
]: any -> record<azureActiveDirectoryEndpoint: string, azureServicePrincipalClientId: string, azureServicePrincipalClientSecret: string, azureServicePrincipalTenantId: string, bearerToken: string, enableOCI: bool, forceHttpBasicAuth: bool, gcpServiceAccountKey: string, githubAppEnterpriseBaseUrl: string, githubAppID: int, githubAppInstallationID: int, githubAppPrivateKey: string, insecureOCIForceHttp: bool, noProxy: string, password: string, proxy: string, sshPrivateKey: string, tlsClientCertData: string, tlsClientCertKey: string, type: string, url: string, useAzureWorkloadIdentity: bool, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/repocreds/($creds.url)")
  let body = {azureActiveDirectoryEndpoint: $azureActiveDirectoryEndpoint, azureServicePrincipalClientId: $azureServicePrincipalClientId, azureServicePrincipalClientSecret: $azureServicePrincipalClientSecret, azureServicePrincipalTenantId: $azureServicePrincipalTenantId, bearerToken: $bearerToken, enableOCI: $enableOCI, forceHttpBasicAuth: $forceHttpBasicAuth, gcpServiceAccountKey: $gcpServiceAccountKey, githubAppEnterpriseBaseUrl: $githubAppEnterpriseBaseUrl, githubAppID: $githubAppID, githubAppInstallationID: $githubAppInstallationID, githubAppPrivateKey: $githubAppPrivateKey, insecureOCIForceHttp: $insecureOCIForceHttp, noProxy: $noProxy, password: $password, proxy: $proxy, sshPrivateKey: $sshPrivateKey, tlsClientCertData: $tlsClientCertData, tlsClientCertKey: $tlsClientCertKey, type: $type, url: $body_url, useAzureWorkloadIdentity: $useAzureWorkloadIdentity, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DeleteRepositoryCredentials deletes a repository credential set from the configuration
#
# DELETE /api/v1/repocreds/{url}
# operationId: RepoCredsService_DeleteRepositoryCredentials
export def "repocreds DeleteRepositoryCredentials" [
  url: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/repocreds/($url)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListRepositories gets a list of all configured repositories
#
# GET /api/v1/repositories
# operationId: RepositoryService_ListRepositories
export def "repositories ListRepositories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --repo: string # Repo URL for query.
  --forceRefresh: oneof<nothing, bool> # Whether to force a cache refresh on repo's connection state.
  --appProject: string # App project for query.
]: nothing -> record<items: table<azureActiveDirectoryEndpoint: string, azureServicePrincipalClientId: string, azureServicePrincipalClientSecret: string, azureServicePrincipalTenantId: string, bearerToken: string, connectionState: record, depth: int, enableLfs: bool, enableOCI: bool, forceHttpBasicAuth: bool, gcpServiceAccountKey: string, githubAppEnterpriseBaseUrl: string, githubAppID: int, githubAppInstallationID: int, githubAppPrivateKey: string, inheritedCreds: bool, insecure: bool, insecureIgnoreHostKey: bool, insecureOCIForceHttp: bool, name: string, noProxy: string, password: string, project: string, proxy: string, repo: string, sshPrivateKey: string, tlsClientCertData: string, tlsClientCertKey: string, type: string, useAzureWorkloadIdentity: bool, username: string, webhookManifestCacheWarmDisabled: bool>, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string, shardInfo: record<selector: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "repo" $repo "scalar") (serialize-qp "forceRefresh" $forceRefresh "scalar") (serialize-qp "appProject" $appProject "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/repositories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CreateRepository creates a new repository configuration
#
# POST /api/v1/repositories
# operationId: RepositoryService_CreateRepository
# --connectionState shape: {attemptedAt?: string, message?: string, status?: string}
export def "repositories CreateRepository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upsert: oneof<nothing, bool> # Whether to create in upsert mode.
  --credsOnly: oneof<nothing, bool> # Whether to operate on credential set instead of repository.
  --azureActiveDirectoryEndpoint: string
  --azureServicePrincipalClientId: string
  --azureServicePrincipalClientSecret: string
  --azureServicePrincipalTenantId: string
  --bearerToken: string
  --connectionState: record # shape: {attemptedAt?: string, message?: string, status?: string}
  --depth: int # Depth specifies the depth for shallow clones. A value of 0 or omitting the field indicates a full clone. (format: int64)
  --enableLfs: oneof<nothing, bool> # EnableLFS specifies whether git-lfs support should be enabled for this repo. Only valid for Git repositories.
  --enableOCI: oneof<nothing, bool>
  --forceHttpBasicAuth: oneof<nothing, bool>
  --gcpServiceAccountKey: string
  --githubAppEnterpriseBaseUrl: string
  --githubAppID: int # format: int64
  --githubAppInstallationID: int # format: int64
  --githubAppPrivateKey: string
  --inheritedCreds: oneof<nothing, bool>
  --body-insecure: oneof<nothing, bool>
  --insecureIgnoreHostKey: oneof<nothing, bool>
  --insecureOCIForceHttp: oneof<nothing, bool> # InsecureOCIForceHttp specifies whether the connection to the repository uses TLS at _all_. If true, no TLS. This flag is applicable for OCI repos only.
  --name: string
  --noProxy: string
  --password: string
  --project: string
  --proxy: string
  --repo: string
  --sshPrivateKey: string # SSHPrivateKey contains the PEM data for authenticating at the repo server. Only used with Git repos.
  --tlsClientCertData: string
  --tlsClientCertKey: string
  --type: string # Type specifies the type of the repo. Can be either "git" or "helm. "git" is assumed if empty or absent.
  --useAzureWorkloadIdentity: oneof<nothing, bool>
  --username: string
  --webhookManifestCacheWarmDisabled: oneof<nothing, bool> # WebhookManifestCacheWarmDisabled disables manifest cache warming during webhook processing for this repository. When set, webhook handlers will only trigger reconciliation for affected applications and skip Redis cache operations for unaffected ones. Recommended for large monorepos with plain YAML manifests.
]: any -> record<azureActiveDirectoryEndpoint: string, azureServicePrincipalClientId: string, azureServicePrincipalClientSecret: string, azureServicePrincipalTenantId: string, bearerToken: string, connectionState: record<attemptedAt: string, message: string, status: string>, depth: int, enableLfs: bool, enableOCI: bool, forceHttpBasicAuth: bool, gcpServiceAccountKey: string, githubAppEnterpriseBaseUrl: string, githubAppID: int, githubAppInstallationID: int, githubAppPrivateKey: string, inheritedCreds: bool, insecure: bool, insecureIgnoreHostKey: bool, insecureOCIForceHttp: bool, name: string, noProxy: string, password: string, project: string, proxy: string, repo: string, sshPrivateKey: string, tlsClientCertData: string, tlsClientCertKey: string, type: string, useAzureWorkloadIdentity: bool, username: string, webhookManifestCacheWarmDisabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upsert" $upsert "scalar") (serialize-qp "credsOnly" $credsOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/repositories" $qp)
  let body = {azureActiveDirectoryEndpoint: $azureActiveDirectoryEndpoint, azureServicePrincipalClientId: $azureServicePrincipalClientId, azureServicePrincipalClientSecret: $azureServicePrincipalClientSecret, azureServicePrincipalTenantId: $azureServicePrincipalTenantId, bearerToken: $bearerToken, connectionState: $connectionState, depth: $depth, enableLfs: $enableLfs, enableOCI: $enableOCI, forceHttpBasicAuth: $forceHttpBasicAuth, gcpServiceAccountKey: $gcpServiceAccountKey, githubAppEnterpriseBaseUrl: $githubAppEnterpriseBaseUrl, githubAppID: $githubAppID, githubAppInstallationID: $githubAppInstallationID, githubAppPrivateKey: $githubAppPrivateKey, inheritedCreds: $inheritedCreds, insecure: $body_insecure, insecureIgnoreHostKey: $insecureIgnoreHostKey, insecureOCIForceHttp: $insecureOCIForceHttp, name: $name, noProxy: $noProxy, password: $password, project: $project, proxy: $proxy, repo: $repo, sshPrivateKey: $sshPrivateKey, tlsClientCertData: $tlsClientCertData, tlsClientCertKey: $tlsClientCertKey, type: $type, useAzureWorkloadIdentity: $useAzureWorkloadIdentity, username: $username, webhookManifestCacheWarmDisabled: $webhookManifestCacheWarmDisabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UpdateRepository updates a repository configuration
#
# PUT /api/v1/repositories/{repo.repo}
# operationId: RepositoryService_UpdateRepository
# --connectionState shape: {attemptedAt?: string, message?: string, status?: string}
export def "repositories UpdateRepository" [
  repo.repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --azureActiveDirectoryEndpoint: string
  --azureServicePrincipalClientId: string
  --azureServicePrincipalClientSecret: string
  --azureServicePrincipalTenantId: string
  --bearerToken: string
  --connectionState: record # shape: {attemptedAt?: string, message?: string, status?: string}
  --depth: int # Depth specifies the depth for shallow clones. A value of 0 or omitting the field indicates a full clone. (format: int64)
  --enableLfs: oneof<nothing, bool> # EnableLFS specifies whether git-lfs support should be enabled for this repo. Only valid for Git repositories.
  --enableOCI: oneof<nothing, bool>
  --forceHttpBasicAuth: oneof<nothing, bool>
  --gcpServiceAccountKey: string
  --githubAppEnterpriseBaseUrl: string
  --githubAppID: int # format: int64
  --githubAppInstallationID: int # format: int64
  --githubAppPrivateKey: string
  --inheritedCreds: oneof<nothing, bool>
  --body-insecure: oneof<nothing, bool>
  --insecureIgnoreHostKey: oneof<nothing, bool>
  --insecureOCIForceHttp: oneof<nothing, bool> # InsecureOCIForceHttp specifies whether the connection to the repository uses TLS at _all_. If true, no TLS. This flag is applicable for OCI repos only.
  --name: string
  --noProxy: string
  --password: string
  --project: string
  --proxy: string
  --repo: string
  --sshPrivateKey: string # SSHPrivateKey contains the PEM data for authenticating at the repo server. Only used with Git repos.
  --tlsClientCertData: string
  --tlsClientCertKey: string
  --type: string # Type specifies the type of the repo. Can be either "git" or "helm. "git" is assumed if empty or absent.
  --useAzureWorkloadIdentity: oneof<nothing, bool>
  --username: string
  --webhookManifestCacheWarmDisabled: oneof<nothing, bool> # WebhookManifestCacheWarmDisabled disables manifest cache warming during webhook processing for this repository. When set, webhook handlers will only trigger reconciliation for affected applications and skip Redis cache operations for unaffected ones. Recommended for large monorepos with plain YAML manifests.
]: any -> record<azureActiveDirectoryEndpoint: string, azureServicePrincipalClientId: string, azureServicePrincipalClientSecret: string, azureServicePrincipalTenantId: string, bearerToken: string, connectionState: record<attemptedAt: string, message: string, status: string>, depth: int, enableLfs: bool, enableOCI: bool, forceHttpBasicAuth: bool, gcpServiceAccountKey: string, githubAppEnterpriseBaseUrl: string, githubAppID: int, githubAppInstallationID: int, githubAppPrivateKey: string, inheritedCreds: bool, insecure: bool, insecureIgnoreHostKey: bool, insecureOCIForceHttp: bool, name: string, noProxy: string, password: string, project: string, proxy: string, repo: string, sshPrivateKey: string, tlsClientCertData: string, tlsClientCertKey: string, type: string, useAzureWorkloadIdentity: bool, username: string, webhookManifestCacheWarmDisabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/repositories/($repo.repo)")
  let body = {azureActiveDirectoryEndpoint: $azureActiveDirectoryEndpoint, azureServicePrincipalClientId: $azureServicePrincipalClientId, azureServicePrincipalClientSecret: $azureServicePrincipalClientSecret, azureServicePrincipalTenantId: $azureServicePrincipalTenantId, bearerToken: $bearerToken, connectionState: $connectionState, depth: $depth, enableLfs: $enableLfs, enableOCI: $enableOCI, forceHttpBasicAuth: $forceHttpBasicAuth, gcpServiceAccountKey: $gcpServiceAccountKey, githubAppEnterpriseBaseUrl: $githubAppEnterpriseBaseUrl, githubAppID: $githubAppID, githubAppInstallationID: $githubAppInstallationID, githubAppPrivateKey: $githubAppPrivateKey, inheritedCreds: $inheritedCreds, insecure: $body_insecure, insecureIgnoreHostKey: $insecureIgnoreHostKey, insecureOCIForceHttp: $insecureOCIForceHttp, name: $name, noProxy: $noProxy, password: $password, project: $project, proxy: $proxy, repo: $repo, sshPrivateKey: $sshPrivateKey, tlsClientCertData: $tlsClientCertData, tlsClientCertKey: $tlsClientCertKey, type: $type, useAzureWorkloadIdentity: $useAzureWorkloadIdentity, username: $username, webhookManifestCacheWarmDisabled: $webhookManifestCacheWarmDisabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get returns a repository or its credentials
#
# GET /api/v1/repositories/{repo}
# operationId: RepositoryService_Get
export def "repositories Get" [
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forceRefresh: oneof<nothing, bool> # Whether to force a cache refresh on repo's connection state.
  --appProject: string # App project for query.
]: nothing -> record<azureActiveDirectoryEndpoint: string, azureServicePrincipalClientId: string, azureServicePrincipalClientSecret: string, azureServicePrincipalTenantId: string, bearerToken: string, connectionState: record<attemptedAt: string, message: string, status: string>, depth: int, enableLfs: bool, enableOCI: bool, forceHttpBasicAuth: bool, gcpServiceAccountKey: string, githubAppEnterpriseBaseUrl: string, githubAppID: int, githubAppInstallationID: int, githubAppPrivateKey: string, inheritedCreds: bool, insecure: bool, insecureIgnoreHostKey: bool, insecureOCIForceHttp: bool, name: string, noProxy: string, password: string, project: string, proxy: string, repo: string, sshPrivateKey: string, tlsClientCertData: string, tlsClientCertKey: string, type: string, useAzureWorkloadIdentity: bool, username: string, webhookManifestCacheWarmDisabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceRefresh" $forceRefresh "scalar") (serialize-qp "appProject" $appProject "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/repositories/($repo)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DeleteRepository deletes a repository from the configuration
#
# DELETE /api/v1/repositories/{repo}
# operationId: RepositoryService_DeleteRepository
export def "repositories DeleteRepository" [
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forceRefresh: oneof<nothing, bool> # Whether to force a cache refresh on repo's connection state.
  --appProject: string # App project for query.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceRefresh" $forceRefresh "scalar") (serialize-qp "appProject" $appProject "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/repositories/($repo)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListApps returns list of apps in the repo
#
# GET /api/v1/repositories/{repo}/apps
# operationId: RepositoryService_ListApps
export def "repositories-apps ListApps" [
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string
  --appName: string
  --appProject: string
]: nothing -> record<items: table<path: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "revision" $revision "scalar") (serialize-qp "appName" $appName "scalar") (serialize-qp "appProject" $appProject "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/repositories/($repo)/apps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GetHelmCharts returns list of helm charts in the specified repository
#
# GET /api/v1/repositories/{repo}/helmcharts
# operationId: RepositoryService_GetHelmCharts
export def "repositories-helmcharts GetHelmCharts" [
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forceRefresh: oneof<nothing, bool> # Whether to force a cache refresh on repo's connection state.
  --appProject: string # App project for query.
]: nothing -> record<items: table<name: string, versions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceRefresh" $forceRefresh "scalar") (serialize-qp "appProject" $appProject "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/repositories/($repo)/helmcharts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/repositories/{repo}/oci-tags
#
# operationId: RepositoryService_ListOCITags
export def "repositories-oci-tags ListOCITags" [
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forceRefresh: oneof<nothing, bool> # Whether to force a cache refresh on repo's connection state.
  --appProject: string # App project for query.
]: nothing -> record<branches: list<string>, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceRefresh" $forceRefresh "scalar") (serialize-qp "appProject" $appProject "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/repositories/($repo)/oci-tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/repositories/{repo}/refs
#
# operationId: RepositoryService_ListRefs
export def "repositories-refs ListRefs" [
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forceRefresh: oneof<nothing, bool> # Whether to force a cache refresh on repo's connection state.
  --appProject: string # App project for query.
]: nothing -> record<branches: list<string>, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceRefresh" $forceRefresh "scalar") (serialize-qp "appProject" $appProject "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/repositories/($repo)/refs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ValidateAccess validates access to a repository with given parameters
#
# POST /api/v1/repositories/{repo}/validate
# operationId: RepositoryService_ValidateAccess
export def "repositories-validate ValidateAccess" [
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Username for accessing repo.
  --password: string # Password for accessing repo.
  --sshPrivateKey: string # Private key data for accessing SSH repository.
  --qp-insecure: oneof<nothing, bool> # Whether to skip certificate or host key validation.
  --tlsClientCertData: string # TLS client cert data for accessing HTTPS repository.
  --tlsClientCertKey: string # TLS client cert key for accessing HTTPS repository.
  --type: string # The type of the repo.
  --name: string # The name of the repo.
  --enableOci: oneof<nothing, bool> # Whether helm-oci support should be enabled for this repo.
  --githubAppPrivateKey: string # Github App Private Key PEM data.
  --githubAppID: string # Github App ID of the app used to access the repo. (format: int64)
  --githubAppInstallationID: string # Github App Installation ID of the installed GitHub App. (format: int64)
  --githubAppEnterpriseBaseUrl: string # Github App Enterprise base url if empty will default to https://api.github.com.
  --proxy: string # HTTP/HTTPS proxy to access the repository.
  --project: string # Reference between project and repository that allow you automatically to be added as item inside SourceRepos project entity.
  --gcpServiceAccountKey: string # Google Cloud Platform service account key.
  --forceHttpBasicAuth: oneof<nothing, bool> # Whether to force HTTP basic auth.
  --useAzureWorkloadIdentity: oneof<nothing, bool> # Whether to use azure workload identity for authentication.
  --bearerToken: string # BearerToken contains the bearer token used for Git auth at the repo server.
  --insecureOciForceHttp: oneof<nothing, bool> # Whether https should be disabled for an OCI repo.
  --azureServicePrincipalClientId: string # Azure Service Principal Client ID.
  --azureServicePrincipalClientSecret: string # Azure Service Principal Client Secret.
  --azureServicePrincipalTenantId: string # Azure Service Principal Tenant ID.
  --azureActiveDirectoryEndpoint: string # Azure Active Directory Endpoint.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "sshPrivateKey" $sshPrivateKey "scalar") (serialize-qp "insecure" $qp_insecure "scalar") (serialize-qp "tlsClientCertData" $tlsClientCertData "scalar") (serialize-qp "tlsClientCertKey" $tlsClientCertKey "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "enableOci" $enableOci "scalar") (serialize-qp "githubAppPrivateKey" $githubAppPrivateKey "scalar") (serialize-qp "githubAppID" $githubAppID "scalar") (serialize-qp "githubAppInstallationID" $githubAppInstallationID "scalar") (serialize-qp "githubAppEnterpriseBaseUrl" $githubAppEnterpriseBaseUrl "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "gcpServiceAccountKey" $gcpServiceAccountKey "scalar") (serialize-qp "forceHttpBasicAuth" $forceHttpBasicAuth "scalar") (serialize-qp "useAzureWorkloadIdentity" $useAzureWorkloadIdentity "scalar") (serialize-qp "bearerToken" $bearerToken "scalar") (serialize-qp "insecureOciForceHttp" $insecureOciForceHttp "scalar") (serialize-qp "azureServicePrincipalClientId" $azureServicePrincipalClientId "scalar") (serialize-qp "azureServicePrincipalClientSecret" $azureServicePrincipalClientSecret "scalar") (serialize-qp "azureServicePrincipalTenantId" $azureServicePrincipalTenantId "scalar") (serialize-qp "azureActiveDirectoryEndpoint" $azureActiveDirectoryEndpoint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/repositories/($repo)/validate" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GetAppDetails returns application details by given path
#
# POST /api/v1/repositories/{source.repoURL}/appdetails
# operationId: RepositoryService_GetAppDetails
# --source shape: {chart?: string, directory?: record, helm?: record, kustomize?: record, name?: string, path?: string, plugin?: record, ref?: string, repoURL?: string, tagPrefix?: string, targetRevision?: string}
export def "repositories-appdetails GetAppDetails" [
  source.repoURL: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appName: string
  --appProject: string
  --body-source: record # shape: {chart?: string, directory?: record, helm?: record, kustomize?: record, name?: string, path?: string, plugin?: record, ref?: string, repoURL?: string, tagPrefix?: string, targetRevision?: string}
  --sourceIndex: int # format: int32
  --versionId: int # format: int32
]: any -> record<directory: record, helm: record<fileParameters: list<record>, name: string, parameters: list<record>, valueFiles: list<string>, values: string>, kustomize: record<images: list<string>>, plugin: record<parametersAnnouncement: list<record>>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/repositories/($source.repoURL)/appdetails")
  let body = {appName: $appName, appProject: $appProject, source: $body_source, sourceIndex: $sourceIndex, versionId: $versionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new JWT for authentication and set a cookie if using HTTP
#
# POST /api/v1/session
# operationId: SessionService_Create
export def "session Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string
  --body-token: string
  --username: string
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/session")
  let body = {password: $password, token: $body_token, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an existing JWT cookie if using HTTP
#
# DELETE /api/v1/session
# operationId: SessionService_Delete
export def "session Delete" [
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
  let full_url = (build-url $base "/api/v1/session")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the current user's info
#
# GET /api/v1/session/userinfo
# operationId: SessionService_GetUserInfo
export def "session-userinfo GetUserInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<groups: list<string>, iss: string, loggedIn: bool, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/session/userinfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get returns Argo CD settings
#
# GET /api/v1/settings
# operationId: SettingsService_Get
export def "settings Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<additionalUrls: list<string>, appLabelKey: string, appsInAnyNamespaceEnabled: bool, configManagementPlugins: table<generate: record, init: record, lockRepo: bool, name: string>, controllerNamespace: string, dexConfig: record<connectors: list<record>>, execEnabled: bool, googleAnalytics: record<anonymizeUsers: bool, trackingID: string>, help: record<binaryUrls: record, chatText: string, chatUrl: string>, hydratorEnabled: bool, impersonationEnabled: bool, installationID: string, kustomizeOptions: record<binaryPath: string, buildOptions: string, versions: list<record>>, kustomizeVersions: list<string>, oidcConfig: record<cliClientID: string, clientID: string, enablePKCEAuthentication: bool, idTokenClaims: record, issuer: string, name: string, scopes: list<string>>, passwordPattern: string, plugins: table<name: string>, resourceOverrides: record, statusBadgeEnabled: bool, statusBadgeRootUrl: string, syncWithReplaceAllowed: bool, trackingMethod: string, uiBannerContent: string, uiBannerPermanent: bool, uiBannerPosition: string, uiBannerURL: string, uiCssURL: string, url: string, userLoginsDisabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get returns Argo CD plugins
#
# GET /api/v1/settings/plugins
# operationId: SettingsService_GetPlugins
export def "settings-plugins GetPlugins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<plugins: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/settings/plugins")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Watch returns stream of application change events
#
# GET /api/v1/stream/applications
# operationId: ApplicationService_Watch
export def "stream-applications Watch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # the application's name.
  --refresh: string # forces application reconciliation if set to 'hard'.
  --projects: list # the project names to restrict returned list applications.
  --resourceVersion: string # when specified with a watch call, shows changes that occur after that particular version of a resource.
  --selector: string # the selector to restrict returned list to applications only with matched labels.
  --repo: string # the repoURL to restrict returned list applications.
  --appNamespace: string # the application's namespace.
  --project: list # the project names to restrict returned list applications (legacy name for backwards-compatibility).
]: nothing -> record<error: record<details: list<record>, grpc_code: int, http_code: int, http_status: string, message: string>, result: record<application: record<metadata: record, operation: record, spec: record, status: record>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "refresh" $refresh "scalar") (serialize-qp "projects" $projects "multi") (serialize-qp "resourceVersion" $resourceVersion "scalar") (serialize-qp "selector" $selector "scalar") (serialize-qp "repo" $repo "scalar") (serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/stream/applications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Watch returns stream of application resource tree
#
# GET /api/v1/stream/applications/{applicationName}/resource-tree
# operationId: ApplicationService_WatchResourceTree
export def "stream-applications-resource-tree WatchResourceTree" [
  applicationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string
  --name: string
  --version: string
  --group: string
  --kind: string
  --appNamespace: string
  --project: string
]: nothing -> record<error: record<details: list<record>, grpc_code: int, http_code: int, http_status: string, message: string>, result: record<hosts: list<record>, nodes: list<record>, orphanedNodes: list<record>, shardsCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "appNamespace" $appNamespace "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stream/applications/($applicationName)/resource-tree" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/stream/applicationsets
#
# operationId: ApplicationSetService_Watch
export def "stream-applicationsets Watch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --projects: list
  --selector: string
  --appSetNamespace: string
  --resourceVersion: string # when specified with a watch call, shows changes that occur after that particular version of a resource.
]: nothing -> record<error: record<details: list<record>, grpc_code: int, http_code: int, http_status: string, message: string>, result: record<applicationSet: record<metadata: record, spec: record, status: record>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "projects" $projects "multi") (serialize-qp "selector" $selector "scalar") (serialize-qp "appSetNamespace" $appSetNamespace "scalar") (serialize-qp "resourceVersion" $resourceVersion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/stream/applicationsets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListWriteRepositoryCredentials gets a list of all configured repository credential sets that have write access
#
# GET /api/v1/write-repocreds
# operationId: RepoCredsService_ListWriteRepositoryCredentials
export def "write-repocreds ListWriteRepositoryCredentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-url: string # Repo URL for query.
]: nothing -> record<items: table<azureActiveDirectoryEndpoint: string, azureServicePrincipalClientId: string, azureServicePrincipalClientSecret: string, azureServicePrincipalTenantId: string, bearerToken: string, enableOCI: bool, forceHttpBasicAuth: bool, gcpServiceAccountKey: string, githubAppEnterpriseBaseUrl: string, githubAppID: int, githubAppInstallationID: int, githubAppPrivateKey: string, insecureOCIForceHttp: bool, noProxy: string, password: string, proxy: string, sshPrivateKey: string, tlsClientCertData: string, tlsClientCertKey: string, type: string, url: string, useAzureWorkloadIdentity: bool, username: string>, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string, shardInfo: record<selector: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $qp_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/write-repocreds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CreateWriteRepositoryCredentials creates a new repository credential set with write access
#
# POST /api/v1/write-repocreds
# operationId: RepoCredsService_CreateWriteRepositoryCredentials
export def "write-repocreds CreateWriteRepositoryCredentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upsert: oneof<nothing, bool> # Whether to create in upsert mode.
  --azureActiveDirectoryEndpoint: string
  --azureServicePrincipalClientId: string
  --azureServicePrincipalClientSecret: string
  --azureServicePrincipalTenantId: string
  --bearerToken: string
  --enableOCI: oneof<nothing, bool>
  --forceHttpBasicAuth: oneof<nothing, bool>
  --gcpServiceAccountKey: string
  --githubAppEnterpriseBaseUrl: string
  --githubAppID: int # format: int64
  --githubAppInstallationID: int # format: int64
  --githubAppPrivateKey: string
  --insecureOCIForceHttp: oneof<nothing, bool> # InsecureOCIForceHttp specifies whether the connection to the repository uses TLS at _all_. If true, no TLS. This flag is applicable for OCI repos only.
  --noProxy: string
  --password: string
  --proxy: string
  --sshPrivateKey: string
  --tlsClientCertData: string
  --tlsClientCertKey: string
  --type: string # Type specifies the type of the repoCreds. Can be either "git", "helm" or "oci". "git" is assumed if empty or absent.
  --body-url: string
  --useAzureWorkloadIdentity: oneof<nothing, bool>
  --username: string
]: any -> record<azureActiveDirectoryEndpoint: string, azureServicePrincipalClientId: string, azureServicePrincipalClientSecret: string, azureServicePrincipalTenantId: string, bearerToken: string, enableOCI: bool, forceHttpBasicAuth: bool, gcpServiceAccountKey: string, githubAppEnterpriseBaseUrl: string, githubAppID: int, githubAppInstallationID: int, githubAppPrivateKey: string, insecureOCIForceHttp: bool, noProxy: string, password: string, proxy: string, sshPrivateKey: string, tlsClientCertData: string, tlsClientCertKey: string, type: string, url: string, useAzureWorkloadIdentity: bool, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upsert" $upsert "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/write-repocreds" $qp)
  let body = {azureActiveDirectoryEndpoint: $azureActiveDirectoryEndpoint, azureServicePrincipalClientId: $azureServicePrincipalClientId, azureServicePrincipalClientSecret: $azureServicePrincipalClientSecret, azureServicePrincipalTenantId: $azureServicePrincipalTenantId, bearerToken: $bearerToken, enableOCI: $enableOCI, forceHttpBasicAuth: $forceHttpBasicAuth, gcpServiceAccountKey: $gcpServiceAccountKey, githubAppEnterpriseBaseUrl: $githubAppEnterpriseBaseUrl, githubAppID: $githubAppID, githubAppInstallationID: $githubAppInstallationID, githubAppPrivateKey: $githubAppPrivateKey, insecureOCIForceHttp: $insecureOCIForceHttp, noProxy: $noProxy, password: $password, proxy: $proxy, sshPrivateKey: $sshPrivateKey, tlsClientCertData: $tlsClientCertData, tlsClientCertKey: $tlsClientCertKey, type: $type, url: $body_url, useAzureWorkloadIdentity: $useAzureWorkloadIdentity, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UpdateWriteRepositoryCredentials updates a repository credential set with write access
#
# PUT /api/v1/write-repocreds/{creds.url}
# operationId: RepoCredsService_UpdateWriteRepositoryCredentials
export def "write-repocreds UpdateWriteRepositoryCredentials" [
  creds.url: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --azureActiveDirectoryEndpoint: string
  --azureServicePrincipalClientId: string
  --azureServicePrincipalClientSecret: string
  --azureServicePrincipalTenantId: string
  --bearerToken: string
  --enableOCI: oneof<nothing, bool>
  --forceHttpBasicAuth: oneof<nothing, bool>
  --gcpServiceAccountKey: string
  --githubAppEnterpriseBaseUrl: string
  --githubAppID: int # format: int64
  --githubAppInstallationID: int # format: int64
  --githubAppPrivateKey: string
  --insecureOCIForceHttp: oneof<nothing, bool> # InsecureOCIForceHttp specifies whether the connection to the repository uses TLS at _all_. If true, no TLS. This flag is applicable for OCI repos only.
  --noProxy: string
  --password: string
  --proxy: string
  --sshPrivateKey: string
  --tlsClientCertData: string
  --tlsClientCertKey: string
  --type: string # Type specifies the type of the repoCreds. Can be either "git", "helm" or "oci". "git" is assumed if empty or absent.
  --body-url: string
  --useAzureWorkloadIdentity: oneof<nothing, bool>
  --username: string
]: any -> record<azureActiveDirectoryEndpoint: string, azureServicePrincipalClientId: string, azureServicePrincipalClientSecret: string, azureServicePrincipalTenantId: string, bearerToken: string, enableOCI: bool, forceHttpBasicAuth: bool, gcpServiceAccountKey: string, githubAppEnterpriseBaseUrl: string, githubAppID: int, githubAppInstallationID: int, githubAppPrivateKey: string, insecureOCIForceHttp: bool, noProxy: string, password: string, proxy: string, sshPrivateKey: string, tlsClientCertData: string, tlsClientCertKey: string, type: string, url: string, useAzureWorkloadIdentity: bool, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/write-repocreds/($creds.url)")
  let body = {azureActiveDirectoryEndpoint: $azureActiveDirectoryEndpoint, azureServicePrincipalClientId: $azureServicePrincipalClientId, azureServicePrincipalClientSecret: $azureServicePrincipalClientSecret, azureServicePrincipalTenantId: $azureServicePrincipalTenantId, bearerToken: $bearerToken, enableOCI: $enableOCI, forceHttpBasicAuth: $forceHttpBasicAuth, gcpServiceAccountKey: $gcpServiceAccountKey, githubAppEnterpriseBaseUrl: $githubAppEnterpriseBaseUrl, githubAppID: $githubAppID, githubAppInstallationID: $githubAppInstallationID, githubAppPrivateKey: $githubAppPrivateKey, insecureOCIForceHttp: $insecureOCIForceHttp, noProxy: $noProxy, password: $password, proxy: $proxy, sshPrivateKey: $sshPrivateKey, tlsClientCertData: $tlsClientCertData, tlsClientCertKey: $tlsClientCertKey, type: $type, url: $body_url, useAzureWorkloadIdentity: $useAzureWorkloadIdentity, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DeleteWriteRepositoryCredentials deletes a repository credential set with write access from the configuration
#
# DELETE /api/v1/write-repocreds/{url}
# operationId: RepoCredsService_DeleteWriteRepositoryCredentials
export def "write-repocreds DeleteWriteRepositoryCredentials" [
  url: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/write-repocreds/($url)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListWriteRepositories gets a list of all configured write repositories
#
# GET /api/v1/write-repositories
# operationId: RepositoryService_ListWriteRepositories
export def "write-repositories ListWriteRepositories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --repo: string # Repo URL for query.
  --forceRefresh: oneof<nothing, bool> # Whether to force a cache refresh on repo's connection state.
  --appProject: string # App project for query.
]: nothing -> record<items: table<azureActiveDirectoryEndpoint: string, azureServicePrincipalClientId: string, azureServicePrincipalClientSecret: string, azureServicePrincipalTenantId: string, bearerToken: string, connectionState: record, depth: int, enableLfs: bool, enableOCI: bool, forceHttpBasicAuth: bool, gcpServiceAccountKey: string, githubAppEnterpriseBaseUrl: string, githubAppID: int, githubAppInstallationID: int, githubAppPrivateKey: string, inheritedCreds: bool, insecure: bool, insecureIgnoreHostKey: bool, insecureOCIForceHttp: bool, name: string, noProxy: string, password: string, project: string, proxy: string, repo: string, sshPrivateKey: string, tlsClientCertData: string, tlsClientCertKey: string, type: string, useAzureWorkloadIdentity: bool, username: string, webhookManifestCacheWarmDisabled: bool>, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string, shardInfo: record<selector: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "repo" $repo "scalar") (serialize-qp "forceRefresh" $forceRefresh "scalar") (serialize-qp "appProject" $appProject "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/write-repositories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CreateWriteRepository creates a new write repository configuration
#
# POST /api/v1/write-repositories
# operationId: RepositoryService_CreateWriteRepository
# --connectionState shape: {attemptedAt?: string, message?: string, status?: string}
export def "write-repositories CreateWriteRepository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upsert: oneof<nothing, bool> # Whether to create in upsert mode.
  --credsOnly: oneof<nothing, bool> # Whether to operate on credential set instead of repository.
  --azureActiveDirectoryEndpoint: string
  --azureServicePrincipalClientId: string
  --azureServicePrincipalClientSecret: string
  --azureServicePrincipalTenantId: string
  --bearerToken: string
  --connectionState: record # shape: {attemptedAt?: string, message?: string, status?: string}
  --depth: int # Depth specifies the depth for shallow clones. A value of 0 or omitting the field indicates a full clone. (format: int64)
  --enableLfs: oneof<nothing, bool> # EnableLFS specifies whether git-lfs support should be enabled for this repo. Only valid for Git repositories.
  --enableOCI: oneof<nothing, bool>
  --forceHttpBasicAuth: oneof<nothing, bool>
  --gcpServiceAccountKey: string
  --githubAppEnterpriseBaseUrl: string
  --githubAppID: int # format: int64
  --githubAppInstallationID: int # format: int64
  --githubAppPrivateKey: string
  --inheritedCreds: oneof<nothing, bool>
  --body-insecure: oneof<nothing, bool>
  --insecureIgnoreHostKey: oneof<nothing, bool>
  --insecureOCIForceHttp: oneof<nothing, bool> # InsecureOCIForceHttp specifies whether the connection to the repository uses TLS at _all_. If true, no TLS. This flag is applicable for OCI repos only.
  --name: string
  --noProxy: string
  --password: string
  --project: string
  --proxy: string
  --repo: string
  --sshPrivateKey: string # SSHPrivateKey contains the PEM data for authenticating at the repo server. Only used with Git repos.
  --tlsClientCertData: string
  --tlsClientCertKey: string
  --type: string # Type specifies the type of the repo. Can be either "git" or "helm. "git" is assumed if empty or absent.
  --useAzureWorkloadIdentity: oneof<nothing, bool>
  --username: string
  --webhookManifestCacheWarmDisabled: oneof<nothing, bool> # WebhookManifestCacheWarmDisabled disables manifest cache warming during webhook processing for this repository. When set, webhook handlers will only trigger reconciliation for affected applications and skip Redis cache operations for unaffected ones. Recommended for large monorepos with plain YAML manifests.
]: any -> record<azureActiveDirectoryEndpoint: string, azureServicePrincipalClientId: string, azureServicePrincipalClientSecret: string, azureServicePrincipalTenantId: string, bearerToken: string, connectionState: record<attemptedAt: string, message: string, status: string>, depth: int, enableLfs: bool, enableOCI: bool, forceHttpBasicAuth: bool, gcpServiceAccountKey: string, githubAppEnterpriseBaseUrl: string, githubAppID: int, githubAppInstallationID: int, githubAppPrivateKey: string, inheritedCreds: bool, insecure: bool, insecureIgnoreHostKey: bool, insecureOCIForceHttp: bool, name: string, noProxy: string, password: string, project: string, proxy: string, repo: string, sshPrivateKey: string, tlsClientCertData: string, tlsClientCertKey: string, type: string, useAzureWorkloadIdentity: bool, username: string, webhookManifestCacheWarmDisabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upsert" $upsert "scalar") (serialize-qp "credsOnly" $credsOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/write-repositories" $qp)
  let body = {azureActiveDirectoryEndpoint: $azureActiveDirectoryEndpoint, azureServicePrincipalClientId: $azureServicePrincipalClientId, azureServicePrincipalClientSecret: $azureServicePrincipalClientSecret, azureServicePrincipalTenantId: $azureServicePrincipalTenantId, bearerToken: $bearerToken, connectionState: $connectionState, depth: $depth, enableLfs: $enableLfs, enableOCI: $enableOCI, forceHttpBasicAuth: $forceHttpBasicAuth, gcpServiceAccountKey: $gcpServiceAccountKey, githubAppEnterpriseBaseUrl: $githubAppEnterpriseBaseUrl, githubAppID: $githubAppID, githubAppInstallationID: $githubAppInstallationID, githubAppPrivateKey: $githubAppPrivateKey, inheritedCreds: $inheritedCreds, insecure: $body_insecure, insecureIgnoreHostKey: $insecureIgnoreHostKey, insecureOCIForceHttp: $insecureOCIForceHttp, name: $name, noProxy: $noProxy, password: $password, project: $project, proxy: $proxy, repo: $repo, sshPrivateKey: $sshPrivateKey, tlsClientCertData: $tlsClientCertData, tlsClientCertKey: $tlsClientCertKey, type: $type, useAzureWorkloadIdentity: $useAzureWorkloadIdentity, username: $username, webhookManifestCacheWarmDisabled: $webhookManifestCacheWarmDisabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UpdateWriteRepository updates a write repository configuration
#
# PUT /api/v1/write-repositories/{repo.repo}
# operationId: RepositoryService_UpdateWriteRepository
# --connectionState shape: {attemptedAt?: string, message?: string, status?: string}
export def "write-repositories UpdateWriteRepository" [
  repo.repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --azureActiveDirectoryEndpoint: string
  --azureServicePrincipalClientId: string
  --azureServicePrincipalClientSecret: string
  --azureServicePrincipalTenantId: string
  --bearerToken: string
  --connectionState: record # shape: {attemptedAt?: string, message?: string, status?: string}
  --depth: int # Depth specifies the depth for shallow clones. A value of 0 or omitting the field indicates a full clone. (format: int64)
  --enableLfs: oneof<nothing, bool> # EnableLFS specifies whether git-lfs support should be enabled for this repo. Only valid for Git repositories.
  --enableOCI: oneof<nothing, bool>
  --forceHttpBasicAuth: oneof<nothing, bool>
  --gcpServiceAccountKey: string
  --githubAppEnterpriseBaseUrl: string
  --githubAppID: int # format: int64
  --githubAppInstallationID: int # format: int64
  --githubAppPrivateKey: string
  --inheritedCreds: oneof<nothing, bool>
  --body-insecure: oneof<nothing, bool>
  --insecureIgnoreHostKey: oneof<nothing, bool>
  --insecureOCIForceHttp: oneof<nothing, bool> # InsecureOCIForceHttp specifies whether the connection to the repository uses TLS at _all_. If true, no TLS. This flag is applicable for OCI repos only.
  --name: string
  --noProxy: string
  --password: string
  --project: string
  --proxy: string
  --repo: string
  --sshPrivateKey: string # SSHPrivateKey contains the PEM data for authenticating at the repo server. Only used with Git repos.
  --tlsClientCertData: string
  --tlsClientCertKey: string
  --type: string # Type specifies the type of the repo. Can be either "git" or "helm. "git" is assumed if empty or absent.
  --useAzureWorkloadIdentity: oneof<nothing, bool>
  --username: string
  --webhookManifestCacheWarmDisabled: oneof<nothing, bool> # WebhookManifestCacheWarmDisabled disables manifest cache warming during webhook processing for this repository. When set, webhook handlers will only trigger reconciliation for affected applications and skip Redis cache operations for unaffected ones. Recommended for large monorepos with plain YAML manifests.
]: any -> record<azureActiveDirectoryEndpoint: string, azureServicePrincipalClientId: string, azureServicePrincipalClientSecret: string, azureServicePrincipalTenantId: string, bearerToken: string, connectionState: record<attemptedAt: string, message: string, status: string>, depth: int, enableLfs: bool, enableOCI: bool, forceHttpBasicAuth: bool, gcpServiceAccountKey: string, githubAppEnterpriseBaseUrl: string, githubAppID: int, githubAppInstallationID: int, githubAppPrivateKey: string, inheritedCreds: bool, insecure: bool, insecureIgnoreHostKey: bool, insecureOCIForceHttp: bool, name: string, noProxy: string, password: string, project: string, proxy: string, repo: string, sshPrivateKey: string, tlsClientCertData: string, tlsClientCertKey: string, type: string, useAzureWorkloadIdentity: bool, username: string, webhookManifestCacheWarmDisabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/write-repositories/($repo.repo)")
  let body = {azureActiveDirectoryEndpoint: $azureActiveDirectoryEndpoint, azureServicePrincipalClientId: $azureServicePrincipalClientId, azureServicePrincipalClientSecret: $azureServicePrincipalClientSecret, azureServicePrincipalTenantId: $azureServicePrincipalTenantId, bearerToken: $bearerToken, connectionState: $connectionState, depth: $depth, enableLfs: $enableLfs, enableOCI: $enableOCI, forceHttpBasicAuth: $forceHttpBasicAuth, gcpServiceAccountKey: $gcpServiceAccountKey, githubAppEnterpriseBaseUrl: $githubAppEnterpriseBaseUrl, githubAppID: $githubAppID, githubAppInstallationID: $githubAppInstallationID, githubAppPrivateKey: $githubAppPrivateKey, inheritedCreds: $inheritedCreds, insecure: $body_insecure, insecureIgnoreHostKey: $insecureIgnoreHostKey, insecureOCIForceHttp: $insecureOCIForceHttp, name: $name, noProxy: $noProxy, password: $password, project: $project, proxy: $proxy, repo: $repo, sshPrivateKey: $sshPrivateKey, tlsClientCertData: $tlsClientCertData, tlsClientCertKey: $tlsClientCertKey, type: $type, useAzureWorkloadIdentity: $useAzureWorkloadIdentity, username: $username, webhookManifestCacheWarmDisabled: $webhookManifestCacheWarmDisabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GetWrite returns a repository or its write credentials
#
# GET /api/v1/write-repositories/{repo}
# operationId: RepositoryService_GetWrite
export def "write-repositories GetWrite" [
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forceRefresh: oneof<nothing, bool> # Whether to force a cache refresh on repo's connection state.
  --appProject: string # App project for query.
]: nothing -> record<azureActiveDirectoryEndpoint: string, azureServicePrincipalClientId: string, azureServicePrincipalClientSecret: string, azureServicePrincipalTenantId: string, bearerToken: string, connectionState: record<attemptedAt: string, message: string, status: string>, depth: int, enableLfs: bool, enableOCI: bool, forceHttpBasicAuth: bool, gcpServiceAccountKey: string, githubAppEnterpriseBaseUrl: string, githubAppID: int, githubAppInstallationID: int, githubAppPrivateKey: string, inheritedCreds: bool, insecure: bool, insecureIgnoreHostKey: bool, insecureOCIForceHttp: bool, name: string, noProxy: string, password: string, project: string, proxy: string, repo: string, sshPrivateKey: string, tlsClientCertData: string, tlsClientCertKey: string, type: string, useAzureWorkloadIdentity: bool, username: string, webhookManifestCacheWarmDisabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceRefresh" $forceRefresh "scalar") (serialize-qp "appProject" $appProject "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/write-repositories/($repo)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DeleteWriteRepository deletes a write repository from the configuration
#
# DELETE /api/v1/write-repositories/{repo}
# operationId: RepositoryService_DeleteWriteRepository
export def "write-repositories DeleteWriteRepository" [
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forceRefresh: oneof<nothing, bool> # Whether to force a cache refresh on repo's connection state.
  --appProject: string # App project for query.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceRefresh" $forceRefresh "scalar") (serialize-qp "appProject" $appProject "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/write-repositories/($repo)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ValidateWriteAccess validates write access to a repository with given parameters
#
# POST /api/v1/write-repositories/{repo}/validate
# operationId: RepositoryService_ValidateWriteAccess
export def "write-repositories-validate ValidateWriteAccess" [
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Username for accessing repo.
  --password: string # Password for accessing repo.
  --sshPrivateKey: string # Private key data for accessing SSH repository.
  --qp-insecure: oneof<nothing, bool> # Whether to skip certificate or host key validation.
  --tlsClientCertData: string # TLS client cert data for accessing HTTPS repository.
  --tlsClientCertKey: string # TLS client cert key for accessing HTTPS repository.
  --type: string # The type of the repo.
  --name: string # The name of the repo.
  --enableOci: oneof<nothing, bool> # Whether helm-oci support should be enabled for this repo.
  --githubAppPrivateKey: string # Github App Private Key PEM data.
  --githubAppID: string # Github App ID of the app used to access the repo. (format: int64)
  --githubAppInstallationID: string # Github App Installation ID of the installed GitHub App. (format: int64)
  --githubAppEnterpriseBaseUrl: string # Github App Enterprise base url if empty will default to https://api.github.com.
  --proxy: string # HTTP/HTTPS proxy to access the repository.
  --project: string # Reference between project and repository that allow you automatically to be added as item inside SourceRepos project entity.
  --gcpServiceAccountKey: string # Google Cloud Platform service account key.
  --forceHttpBasicAuth: oneof<nothing, bool> # Whether to force HTTP basic auth.
  --useAzureWorkloadIdentity: oneof<nothing, bool> # Whether to use azure workload identity for authentication.
  --bearerToken: string # BearerToken contains the bearer token used for Git auth at the repo server.
  --insecureOciForceHttp: oneof<nothing, bool> # Whether https should be disabled for an OCI repo.
  --azureServicePrincipalClientId: string # Azure Service Principal Client ID.
  --azureServicePrincipalClientSecret: string # Azure Service Principal Client Secret.
  --azureServicePrincipalTenantId: string # Azure Service Principal Tenant ID.
  --azureActiveDirectoryEndpoint: string # Azure Active Directory Endpoint.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "sshPrivateKey" $sshPrivateKey "scalar") (serialize-qp "insecure" $qp_insecure "scalar") (serialize-qp "tlsClientCertData" $tlsClientCertData "scalar") (serialize-qp "tlsClientCertKey" $tlsClientCertKey "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "enableOci" $enableOci "scalar") (serialize-qp "githubAppPrivateKey" $githubAppPrivateKey "scalar") (serialize-qp "githubAppID" $githubAppID "scalar") (serialize-qp "githubAppInstallationID" $githubAppInstallationID "scalar") (serialize-qp "githubAppEnterpriseBaseUrl" $githubAppEnterpriseBaseUrl "scalar") (serialize-qp "proxy" $proxy "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "gcpServiceAccountKey" $gcpServiceAccountKey "scalar") (serialize-qp "forceHttpBasicAuth" $forceHttpBasicAuth "scalar") (serialize-qp "useAzureWorkloadIdentity" $useAzureWorkloadIdentity "scalar") (serialize-qp "bearerToken" $bearerToken "scalar") (serialize-qp "insecureOciForceHttp" $insecureOciForceHttp "scalar") (serialize-qp "azureServicePrincipalClientId" $azureServicePrincipalClientId "scalar") (serialize-qp "azureServicePrincipalClientSecret" $azureServicePrincipalClientSecret "scalar") (serialize-qp "azureServicePrincipalTenantId" $azureServicePrincipalTenantId "scalar") (serialize-qp "azureActiveDirectoryEndpoint" $azureActiveDirectoryEndpoint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/write-repositories/($repo)/validate" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Version returns version information of the API server
#
# GET /api/version
# operationId: VersionService_Version
export def "version Version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<BuildDate: string, Compiler: string, ExtraBuildInfo: string, GitCommit: string, GitTag: string, GitTreeState: string, GoVersion: string, HelmVersion: string, JsonnetVersion: string, KubectlVersion: string, KustomizeVersion: string, Platform: string, Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
