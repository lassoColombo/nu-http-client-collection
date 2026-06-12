# Auto-generated client for Apify API vv2-2026-05-28T120425Z
# Source: https://api.apify.com/v2/openapi.json
# Auth: --token flag or $env.APIFY_API_TOKEN

const BASE_URL = "https://api.apify.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o APIFY_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "query-token" => { {headers: {}, query: $"token=($token_val)"} }
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

def base-url-completer [] { ["https://api.apify.com"] }
def auth-scheme-completer [] { ["bearer" "query-token"] }

# Completers for enum parameters
def sortBy-completer [] { ["createdAt" "stats.lastRunStartedAt"] }
def forcePermissionLevel-completer [] { ["FULL_PERMISSIONS" "LIMITED_PERMISSIONS"] }
def generalAccess-completer [] { ["ANYONE_WITH_ID_CAN_READ" "ANYONE_WITH_NAME_CAN_READ" "FOLLOW_USER_SETTING" "RESTRICTED"] }
def accept-completer [] { ["application/json" "application/jsonl" "application/rss+xml" "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" "application/xml" "text/csv" "text/html"] }
def accept-completer-1 [] { ["*/*" "application/json"] }
def Content-Encoding-completer [] { ["br" "deflate" "gzip" "identity"] }
def method-completer [] { ["CONNECT" "DELETE" "GET" "HEAD" "OPTIONS" "PATCH" "POST" "PUT" "TRACE"] }
def ownership-completer [] { ["ownedByMe" "sharedWithMe"] }
def pricingModel-completer [] { ["FLAT_PRICE_PER_MONTH" "FREE" "PAY_PER_EVENT" "PRICE_PER_DATASET_ITEM"] }
def responseFormat-completer [] { ["agent" "full"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "actors list" } } | get name | first)
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

# Get list of Actors
#
# GET /v2/actors
# operationId: acts_get
export def "actors list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --my: oneof<nothing, bool> # If `true` or `1` then the returned list only contains Actors owned by the user. The default value is `false`.  (e.g. true)
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. The default value as well as the maximum is `1000`.  (format: double, e.g. 1000)
  --desc: oneof<nothing, bool> # If `true` or `1` then the objects are sorted by the `createdAt` field in descending order. By default, they are sorted in ascending order.  (e.g. true)
  --sortBy: string@sortBy-completer # Field to sort the records by. The default is `createdAt`. You can also use `stats.lastRunStartedAt` to sort by the most recently ran Actors.  (e.g. createdAt)
]: nothing -> record<data: record<total: int, offset: int, limit: int, desc: bool, count: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "my" $my "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/actors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Actor
#
# POST /v2/actors
# operationId: acts_post
# --versions item shape: {versionNumber: string, sourceType: any, envVars?: list, applyEnvVarsToBuild?: bool, buildTag?: string, sourceFiles?: list, gitRepoUrl?: string, tarballUrl?: string, gitHubGistUrl?: string}
# --defaultRunOptions shape: {build?: string, timeoutSecs?: int, memoryMbytes?: int, restartOnError?: bool, maxItems?: int, forcePermissionLevel?: any}
@deprecated --flag restartOnError
export def "actors post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # nullable
  --description: string # nullable
  --title: string # nullable
  --isPublic: oneof<nothing, bool> # nullable
  --seoTitle: string # nullable
  --seoDescription: string # nullable
  --restartOnError: oneof<nothing, bool> # DEPRECATED
  --versions: list # nullable — item shape: {versionNumber: string, sourceType: any, envVars?: list, applyEnvVarsToBuild?: bool, buildTag?: string, sourceFiles?: list, gitRepoUrl?: string, tarballUrl?: string, gitHubGistUrl?: string}
  --pricingInfos: list
  --categories: list # nullable
  --defaultRunOptions: record # shape: {build?: string, timeoutSecs?: int, memoryMbytes?: int, restartOnError?: bool, maxItems?: int, forcePermissionLevel?: any}
  --actorStandby: any
  --exampleRunInput: any
  --isDeprecated: oneof<nothing, bool> # nullable
]: any -> record<data: record<id: string, userId: string, name: string, username: string, description: string, restartOnError: bool, isPublic: bool, actorPermissionLevel: string, createdAt: string, modifiedAt: string, stats: record<totalBuilds: int, totalRuns: int, totalUsers: int, totalUsers7Days: int, totalUsers30Days: int, totalUsers90Days: int, totalMetamorphs: int, lastRunStartedAt: string, actorReviewCount: int, actorReviewRating: float, bookmarkCount: int, publicActorRunStats30Days: record>, versions: list<record>, pricingInfos: list<any>, defaultRunOptions: record<build: string, timeoutSecs: int, memoryMbytes: int, restartOnError: bool, maxItems: int, forcePermissionLevel: any>, exampleRunInput: any, isDeprecated: bool, deploymentKey: string, title: string, taggedBuilds: any, actorStandby: any, readmeSummary: string, seoTitle: string, seoDescription: string, pictureUrl: string, standbyUrl: string, notice: string, categories: list<string>, isCritical: bool, isGeneric: bool, isSourceCodeHidden: bool, hasNoDataset: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/actors")
  let body = {name: $name, description: $description, title: $title, isPublic: $isPublic, seoTitle: $seoTitle, seoDescription: $seoDescription, restartOnError: $restartOnError, versions: $versions, pricingInfos: $pricingInfos, categories: $categories, defaultRunOptions: $defaultRunOptions, actorStandby: $actorStandby, exampleRunInput: $exampleRunInput, isDeprecated: $isDeprecated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Actor
#
# GET /v2/actors/{actorId}
# operationId: act_get
export def "actors get" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, userId: string, name: string, username: string, description: string, restartOnError: bool, isPublic: bool, actorPermissionLevel: string, createdAt: string, modifiedAt: string, stats: record<totalBuilds: int, totalRuns: int, totalUsers: int, totalUsers7Days: int, totalUsers30Days: int, totalUsers90Days: int, totalMetamorphs: int, lastRunStartedAt: string, actorReviewCount: int, actorReviewRating: float, bookmarkCount: int, publicActorRunStats30Days: record>, versions: list<record>, pricingInfos: list<any>, defaultRunOptions: record<build: string, timeoutSecs: int, memoryMbytes: int, restartOnError: bool, maxItems: int, forcePermissionLevel: any>, exampleRunInput: any, isDeprecated: bool, deploymentKey: string, title: string, taggedBuilds: any, actorStandby: any, readmeSummary: string, seoTitle: string, seoDescription: string, pictureUrl: string, standbyUrl: string, notice: string, categories: list<string>, isCritical: bool, isGeneric: bool, isSourceCodeHidden: bool, hasNoDataset: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actors/($actorId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Actor
#
# PUT /v2/actors/{actorId}
# operationId: act_put
# --versions item shape: {versionNumber?: string, sourceType?: any, envVars?: list, applyEnvVarsToBuild?: bool, buildTag?: string, sourceFiles?: list, gitRepoUrl?: string, tarballUrl?: string, gitHubGistUrl?: string}
@deprecated --flag restartOnError
export def "actors put" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: string # nullable
  --isPublic: oneof<nothing, bool>
  --actorPermissionLevel: any
  --seoTitle: string # nullable
  --seoDescription: string # nullable
  --title: string # nullable
  --restartOnError: oneof<nothing, bool> # DEPRECATED
  --versions: list # item shape: {versionNumber?: string, sourceType?: any, envVars?: list, applyEnvVarsToBuild?: bool, buildTag?: string, sourceFiles?: list, gitRepoUrl?: string, tarballUrl?: string, gitHubGistUrl?: string}
  --pricingInfos: list
  --categories: list # nullable
  --defaultRunOptions: any
  --taggedBuilds: record # An object to modify tags on the Actor's builds. The key is the tag name (e.g., _latest_), and the value is either an object with a `buildId` or `null`.  This operation is a patch; any existing tags that you omit from this object will be preserved.  - **To create or reassign a tag**, provide the tag name with a `buildId`. e.g., to assign the _latest_ tag:    &nbsp;    ```json   {     "latest": {       "buildId": "z2EryhbfhgSyqj6Hn"     }   }   ```  - **To remove a tag**, provide the tag name with a `null` value. e.g., to remove the _beta_ tag:    &nbsp;    ```json   {     "beta": null   }   ```  - **To perform multiple operations**, combine them. The following reassigns _latest_ and removes _beta_, while preserving any other existing tags.    &nbsp;    ```json   {     "latest": {       "buildId": "z2EryhbfhgSyqj6Hn"     },     "beta": null   }   ```  (nullable, e.g. {latest: {buildId: z2EryhbfhgSyqj6Hn}, beta: })
  --actorStandby: any
  --exampleRunInput: any
  --isDeprecated: oneof<nothing, bool> # nullable
]: any -> record<data: record<id: string, userId: string, name: string, username: string, description: string, restartOnError: bool, isPublic: bool, actorPermissionLevel: string, createdAt: string, modifiedAt: string, stats: record<totalBuilds: int, totalRuns: int, totalUsers: int, totalUsers7Days: int, totalUsers30Days: int, totalUsers90Days: int, totalMetamorphs: int, lastRunStartedAt: string, actorReviewCount: int, actorReviewRating: float, bookmarkCount: int, publicActorRunStats30Days: record>, versions: list<record>, pricingInfos: list<any>, defaultRunOptions: record<build: string, timeoutSecs: int, memoryMbytes: int, restartOnError: bool, maxItems: int, forcePermissionLevel: any>, exampleRunInput: any, isDeprecated: bool, deploymentKey: string, title: string, taggedBuilds: any, actorStandby: any, readmeSummary: string, seoTitle: string, seoDescription: string, pictureUrl: string, standbyUrl: string, notice: string, categories: list<string>, isCritical: bool, isGeneric: bool, isSourceCodeHidden: bool, hasNoDataset: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actors/($actorId)")
  let body = {name: $name, description: $description, isPublic: $isPublic, actorPermissionLevel: $actorPermissionLevel, seoTitle: $seoTitle, seoDescription: $seoDescription, title: $title, restartOnError: $restartOnError, versions: $versions, pricingInfos: $pricingInfos, categories: $categories, defaultRunOptions: $defaultRunOptions, taggedBuilds: $taggedBuilds, actorStandby: $actorStandby, exampleRunInput: $exampleRunInput, isDeprecated: $isDeprecated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Actor
#
# DELETE /v2/actors/{actorId}
# operationId: act_delete
export def "actors delete" [
  actorId: string
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
  let full_url = (build-url $base $"/v2/actors/($actorId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of versions
#
# GET /v2/actors/{actorId}/versions
# operationId: act_versions_get
export def "actors-versions list" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<total: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actors/($actorId)/versions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create version
#
# POST /v2/actors/{actorId}/versions
# operationId: act_versions_post
# --envVars item shape: {name: string, value: string, isSecret?: bool}
export def "actors-versions post-by-actorId" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --versionNumber: string # nullable
  --sourceType: any
  --envVars: list # nullable — item shape: {name: string, value: string, isSecret?: bool}
  --applyEnvVarsToBuild: oneof<nothing, bool> # nullable
  --buildTag: string # nullable
  --sourceFiles: list
  --gitRepoUrl: string # URL of the Git repository when sourceType is GIT_REPO. (nullable)
  --tarballUrl: string # URL of the tarball when sourceType is TARBALL. (nullable)
  --gitHubGistUrl: string # URL of the GitHub Gist when sourceType is GITHUB_GIST. (nullable)
]: any -> record<data: record<versionNumber: string, sourceType: any, envVars: list<record>, applyEnvVarsToBuild: bool, buildTag: string, sourceFiles: list<any>, gitRepoUrl: string, tarballUrl: string, gitHubGistUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actors/($actorId)/versions")
  let body = {versionNumber: $versionNumber, sourceType: $sourceType, envVars: $envVars, applyEnvVarsToBuild: $applyEnvVarsToBuild, buildTag: $buildTag, sourceFiles: $sourceFiles, gitRepoUrl: $gitRepoUrl, tarballUrl: $tarballUrl, gitHubGistUrl: $gitHubGistUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get version
#
# GET /v2/actors/{actorId}/versions/{versionNumber}
# operationId: act_version_get
export def "actors-versions get" [
  actorId: string
  versionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<versionNumber: string, sourceType: any, envVars: list<record>, applyEnvVarsToBuild: bool, buildTag: string, sourceFiles: list<any>, gitRepoUrl: string, tarballUrl: string, gitHubGistUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actors/($actorId)/versions/($versionNumber)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update version
#
# PUT /v2/actors/{actorId}/versions/{versionNumber}
# operationId: act_version_put
# --envVars item shape: {name: string, value: string, isSecret?: bool}
export def "actors-versions put" [
  actorId: string
  versionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-versionNumber: string # nullable
  --sourceType: any
  --envVars: list # nullable — item shape: {name: string, value: string, isSecret?: bool}
  --applyEnvVarsToBuild: oneof<nothing, bool> # nullable
  --buildTag: string # nullable
  --sourceFiles: list
  --gitRepoUrl: string # URL of the Git repository when sourceType is GIT_REPO. (nullable)
  --tarballUrl: string # URL of the tarball when sourceType is TARBALL. (nullable)
  --gitHubGistUrl: string # URL of the GitHub Gist when sourceType is GITHUB_GIST. (nullable)
]: any -> record<data: record<versionNumber: string, sourceType: any, envVars: list<record>, applyEnvVarsToBuild: bool, buildTag: string, sourceFiles: list<any>, gitRepoUrl: string, tarballUrl: string, gitHubGistUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actors/($actorId)/versions/($versionNumber)")
  let body = {versionNumber: $body_versionNumber, sourceType: $sourceType, envVars: $envVars, applyEnvVarsToBuild: $applyEnvVarsToBuild, buildTag: $buildTag, sourceFiles: $sourceFiles, gitRepoUrl: $gitRepoUrl, tarballUrl: $tarballUrl, gitHubGistUrl: $gitHubGistUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update version (POST)
#
# POST /v2/actors/{actorId}/versions/{versionNumber}
# operationId: act_version_post
# --envVars item shape: {name: string, value: string, isSecret?: bool}
export def "actors-versions post-by-actorId-versionNumber" [
  actorId: string
  versionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-versionNumber: string # nullable
  --sourceType: any
  --envVars: list # nullable — item shape: {name: string, value: string, isSecret?: bool}
  --applyEnvVarsToBuild: oneof<nothing, bool> # nullable
  --buildTag: string # nullable
  --sourceFiles: list
  --gitRepoUrl: string # URL of the Git repository when sourceType is GIT_REPO. (nullable)
  --tarballUrl: string # URL of the tarball when sourceType is TARBALL. (nullable)
  --gitHubGistUrl: string # URL of the GitHub Gist when sourceType is GITHUB_GIST. (nullable)
]: any -> record<data: record<versionNumber: string, sourceType: any, envVars: list<record>, applyEnvVarsToBuild: bool, buildTag: string, sourceFiles: list<any>, gitRepoUrl: string, tarballUrl: string, gitHubGistUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actors/($actorId)/versions/($versionNumber)")
  let body = {versionNumber: $body_versionNumber, sourceType: $sourceType, envVars: $envVars, applyEnvVarsToBuild: $applyEnvVarsToBuild, buildTag: $buildTag, sourceFiles: $sourceFiles, gitRepoUrl: $gitRepoUrl, tarballUrl: $tarballUrl, gitHubGistUrl: $gitHubGistUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete version
#
# DELETE /v2/actors/{actorId}/versions/{versionNumber}
# operationId: act_version_delete
export def "actors-versions delete" [
  actorId: string
  versionNumber: string
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
  let full_url = (build-url $base $"/v2/actors/($actorId)/versions/($versionNumber)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of environment variables
#
# GET /v2/actors/{actorId}/versions/{versionNumber}/env-vars
# operationId: act_version_envVars_get
export def "actors-versions-env-vars list" [
  actorId: string
  versionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<total: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actors/($actorId)/versions/($versionNumber)/env-vars")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create environment variable
#
# POST /v2/actors/{actorId}/versions/{versionNumber}/env-vars
# operationId: act_version_envVars_post
export def "actors-versions-env-vars post-by-actorId-versionNumber" [
  actorId: string
  versionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  value: string # The environment variable value. This field is absent in responses when `isSecret` is `true`, as secret values are never returned by the API.
  --isSecret: oneof<nothing, bool> # nullable
]: any -> record<data: record<name: string, value: string, isSecret: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actors/($actorId)/versions/($versionNumber)/env-vars")
  let body = {name: $name, value: $value, isSecret: $isSecret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get environment variable
#
# GET /v2/actors/{actorId}/versions/{versionNumber}/env-vars/{envVarName}
# operationId: act_version_envVar_get
export def "actors-versions-env-vars get" [
  actorId: string
  versionNumber: string
  envVarName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<name: string, value: string, isSecret: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actors/($actorId)/versions/($versionNumber)/env-vars/($envVarName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update environment variable
#
# PUT /v2/actors/{actorId}/versions/{versionNumber}/env-vars/{envVarName}
# operationId: act_version_envVar_put
export def "actors-versions-env-vars put" [
  actorId: string
  versionNumber: string
  envVarName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  value: string # The environment variable value. This field is absent in responses when `isSecret` is `true`, as secret values are never returned by the API.
  --isSecret: oneof<nothing, bool> # nullable
]: any -> record<data: record<name: string, value: string, isSecret: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actors/($actorId)/versions/($versionNumber)/env-vars/($envVarName)")
  let body = {name: $name, value: $value, isSecret: $isSecret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update environment variable (POST)
#
# POST /v2/actors/{actorId}/versions/{versionNumber}/env-vars/{envVarName}
# operationId: act_version_envVar_post
export def "actors-versions-env-vars post-by-actorId-versionNumber-envVarName" [
  actorId: string
  versionNumber: string
  envVarName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  value: string # The environment variable value. This field is absent in responses when `isSecret` is `true`, as secret values are never returned by the API.
  --isSecret: oneof<nothing, bool> # nullable
]: any -> record<data: record<name: string, value: string, isSecret: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actors/($actorId)/versions/($versionNumber)/env-vars/($envVarName)")
  let body = {name: $name, value: $value, isSecret: $isSecret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete environment variable
#
# DELETE /v2/actors/{actorId}/versions/{versionNumber}/env-vars/{envVarName}
# operationId: act_version_envVar_delete
export def "actors-versions-env-vars delete" [
  actorId: string
  versionNumber: string
  envVarName: string
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
  let full_url = (build-url $base $"/v2/actors/($actorId)/versions/($versionNumber)/env-vars/($envVarName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of webhooks
#
# GET /v2/actors/{actorId}/webhooks
# operationId: act_webhooks_get
export def "actors-webhooks get" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. The default value as well as the maximum is `1000`.  (format: double, e.g. 1000)
  --desc: oneof<nothing, bool> # If `true` or `1` then the objects are sorted by the `createdAt` field in descending order. By default, they are sorted in ascending order.  (e.g. true)
]: nothing -> record<data: record<total: int, offset: int, limit: int, desc: bool, count: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "desc" $desc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of builds
#
# GET /v2/actors/{actorId}/builds
# operationId: act_builds_get
export def "actors-builds list" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. The default value as well as the maximum is `1000`.  (format: double, e.g. 1000)
  --desc: oneof<nothing, bool> # If `true` or `1` then the objects are sorted by the `startedAt` field in descending order. By default, they are sorted in ascending order.  (e.g. true)
]: nothing -> record<data: record<total: int, offset: int, limit: int, desc: bool, count: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "desc" $desc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/builds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Build Actor
#
# POST /v2/actors/{actorId}/builds
# operationId: act_builds_post
export def "actors-builds post" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Actor version number to be built. (e.g. 0.0)
  --useCache: oneof<nothing, bool> # If `true` or `1`, the system will use a cache to speed up the build process. By default, cache is not used.  (e.g. true)
  --betaPackages: oneof<nothing, bool> # If `true` or `1` then the Actor is built with beta versions of Apify NPM packages. By default, the build uses `latest` packages.  (e.g. true)
  --tag: string # Tag to be applied to the build on success. By default, the tag is taken from Actor version's `buildTag` property.  (e.g. latest)
  --waitForFinish: float # The maximum number of seconds the server waits for the build to finish. By default it is `0`, the maximum value is `60`. <!-- MAX_ACTOR_JOB_ASYNC_WAIT_SECS --> If the build finishes in time then the returned build object will have a terminal status (e.g. `SUCCEEDED`), otherwise it will have a transitional status (e.g. `RUNNING`).  (format: double, e.g. 60)
]: nothing -> record<data: record<id: string, actId: string, userId: string, startedAt: string, finishedAt: string, status: string, meta: record<origin: string, clientIp: string, userAgent: string>, stats: any, options: any, usage: any, usageTotalUsd: float, usageUsd: any, inputSchema: string, readme: string, buildNumber: string, actVersion: record<sourceType: string, buildTag: string, versionNumber: string, gitRepoUrl: string, sourceFiles: list>, actorDefinition: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "useCache" $useCache "scalar") (serialize-qp "betaPackages" $betaPackages "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "waitForFinish" $waitForFinish "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/builds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get default build
#
# GET /v2/actors/{actorId}/builds/default
# operationId: act_build_default_get
export def "actors-builds-default get" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --waitForFinish: float # The maximum number of seconds the server waits for the build to finish. By default it is `0`, the maximum value is `60`. <!-- MAX_ACTOR_JOB_ASYNC_WAIT_SECS --> If the build finishes in time then the returned build object will have a terminal status (e.g. `SUCCEEDED`), otherwise it will have a transitional status (e.g. `RUNNING`).  (format: double, e.g. 60)
]: nothing -> record<data: record<id: string, actId: string, userId: string, startedAt: string, finishedAt: string, status: string, meta: record<origin: string, clientIp: string, userAgent: string>, stats: any, options: any, usage: any, usageTotalUsd: float, usageUsd: any, inputSchema: string, readme: string, buildNumber: string, actVersion: record<sourceType: string, buildTag: string, versionNumber: string, gitRepoUrl: string, sourceFiles: list>, actorDefinition: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "waitForFinish" $waitForFinish "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/builds/default" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get OpenAPI definition
#
# GET /v2/actors/{actorId}/builds/{buildId}/openapi.json
# operationId: act_openapi_json_get
export def "actors-builds-openapijson get" [
  actorId: string
  buildId: string
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
  let full_url = (build-url $base $"/v2/actors/($actorId)/builds/($buildId)/openapi.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get build
#
# GET /v2/actors/{actorId}/builds/{buildId}
# DEPRECATED
# operationId: act_build_get
@deprecated
export def "actors-builds get" [
  actorId: string
  buildId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --waitForFinish: float # The maximum number of seconds the server waits for the build to finish. By default it is `0`, the maximum value is `60`. <!-- MAX_ACTOR_JOB_ASYNC_WAIT_SECS --> If the build finishes in time then the returned build object will have a terminal status (e.g. `SUCCEEDED`), otherwise it will have a transitional status (e.g. `RUNNING`).  (format: double, e.g. 60)
]: nothing -> record<data: record<id: string, actId: string, userId: string, startedAt: string, finishedAt: string, status: string, meta: record<origin: string, clientIp: string, userAgent: string>, stats: any, options: any, usage: any, usageTotalUsd: float, usageUsd: any, inputSchema: string, readme: string, buildNumber: string, actVersion: record<sourceType: string, buildTag: string, versionNumber: string, gitRepoUrl: string, sourceFiles: list>, actorDefinition: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "waitForFinish" $waitForFinish "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/builds/($buildId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abort build
#
# POST /v2/actors/{actorId}/builds/{buildId}/abort
# DEPRECATED
# operationId: act_build_abort_post
@deprecated
export def "actors-builds-abort post" [
  actorId: string
  buildId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, actId: string, userId: string, startedAt: string, finishedAt: string, status: string, meta: record<origin: string, clientIp: string, userAgent: string>, stats: any, options: any, usage: any, usageTotalUsd: float, usageUsd: any, inputSchema: string, readme: string, buildNumber: string, actVersion: record<sourceType: string, buildTag: string, versionNumber: string, gitRepoUrl: string, sourceFiles: list>, actorDefinition: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actors/($actorId)/builds/($buildId)/abort")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of runs
#
# GET /v2/actors/{actorId}/runs
# operationId: act_runs_get
export def "actors-runs list" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. The default value as well as the maximum is `1000`.  (format: double, e.g. 1000)
  --desc: oneof<nothing, bool> # If `true` or `1` then the objects are sorted by the `startedAt` field in descending order. By default, they are sorted in ascending order.  (e.g. true)
  --status: list # Single status or comma-separated list of statuses, see ([available statuses](https://docs.apify.com/platform/actors/running/runs-and-builds#lifecycle)). Used to filter runs by the specified statuses only.  (e.g. [SUCCEEDED])
  --startedAfter: string # Filter runs that started after the specified date and time (inclusive). The value must be a valid ISO 8601 datetime string (UTC).  (format: date-time, e.g. 2025-09-01T00:00:00.000Z)
  --startedBefore: string # Filter runs that started before the specified date and time (inclusive). The value must be a valid ISO 8601 datetime string (UTC).  (format: date-time, e.g. 2025-09-17T23:59:59.000Z)
]: nothing -> record<data: record<total: int, offset: int, limit: int, desc: bool, count: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "status" $status "csv") (serialize-qp "startedAfter" $startedAfter "scalar") (serialize-qp "startedBefore" $startedBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run Actor
#
# POST /v2/actors/{actorId}/runs
# operationId: act_runs_post
export def "actors-runs post" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: float # Optional timeout for the run, in seconds. By default, the run uses the timeout from its configuration.  (format: double, e.g. 60)
  --memory: float # Memory limit for the run, in megabytes. The amount of memory can be set to a power of 2 with a minimum of 128. By default, the run uses the memory limit from its configuration.  (format: double, e.g. 256)
  --maxItems: float # Specifies the maximum number of dataset items that will be charged for pay-per-result Actors. This does NOT guarantee that the Actor will return only this many items. It only ensures you won't be charged for more than this number of items. Only works for pay-per-result Actors. Value can be accessed in the actor run using `ACTOR_MAX_PAID_DATASET_ITEMS` environment variable.  (format: double, e.g. 1000)
  --maxTotalChargeUsd: float # Specifies the maximum cost of the run. This parameter is useful for pay-per-event Actors, as it allows you to limit the amount charged to your subscription. You can access the maximum cost in your Actor by using the `ACTOR_MAX_TOTAL_CHARGE_USD` environment variable.  (format: double, e.g. 5)
  --restartOnError: oneof<nothing, bool> # Determines whether the run will be restarted if it fails.  (e.g. false)
  --build: string # Specifies the Actor build to run. It can be either a build tag or build number. By default, the run uses the build from its configuration (typically `latest`).  (e.g. 0.1.234)
  --waitForFinish: float # The maximum number of seconds the server waits for the run to finish. By default it is `0`, the maximum value is `60`. <!-- MAX_ACTOR_JOB_ASYNC_WAIT_SECS --> If the run finishes in time then the returned run object will have a terminal status (e.g. `SUCCEEDED`), otherwise it will have a transitional status (e.g. `RUNNING`).  (format: double, e.g. 60)
  --webhooks: string # Specifies optional webhooks associated with the Actor run, which can be used to receive a notification e.g. when the Actor finished or failed. The value is a Base64-encoded JSON array whose items follow the WebhookRepresentation schema. For more information, see [Webhooks documentation](https://docs.apify.com/platform/integrations/webhooks).  (e.g. dGhpcyBpcyBqdXN0IGV4YW1wbGUK...)
  --forcePermissionLevel: string@forcePermissionLevel-completer # Overrides the Actor's permission level for this specific run. Use to test restricted permissions before deploying changes to your Actor or to temporarily elevate or restrict access. If you don't specify this parameter, the Actor uses its configured default permission level. For more information on permissions, see the [documentation](https://docs.apify.com/platform/actors/development/permissions).  (e.g. LIMITED_PERMISSIONS)
  --body: record
]: any -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "memory" $memory "scalar") (serialize-qp "maxItems" $maxItems "scalar") (serialize-qp "maxTotalChargeUsd" $maxTotalChargeUsd "scalar") (serialize-qp "restartOnError" $restartOnError "scalar") (serialize-qp "build" $build "scalar") (serialize-qp "waitForFinish" $waitForFinish "scalar") (serialize-qp "webhooks" $webhooks "scalar") (serialize-qp "forcePermissionLevel" $forcePermissionLevel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Run Actor synchronously and return output
#
# POST /v2/actors/{actorId}/run-sync
# operationId: act_runSync_post
export def "actors-run-sync post" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --outputRecordKey: string # Key of the record from run's default key-value store to be returned in the response. By default, it is `OUTPUT`.  (e.g. OUTPUT)
  --timeout: float # Optional timeout for the run, in seconds. By default, the run uses the timeout from its configuration.  (format: double, e.g. 60)
  --memory: float # Memory limit for the run, in megabytes. The amount of memory can be set to a power of 2 with a minimum of 128. By default, the run uses the memory limit from its configuration.  (format: double, e.g. 256)
  --maxItems: float # Specifies the maximum number of dataset items that will be charged for pay-per-result Actors. This does NOT guarantee that the Actor will return only this many items. It only ensures you won't be charged for more than this number of items. Only works for pay-per-result Actors. Value can be accessed in the actor run using `ACTOR_MAX_PAID_DATASET_ITEMS` environment variable.  (format: double, e.g. 1000)
  --maxTotalChargeUsd: float # Specifies the maximum cost of the run. This parameter is useful for pay-per-event Actors, as it allows you to limit the amount charged to your subscription. You can access the maximum cost in your Actor by using the `ACTOR_MAX_TOTAL_CHARGE_USD` environment variable.  (format: double, e.g. 5)
  --restartOnError: oneof<nothing, bool> # Determines whether the run will be restarted if it fails.  (e.g. false)
  --build: string # Specifies the Actor build to run. It can be either a build tag or build number. By default, the run uses the build from its configuration (typically `latest`).  (e.g. 0.1.234)
  --webhooks: string # Specifies optional webhooks associated with the Actor run, which can be used to receive a notification e.g. when the Actor finished or failed. The value is a Base64-encoded JSON array whose items follow the WebhookRepresentation schema. For more information, see [Webhooks documentation](https://docs.apify.com/platform/integrations/webhooks).  (e.g. dGhpcyBpcyBqdXN0IGV4YW1wbGUK...)
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputRecordKey" $outputRecordKey "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "memory" $memory "scalar") (serialize-qp "maxItems" $maxItems "scalar") (serialize-qp "maxTotalChargeUsd" $maxTotalChargeUsd "scalar") (serialize-qp "restartOnError" $restartOnError "scalar") (serialize-qp "build" $build "scalar") (serialize-qp "webhooks" $webhooks "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/run-sync" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Run Actor synchronously without input
#
# GET /v2/actors/{actorId}/run-sync
# operationId: act_runSync_get
export def "actors-run-sync get" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --outputRecordKey: string # Key of the record from run's default key-value store to be returned in the response. By default, it is `OUTPUT`.  (e.g. OUTPUT)
  --timeout: float # Optional timeout for the run, in seconds. By default, the run uses the timeout from its configuration.  (format: double, e.g. 60)
  --memory: float # Memory limit for the run, in megabytes. The amount of memory can be set to a power of 2 with a minimum of 128. By default, the run uses the memory limit from its configuration.  (format: double, e.g. 256)
  --maxItems: float # Specifies the maximum number of dataset items that will be charged for pay-per-result Actors. This does NOT guarantee that the Actor will return only this many items. It only ensures you won't be charged for more than this number of items. Only works for pay-per-result Actors. Value can be accessed in the actor run using `ACTOR_MAX_PAID_DATASET_ITEMS` environment variable.  (format: double, e.g. 1000)
  --maxTotalChargeUsd: float # Specifies the maximum cost of the run. This parameter is useful for pay-per-event Actors, as it allows you to limit the amount charged to your subscription. You can access the maximum cost in your Actor by using the `ACTOR_MAX_TOTAL_CHARGE_USD` environment variable.  (format: double, e.g. 5)
  --restartOnError: oneof<nothing, bool> # Determines whether the run will be restarted if it fails.  (e.g. false)
  --build: string # Specifies the Actor build to run. It can be either a build tag or build number. By default, the run uses the build from its configuration (typically `latest`).  (e.g. 0.1.234)
  --webhooks: string # Specifies optional webhooks associated with the Actor run, which can be used to receive a notification e.g. when the Actor finished or failed. The value is a Base64-encoded JSON array whose items follow the WebhookRepresentation schema. For more information, see [Webhooks documentation](https://docs.apify.com/platform/integrations/webhooks).  (e.g. dGhpcyBpcyBqdXN0IGV4YW1wbGUK...)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputRecordKey" $outputRecordKey "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "memory" $memory "scalar") (serialize-qp "maxItems" $maxItems "scalar") (serialize-qp "maxTotalChargeUsd" $maxTotalChargeUsd "scalar") (serialize-qp "restartOnError" $restartOnError "scalar") (serialize-qp "build" $build "scalar") (serialize-qp "webhooks" $webhooks "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/run-sync" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run Actor synchronously and get dataset items
#
# POST /v2/actors/{actorId}/run-sync-get-dataset-items
# operationId: act_runSyncGetDatasetItems_post
export def "actors-run-sync-get-dataset-items post" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: float # Optional timeout for the run, in seconds. By default, the run uses the timeout from its configuration.  (format: double, e.g. 60)
  --memory: float # Memory limit for the run, in megabytes. The amount of memory can be set to a power of 2 with a minimum of 128. By default, the run uses the memory limit from its configuration.  (format: double, e.g. 256)
  --maxItems: float # Specifies the maximum number of dataset items that will be charged for pay-per-result Actors. This does NOT guarantee that the Actor will return only this many items. It only ensures you won't be charged for more than this number of items. Only works for pay-per-result Actors. Value can be accessed in the actor run using `ACTOR_MAX_PAID_DATASET_ITEMS` environment variable.  (format: double, e.g. 1000)
  --maxTotalChargeUsd: float # Specifies the maximum cost of the run. This parameter is useful for pay-per-event Actors, as it allows you to limit the amount charged to your subscription. You can access the maximum cost in your Actor by using the `ACTOR_MAX_TOTAL_CHARGE_USD` environment variable.  (format: double, e.g. 5)
  --restartOnError: oneof<nothing, bool> # Determines whether the run will be restarted if it fails.  (e.g. false)
  --build: string # Specifies the Actor build to run. It can be either a build tag or build number. By default, the run uses the build from its configuration (typically `latest`).  (e.g. 0.1.234)
  --webhooks: string # Specifies optional webhooks associated with the Actor run, which can be used to receive a notification e.g. when the Actor finished or failed. The value is a Base64-encoded JSON array whose items follow the WebhookRepresentation schema. For more information, see [Webhooks documentation](https://docs.apify.com/platform/integrations/webhooks).  (e.g. dGhpcyBpcyBqdXN0IGV4YW1wbGUK...)
  --format: string # Format of the results, possible values are: `json`, `jsonl`, `csv`, `html`, `xlsx`, `xml` and `rss`. The default value is `json`.  (e.g. json)
  --clean: oneof<nothing, bool> # If `true` or `1` then the API endpoint returns only non-empty items and skips hidden fields (i.e. fields starting with the # character). The `clean` parameter is just a shortcut for `skipHidden=true` and `skipEmpty=true` parameters. Note that since some objects might be skipped from the output, that the result might contain less items than the `limit` value.  (e.g. false)
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. By default there is no limit. (format: double)
  --qp-fields: string # A comma-separated list of fields which should be picked from the items, only these fields will remain in the resulting record objects. Note that the fields in the outputted items are sorted the same way as they are specified in the `fields` query parameter. You can use this feature to effectively fix the output format.  (e.g. myValue,myOtherValue)
  --outputFields: string # A comma-separated list of output field names that positionally rename the fields specified in the `fields` parameter. For example, `?fields=headline,url&outputFields=title,link` renames `headline` to `title` and `url` to `link` in the output. The number of names in `outputFields` must match the number of names in `fields`. Requires the `fields` parameter to be specified as well.  (e.g. title,link)
  --omit: string # A comma-separated list of fields which should be omitted from the items. (e.g. myValue,myOtherValue)
  --unwind: string # A comma-separated list of fields which should be unwound, in order which they should be processed. Each field should be either an array or an object. If the field is an array then every element of the array will become a separate record and merged with parent object. If the unwound field is an object then it is merged with the parent object. If the unwound field is missing or its value is neither an array nor an object and therefore cannot be merged with a parent object then the item gets preserved as it is. Note that the unwound items ignore the `desc` parameter.  (e.g. myValue,myOtherValue)
  --flatten: string # A comma-separated list of fields which should transform nested objects into flat structures.  For example, with `flatten="foo"` the object `{"foo":{"bar": "hello"}}` is turned into `{"foo.bar": "hello"}`.  The original object with properties is replaced with the flattened object.  (e.g. myValue)
  --desc: oneof<nothing, bool> # By default, results are returned in the same order as they were stored. To reverse the order, set this parameter to `true` or `1`.  (e.g. true)
  --attachment: oneof<nothing, bool> # If `true` or `1` then the response will define the `Content-Disposition: attachment` header, forcing a web browser to download the file rather than to display it. By default this header is not present.  (e.g. true)
  --delimiter: string # A delimiter character for CSV files, only used if `format=csv`. You might need to URL-encode the character (e.g. use `%09` for tab or `%3B` for semicolon). The default delimiter is a simple comma (`,`).  (e.g. ;)
  --bom: oneof<nothing, bool> # All text responses are encoded in UTF-8 encoding. By default, the `format=csv` files are prefixed with the UTF-8 Byte Order Mark (BOM), while `json`, `jsonl`, `xml`, `html` and `rss` files are not.  If you want to override this default behavior, specify `bom=1` query parameter to include the BOM or `bom=0` to skip it.  (e.g. false)
  --xmlRoot: string # Overrides default root element name of `xml` output. By default the root element is `items`.  (e.g. items)
  --xmlRow: string # Overrides default element name that wraps each page or page function result object in `xml` output. By default the element name is `item`.  (e.g. item)
  --skipHeaderRow: oneof<nothing, bool> # If `true` or `1` then header row in the `csv` format is skipped. (e.g. true)
  --skipHidden: oneof<nothing, bool> # If `true` or `1` then hidden fields are skipped from the output, i.e. fields starting with the `#` character.  (e.g. false)
  --skipEmpty: oneof<nothing, bool> # If `true` or `1` then empty items are skipped from the output.  Note that if used, the results might contain less items than the limit value.  (e.g. false)
  --simplified: oneof<nothing, bool> # If `true` or `1` then, the endpoint applies the `fields=url,pageFunctionResult,errorInfo` and `unwind=pageFunctionResult` query parameters. This feature is used to emulate simplified results provided by the legacy Apify Crawler product and it's not recommended to use it in new integrations.  (e.g. false)
  --view: string # Defines the view configuration for dataset items based on the schema definition. This parameter determines how the data will be filtered and presented. For complete specification details, see the [dataset schema documentation](/platform/actors/development/actor-definition/dataset-schema).  (e.g. overview)
  --skipFailedPages: oneof<nothing, bool> # If `true` or `1` then, the all the items with errorInfo property will be skipped from the output.  This feature is here to emulate functionality of API version 1 used for the legacy Apify Crawler product and it's not recommended to use it in new integrations.  (e.g. false)
  --feedTitle: string # Overrides the auto-generated RSS channel `<title>` element. Only used when `format=rss`. If not provided, the title defaults to `Dataset <label>`.  (e.g. Latest posts from r/pasta)
  --feedDescription: string # Overrides the auto-generated RSS channel `<description>` element. Only used when `format=rss`. If not provided, the description defaults to `Items in dataset with id "<datasetId>".`  (e.g. Scraped forum posts)
  --body: record
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "memory" $memory "scalar") (serialize-qp "maxItems" $maxItems "scalar") (serialize-qp "maxTotalChargeUsd" $maxTotalChargeUsd "scalar") (serialize-qp "restartOnError" $restartOnError "scalar") (serialize-qp "build" $build "scalar") (serialize-qp "webhooks" $webhooks "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "clean" $clean "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "outputFields" $outputFields "scalar") (serialize-qp "omit" $omit "scalar") (serialize-qp "unwind" $unwind "scalar") (serialize-qp "flatten" $flatten "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "attachment" $attachment "scalar") (serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "bom" $bom "scalar") (serialize-qp "xmlRoot" $xmlRoot "scalar") (serialize-qp "xmlRow" $xmlRow "scalar") (serialize-qp "skipHeaderRow" $skipHeaderRow "scalar") (serialize-qp "skipHidden" $skipHidden "scalar") (serialize-qp "skipEmpty" $skipEmpty "scalar") (serialize-qp "simplified" $simplified "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "skipFailedPages" $skipFailedPages "scalar") (serialize-qp "feedTitle" $feedTitle "scalar") (serialize-qp "feedDescription" $feedDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/run-sync-get-dataset-items" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Run Actor synchronously without input and get dataset items
#
# GET /v2/actors/{actorId}/run-sync-get-dataset-items
# operationId: act_runSyncGetDatasetItems_get
export def "actors-run-sync-get-dataset-items get" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: float # Optional timeout for the run, in seconds. By default, the run uses the timeout from its configuration.  (format: double, e.g. 60)
  --memory: float # Memory limit for the run, in megabytes. The amount of memory can be set to a power of 2 with a minimum of 128. By default, the run uses the memory limit from its configuration.  (format: double, e.g. 256)
  --maxItems: float # Specifies the maximum number of dataset items that will be charged for pay-per-result Actors. This does NOT guarantee that the Actor will return only this many items. It only ensures you won't be charged for more than this number of items. Only works for pay-per-result Actors. Value can be accessed in the actor run using `ACTOR_MAX_PAID_DATASET_ITEMS` environment variable.  (format: double, e.g. 1000)
  --maxTotalChargeUsd: float # Specifies the maximum cost of the run. This parameter is useful for pay-per-event Actors, as it allows you to limit the amount charged to your subscription. You can access the maximum cost in your Actor by using the `ACTOR_MAX_TOTAL_CHARGE_USD` environment variable.  (format: double, e.g. 5)
  --restartOnError: oneof<nothing, bool> # Determines whether the run will be restarted if it fails.  (e.g. false)
  --build: string # Specifies the Actor build to run. It can be either a build tag or build number. By default, the run uses the build from its configuration (typically `latest`).  (e.g. 0.1.234)
  --webhooks: string # Specifies optional webhooks associated with the Actor run, which can be used to receive a notification e.g. when the Actor finished or failed. The value is a Base64-encoded JSON array whose items follow the WebhookRepresentation schema. For more information, see [Webhooks documentation](https://docs.apify.com/platform/integrations/webhooks).  (e.g. dGhpcyBpcyBqdXN0IGV4YW1wbGUK...)
  --format: string # Format of the results, possible values are: `json`, `jsonl`, `csv`, `html`, `xlsx`, `xml` and `rss`. The default value is `json`.  (e.g. json)
  --clean: oneof<nothing, bool> # If `true` or `1` then the API endpoint returns only non-empty items and skips hidden fields (i.e. fields starting with the # character). The `clean` parameter is just a shortcut for `skipHidden=true` and `skipEmpty=true` parameters. Note that since some objects might be skipped from the output, that the result might contain less items than the `limit` value.  (e.g. false)
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. By default there is no limit. (format: double)
  --qp-fields: string # A comma-separated list of fields which should be picked from the items, only these fields will remain in the resulting record objects. Note that the fields in the outputted items are sorted the same way as they are specified in the `fields` query parameter. You can use this feature to effectively fix the output format.  (e.g. myValue,myOtherValue)
  --outputFields: string # A comma-separated list of output field names that positionally rename the fields specified in the `fields` parameter. For example, `?fields=headline,url&outputFields=title,link` renames `headline` to `title` and `url` to `link` in the output. The number of names in `outputFields` must match the number of names in `fields`. Requires the `fields` parameter to be specified as well.  (e.g. title,link)
  --omit: string # A comma-separated list of fields which should be omitted from the items. (e.g. myValue,myOtherValue)
  --unwind: string # A comma-separated list of fields which should be unwound, in order which they should be processed. Each field should be either an array or an object. If the field is an array then every element of the array will become a separate record and merged with parent object. If the unwound field is an object then it is merged with the parent object. If the unwound field is missing or its value is neither an array nor an object and therefore cannot be merged with a parent object then the item gets preserved as it is. Note that the unwound items ignore the `desc` parameter.  (e.g. myValue,myOtherValue)
  --flatten: string # A comma-separated list of fields which should transform nested objects into flat structures.  For example, with `flatten="foo"` the object `{"foo":{"bar": "hello"}}` is turned into `{"foo.bar": "hello"}`.  The original object with properties is replaced with the flattened object.  (e.g. myValue)
  --desc: oneof<nothing, bool> # By default, results are returned in the same order as they were stored. To reverse the order, set this parameter to `true` or `1`.  (e.g. true)
  --attachment: oneof<nothing, bool> # If `true` or `1` then the response will define the `Content-Disposition: attachment` header, forcing a web browser to download the file rather than to display it. By default this header is not present.  (e.g. true)
  --delimiter: string # A delimiter character for CSV files, only used if `format=csv`. You might need to URL-encode the character (e.g. use `%09` for tab or `%3B` for semicolon). The default delimiter is a simple comma (`,`).  (e.g. ;)
  --bom: oneof<nothing, bool> # All text responses are encoded in UTF-8 encoding. By default, the `format=csv` files are prefixed with the UTF-8 Byte Order Mark (BOM), while `json`, `jsonl`, `xml`, `html` and `rss` files are not.  If you want to override this default behavior, specify `bom=1` query parameter to include the BOM or `bom=0` to skip it.  (e.g. false)
  --xmlRoot: string # Overrides default root element name of `xml` output. By default the root element is `items`.  (e.g. items)
  --xmlRow: string # Overrides default element name that wraps each page or page function result object in `xml` output. By default the element name is `item`.  (e.g. item)
  --skipHeaderRow: oneof<nothing, bool> # If `true` or `1` then header row in the `csv` format is skipped. (e.g. true)
  --skipHidden: oneof<nothing, bool> # If `true` or `1` then hidden fields are skipped from the output, i.e. fields starting with the `#` character.  (e.g. false)
  --skipEmpty: oneof<nothing, bool> # If `true` or `1` then empty items are skipped from the output.  Note that if used, the results might contain less items than the limit value.  (e.g. false)
  --simplified: oneof<nothing, bool> # If `true` or `1` then, the endpoint applies the `fields=url,pageFunctionResult,errorInfo` and `unwind=pageFunctionResult` query parameters. This feature is used to emulate simplified results provided by the legacy Apify Crawler product and it's not recommended to use it in new integrations.  (e.g. false)
  --view: string # Defines the view configuration for dataset items based on the schema definition. This parameter determines how the data will be filtered and presented. For complete specification details, see the [dataset schema documentation](/platform/actors/development/actor-definition/dataset-schema).  (e.g. overview)
  --skipFailedPages: oneof<nothing, bool> # If `true` or `1` then, the all the items with errorInfo property will be skipped from the output.  This feature is here to emulate functionality of API version 1 used for the legacy Apify Crawler product and it's not recommended to use it in new integrations.  (e.g. false)
  --feedTitle: string # Overrides the auto-generated RSS channel `<title>` element. Only used when `format=rss`. If not provided, the title defaults to `Dataset <label>`.  (e.g. Latest posts from r/pasta)
  --feedDescription: string # Overrides the auto-generated RSS channel `<description>` element. Only used when `format=rss`. If not provided, the description defaults to `Items in dataset with id "<datasetId>".`  (e.g. Scraped forum posts)
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "memory" $memory "scalar") (serialize-qp "maxItems" $maxItems "scalar") (serialize-qp "maxTotalChargeUsd" $maxTotalChargeUsd "scalar") (serialize-qp "restartOnError" $restartOnError "scalar") (serialize-qp "build" $build "scalar") (serialize-qp "webhooks" $webhooks "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "clean" $clean "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "outputFields" $outputFields "scalar") (serialize-qp "omit" $omit "scalar") (serialize-qp "unwind" $unwind "scalar") (serialize-qp "flatten" $flatten "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "attachment" $attachment "scalar") (serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "bom" $bom "scalar") (serialize-qp "xmlRoot" $xmlRoot "scalar") (serialize-qp "xmlRow" $xmlRow "scalar") (serialize-qp "skipHeaderRow" $skipHeaderRow "scalar") (serialize-qp "skipHidden" $skipHidden "scalar") (serialize-qp "skipEmpty" $skipEmpty "scalar") (serialize-qp "simplified" $simplified "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "skipFailedPages" $skipFailedPages "scalar") (serialize-qp "feedTitle" $feedTitle "scalar") (serialize-qp "feedDescription" $feedDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/run-sync-get-dataset-items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validate Actor input
#
# POST /v2/actors/{actorId}/validate-input
# operationId: act_validateInput_post
export def "actors-validate-input post" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --build: string # Optional tag or number of the Actor build to use for input schema validation. By default, the `latest` build tag is used.  (e.g. latest)
  --body: record
]: any -> record<valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "build" $build "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/validate-input" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resurrect run
#
# POST /v2/actors/{actorId}/runs/{runId}/resurrect
# operationId: act_run_resurrect_post
export def "actors-runs-resurrect post" [
  actorId: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --build: string # Specifies the Actor build to run. It can be either a build tag or build number. By default, the run is resurrected with the same build it originally used. Specifically, if a run was first started with the `latest` tag, which resolves to version `0.0.3` at the time, a run resurrected without this parameter will continue running with `0.0.3`, even if `latest` already points to a newer build.  (e.g. 0.1.234)
  --timeout: float # Optional timeout for the run, in seconds. By default, the run uses the timeout specified in the run that is being resurrected.  (format: double, e.g. 60)
  --memory: float # Memory limit for the run, in megabytes. The amount of memory can be set to a power of 2 with a minimum of 128. By default, the run uses the memory limit specified in the run that is being resurrected.  (format: double, e.g. 256)
  --restartOnError: oneof<nothing, bool> # Determines whether the resurrected run will be restarted if it fails. By default, the resurrected run uses the same setting as before.  (e.g. false)
]: nothing -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "build" $build "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "memory" $memory "scalar") (serialize-qp "restartOnError" $restartOnError "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/($runId)/resurrect" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last run
#
# GET /v2/actors/{actorId}/runs/last
# operationId: act_runs_last_get
export def "actors-runs-last get" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --waitForFinish: float # The maximum number of seconds the server waits for the run to finish. By default it is `0`, the maximum value is `60`. <!-- MAX_ACTOR_JOB_ASYNC_WAIT_SECS --> If the run finishes in time then the returned run object will have a terminal status (e.g. `SUCCEEDED`), otherwise it will have a transitional status (e.g. `RUNNING`).  (format: double, e.g. 60)
]: nothing -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "waitForFinish" $waitForFinish "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last run's default dataset
#
# GET /v2/actors/{actorId}/runs/last/dataset
# operationId: act_runs_last_dataset_get
export def "actors-runs-last-dataset get" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> record<data: record<id: string, name: string, userId: string, createdAt: string, modifiedAt: string, accessedAt: string, itemCount: int, cleanItemCount: int, actId: string, actRunId: string, fields: list<string>, schema: record, consoleUrl: string, itemsPublicUrl: string, urlSigningSecretKey: string, generalAccess: string, stats: record<readCount: int, writeCount: int, storageBytes: int, inflatedBytes: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/dataset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update last run's default dataset
#
# PUT /v2/actors/{actorId}/runs/last/dataset
# operationId: act_runs_last_dataset_put
export def "actors-runs-last-dataset put" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --name: string # nullable
  --generalAccess: string@generalAccess-completer # Defines the general access level for the resource.
]: any -> record<data: record<id: string, name: string, userId: string, createdAt: string, modifiedAt: string, accessedAt: string, itemCount: int, cleanItemCount: int, actId: string, actRunId: string, fields: list<string>, schema: record, consoleUrl: string, itemsPublicUrl: string, urlSigningSecretKey: string, generalAccess: string, stats: record<readCount: int, writeCount: int, storageBytes: int, inflatedBytes: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/dataset" $qp)
  let body = {name: $name, generalAccess: $generalAccess} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete last run's default dataset
#
# DELETE /v2/actors/{actorId}/runs/last/dataset
# operationId: act_runs_last_dataset_delete
export def "actors-runs-last-dataset delete" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/dataset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last run's dataset items
#
# GET /v2/actors/{actorId}/runs/last/dataset/items
# operationId: act_runs_last_dataset_items_get
export def "actors-runs-last-dataset-items get" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --format: string # Format of the results, possible values are: `json`, `jsonl`, `csv`, `html`, `xlsx`, `xml` and `rss`. The default value is `json`.  (e.g. json)
  --clean: oneof<nothing, bool> # If `true` or `1` then the API endpoint returns only non-empty items and skips hidden fields (i.e. fields starting with the # character). The `clean` parameter is just a shortcut for `skipHidden=true` and `skipEmpty=true` parameters. Note that since some objects might be skipped from the output, that the result might contain less items than the `limit` value.  (e.g. false)
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. By default there is no limit. (format: double)
  --qp-fields: string # A comma-separated list of fields which should be picked from the items, only these fields will remain in the resulting record objects. Note that the fields in the outputted items are sorted the same way as they are specified in the `fields` query parameter. You can use this feature to effectively fix the output format.  (e.g. myValue,myOtherValue)
  --outputFields: string # A comma-separated list of output field names that positionally rename the fields specified in the `fields` parameter. For example, `?fields=headline,url&outputFields=title,link` renames `headline` to `title` and `url` to `link` in the output. The number of names in `outputFields` must match the number of names in `fields`. Requires the `fields` parameter to be specified as well.  (e.g. title,link)
  --omit: string # A comma-separated list of fields which should be omitted from the items. (e.g. myValue,myOtherValue)
  --unwind: string # A comma-separated list of fields which should be unwound, in order which they should be processed. Each field should be either an array or an object. If the field is an array then every element of the array will become a separate record and merged with parent object. If the unwound field is an object then it is merged with the parent object. If the unwound field is missing or its value is neither an array nor an object and therefore cannot be merged with a parent object then the item gets preserved as it is. Note that the unwound items ignore the `desc` parameter.  (e.g. myValue,myOtherValue)
  --flatten: string # A comma-separated list of fields which should transform nested objects into flat structures.  For example, with `flatten="foo"` the object `{"foo":{"bar": "hello"}}` is turned into `{"foo.bar": "hello"}`.  The original object with properties is replaced with the flattened object.  (e.g. myValue)
  --desc: oneof<nothing, bool> # By default, results are returned in the same order as they were stored. To reverse the order, set this parameter to `true` or `1`.  (e.g. true)
  --attachment: oneof<nothing, bool> # If `true` or `1` then the response will define the `Content-Disposition: attachment` header, forcing a web browser to download the file rather than to display it. By default this header is not present.  (e.g. true)
  --delimiter: string # A delimiter character for CSV files, only used if `format=csv`. You might need to URL-encode the character (e.g. use `%09` for tab or `%3B` for semicolon). The default delimiter is a simple comma (`,`).  (e.g. ;)
  --bom: oneof<nothing, bool> # All text responses are encoded in UTF-8 encoding. By default, the `format=csv` files are prefixed with the UTF-8 Byte Order Mark (BOM), while `json`, `jsonl`, `xml`, `html` and `rss` files are not.  If you want to override this default behavior, specify `bom=1` query parameter to include the BOM or `bom=0` to skip it.  (e.g. false)
  --xmlRoot: string # Overrides default root element name of `xml` output. By default the root element is `items`.  (e.g. items)
  --xmlRow: string # Overrides default element name that wraps each page or page function result object in `xml` output. By default the element name is `item`.  (e.g. item)
  --skipHeaderRow: oneof<nothing, bool> # If `true` or `1` then header row in the `csv` format is skipped. (e.g. true)
  --skipHidden: oneof<nothing, bool> # If `true` or `1` then hidden fields are skipped from the output, i.e. fields starting with the `#` character.  (e.g. false)
  --skipEmpty: oneof<nothing, bool> # If `true` or `1` then empty items are skipped from the output.  Note that if used, the results might contain less items than the limit value.  (e.g. false)
  --simplified: oneof<nothing, bool> # If `true` or `1` then, the endpoint applies the `fields=url,pageFunctionResult,errorInfo` and `unwind=pageFunctionResult` query parameters. This feature is used to emulate simplified results provided by the legacy Apify Crawler product and it's not recommended to use it in new integrations.  (e.g. false)
  --view: string # Defines the view configuration for dataset items based on the schema definition. This parameter determines how the data will be filtered and presented. For complete specification details, see the [dataset schema documentation](/platform/actors/development/actor-definition/dataset-schema).  (e.g. overview)
  --skipFailedPages: oneof<nothing, bool> # If `true` or `1` then, the all the items with errorInfo property will be skipped from the output.  This feature is here to emulate functionality of API version 1 used for the legacy Apify Crawler product and it's not recommended to use it in new integrations.  (e.g. false)
  --feedTitle: string # Overrides the auto-generated RSS channel `<title>` element. Only used when `format=rss`. If not provided, the title defaults to `Dataset <label>`.  (e.g. Latest posts from r/pasta)
  --feedDescription: string # Overrides the auto-generated RSS channel `<description>` element. Only used when `format=rss`. If not provided, the description defaults to `Items in dataset with id "<datasetId>".`  (e.g. Scraped forum posts)
  --signature: string # Signature used for the access. (e.g. 2wTI46Bg8qWQrV7tavlPI)
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "clean" $clean "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "outputFields" $outputFields "scalar") (serialize-qp "omit" $omit "scalar") (serialize-qp "unwind" $unwind "scalar") (serialize-qp "flatten" $flatten "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "attachment" $attachment "scalar") (serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "bom" $bom "scalar") (serialize-qp "xmlRoot" $xmlRoot "scalar") (serialize-qp "xmlRow" $xmlRow "scalar") (serialize-qp "skipHeaderRow" $skipHeaderRow "scalar") (serialize-qp "skipHidden" $skipHidden "scalar") (serialize-qp "skipEmpty" $skipEmpty "scalar") (serialize-qp "simplified" $simplified "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "skipFailedPages" $skipFailedPages "scalar") (serialize-qp "feedTitle" $feedTitle "scalar") (serialize-qp "feedDescription" $feedDescription "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/dataset/items" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Store items in last run's dataset
#
# POST /v2/actors/{actorId}/runs/last/dataset/items
# operationId: act_runs_last_dataset_items_post
export def "actors-runs-last-dataset-items post" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/dataset/items" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get last run's dataset statistics
#
# GET /v2/actors/{actorId}/runs/last/dataset/statistics
# operationId: act_runs_last_dataset_statistics_get
export def "actors-runs-last-dataset-statistics get" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> record<data: record<fieldStatistics: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/dataset/statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last run's default store
#
# GET /v2/actors/{actorId}/runs/last/key-value-store
# operationId: act_runs_last_keyValueStore_get
export def "actors-runs-last-key-value-store get" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> record<data: record<id: string, name: string, userId: string, username: string, createdAt: string, modifiedAt: string, accessedAt: string, actId: string, actRunId: string, consoleUrl: string, keysPublicUrl: string, recordsPublicUrl: string, schema: record, urlSigningSecretKey: string, generalAccess: string, stats: record<readCount: int, writeCount: int, deleteCount: int, listCount: int, s3StorageBytes: int, storageBytes: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/key-value-store" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update last run's default store
#
# PUT /v2/actors/{actorId}/runs/last/key-value-store
# operationId: act_runs_last_keyValueStore_put
export def "actors-runs-last-key-value-store put" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --name: string # nullable
  --generalAccess: string@generalAccess-completer # Defines the general access level for the resource.
]: any -> record<data: record<id: string, name: string, userId: string, username: string, createdAt: string, modifiedAt: string, accessedAt: string, actId: string, actRunId: string, consoleUrl: string, keysPublicUrl: string, recordsPublicUrl: string, schema: record, urlSigningSecretKey: string, generalAccess: string, stats: record<readCount: int, writeCount: int, deleteCount: int, listCount: int, s3StorageBytes: int, storageBytes: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/key-value-store" $qp)
  let body = {name: $name, generalAccess: $generalAccess} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete last run's default store
#
# DELETE /v2/actors/{actorId}/runs/last/key-value-store
# operationId: act_runs_last_keyValueStore_delete
export def "actors-runs-last-key-value-store delete" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/key-value-store" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last run's default store's list of keys
#
# GET /v2/actors/{actorId}/runs/last/key-value-store/keys
# operationId: act_runs_last_keyValueStore_keys_get
export def "actors-runs-last-key-value-store-keys get" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --exclusiveStartKey: string # All keys up to this one (including) are skipped from the result. (e.g. Ihnsp8YrvJ8102Kj)
  --limit: float # Number of keys to be returned. (format: int32, default: 1000, e.g. 100)
  --collection: string # Limit the results to keys that belong to a specific collection from the key-value store schema. The key-value store need to have a schema defined for this parameter to work. (e.g. postImages)
  --prefix: string # Limit the results to keys that start with a specific prefix. (e.g. post-images-)
  --signature: string # Signature used for the access. (e.g. 2wTI46Bg8qWQrV7tavlPI)
]: nothing -> record<data: record<items: list<record>, count: int, limit: int, exclusiveStartKey: string, isTruncated: bool, nextExclusiveStartKey: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "exclusiveStartKey" $exclusiveStartKey "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "collection" $collection "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/key-value-store/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download last run's default store's records
#
# GET /v2/actors/{actorId}/runs/last/key-value-store/records
# operationId: act_runs_last_keyValueStore_records_get
export def "actors-runs-last-key-value-store-records list" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --collection: string # If specified, only records belonging to a specific collection from the key-value store schema. The key-value store need to have a schema defined for this parameter to work.  (e.g. my-collection)
  --prefix: string # If specified, only records whose key starts with the given prefix are included in the archive.  (e.g. my-prefix/)
  --signature: string # Signature used for the access. (e.g. 2wTI46Bg8qWQrV7tavlPI)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "collection" $collection "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/key-value-store/records" $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last run's default store's record
#
# GET /v2/actors/{actorId}/runs/last/key-value-store/records/{recordKey}
# operationId: act_runs_last_keyValueStore_record_get
export def "actors-runs-last-key-value-store-records get" [
  actorId: string
  recordKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --signature: string # Signature used for the access. (e.g. 2wTI46Bg8qWQrV7tavlPI)
  --attachment: oneof<nothing, bool> # If `true` or `1`, the response will be served with `Content-Disposition: attachment` header, causing web browsers to offer downloading HTML records instead of displaying them.  (e.g. true)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "signature" $signature "scalar") (serialize-qp "attachment" $attachment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/key-value-store/records/($recordKey)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Store record in last run's default store
#
# PUT /v2/actors/{actorId}/runs/last/key-value-store/records/{recordKey}
# operationId: act_runs_last_keyValueStore_record_put
export def "actors-runs-last-key-value-store-records put" [
  actorId: string
  recordKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --Content-Encoding: string@Content-Encoding-completer
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/key-value-store/records/($recordKey)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Encoding": $Content_Encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Store record in last run's default store (POST)
#
# POST /v2/actors/{actorId}/runs/last/key-value-store/records/{recordKey}
# operationId: act_runs_last_keyValueStore_record_post
export def "actors-runs-last-key-value-store-records post" [
  actorId: string
  recordKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --Content-Encoding: string@Content-Encoding-completer
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/key-value-store/records/($recordKey)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Encoding": $Content_Encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete last run's default store's record
#
# DELETE /v2/actors/{actorId}/runs/last/key-value-store/records/{recordKey}
# operationId: act_runs_last_keyValueStore_record_delete
export def "actors-runs-last-key-value-store-records delete" [
  actorId: string
  recordKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/key-value-store/records/($recordKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last run's default request queue
#
# GET /v2/actors/{actorId}/runs/last/request-queue
# operationId: act_runs_last_requestQueue_get
export def "actors-runs-last-request-queue get" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> record<data: record<id: string, name: string, userId: string, actId: string, actRunId: string, createdAt: string, modifiedAt: string, accessedAt: string, totalRequestCount: int, handledRequestCount: int, pendingRequestCount: int, hadMultipleClients: bool, consoleUrl: string, stats: record<deleteCount: int, headItemReadCount: int, readCount: int, storageBytes: int, writeCount: int>, generalAccess: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/request-queue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update last run's default request queue
#
# PUT /v2/actors/{actorId}/runs/last/request-queue
# operationId: act_runs_last_requestQueue_put
export def "actors-runs-last-request-queue put" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --name: string # The new name for the request queue. (nullable)
  --generalAccess: string@generalAccess-completer # Defines the general access level for the resource.
]: any -> record<data: record<id: string, name: string, userId: string, actId: string, actRunId: string, createdAt: string, modifiedAt: string, accessedAt: string, totalRequestCount: int, handledRequestCount: int, pendingRequestCount: int, hadMultipleClients: bool, consoleUrl: string, stats: record<deleteCount: int, headItemReadCount: int, readCount: int, storageBytes: int, writeCount: int>, generalAccess: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/request-queue" $qp)
  let body = {name: $name, generalAccess: $generalAccess} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete last run's default request queue
#
# DELETE /v2/actors/{actorId}/runs/last/request-queue
# operationId: act_runs_last_requestQueue_delete
export def "actors-runs-last-request-queue delete" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/request-queue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List last run's default request queue's requests
#
# GET /v2/actors/{actorId}/runs/last/request-queue/requests
# operationId: act_runs_last_requestQueue_requests_get
@deprecated --flag exclusiveStartId
export def "actors-runs-last-request-queue-requests list" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --exclusiveStartId: string # All requests up to this one (including) are skipped from the result. (Deprecated, use `cursor` instead.) (DEPRECATED, e.g. Ihnsp8YrvJ8102Kj)
  --limit: float # Number of keys to be returned. Maximum value is `10000`. (format: double, e.g. 100)
  --cursor: string # A cursor string for pagination, returned in the previous response as `nextCursor`. Use this to retrieve the next page of requests. (e.g. eyJyZXF1ZXN0SWQiOiI2OFRqQ2RaTDNvM2hiUU0ifQ)
  --filter: list # Filter requests by their state. Possible values are `locked` and `pending`. You can combine multiple values separated by commas, which will mean the union of these filters – requests matching any of the specified states will be returned. (Not compatible with deprecated `exclusiveStartId` parameter.) (e.g. [locked])
]: nothing -> record<data: record<items: list<record>, limit: int, exclusiveStartId: string, cursor: string, nextCursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "exclusiveStartId" $exclusiveStartId "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "filter" $filter "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/request-queue/requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add request to last run's default request queue
#
# POST /v2/actors/{actorId}/runs/last/request-queue/requests
# operationId: act_runs_last_requestQueue_requests_post
export def "actors-runs-last-request-queue-requests post" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --forefront: string # Determines if request should be added to the head of the queue or to the end. Default value is `false` (end of queue).  (e.g. false)
  --uniqueKey: string # A unique key used for request de-duplication. Requests with the same unique key are considered identical.
  --body-url: string # The URL of the request.
  --method: string@method-completer
  --retryCount: int # The number of times this request has been retried.
  --loadedUrl: string # The final URL that was loaded, after redirects (if any). (nullable)
  --payload: string # The request payload, typically used with POST or PUT requests. (nullable)
  --headers: record # HTTP headers sent with the request. (nullable)
  --userData: record # Custom user data attached to the request. Can contain arbitrary fields. (e.g. {label: DETAIL, customField: custom-value})
  --noRetry: oneof<nothing, bool> # Indicates whether the request should not be retried if processing fails. (nullable)
  --errorMessages: list # Error messages recorded from failed processing attempts. (nullable)
  --handledAt: string # The timestamp when the request was marked as handled, if applicable. (nullable, format: date-time)
]: any -> record<data: record<requestId: string, wasAlreadyPresent: bool, wasAlreadyHandled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "forefront" $forefront "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/request-queue/requests" $qp)
  let body = {uniqueKey: $uniqueKey, url: $body_url, method: $method, retryCount: $retryCount, loadedUrl: $loadedUrl, payload: $payload, headers: $headers, userData: $userData, noRetry: $noRetry, errorMessages: $errorMessages, handledAt: $handledAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Batch add requests to last run's default request queue
#
# POST /v2/actors/{actorId}/runs/last/request-queue/requests/batch
# operationId: act_runs_last_requestQueue_requests_batch_post
export def "actors-runs-last-request-queue-requests-batch post" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --forefront: string # Determines if request should be added to the head of the queue or to the end. Default value is `false` (end of queue).  (e.g. false)
  --body: record
]: any -> record<data: record<processedRequests: list<record>, unprocessedRequests: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "forefront" $forefront "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/request-queue/requests/batch" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Batch delete requests from last run's default request queue
#
# DELETE /v2/actors/{actorId}/runs/last/request-queue/requests/batch
# operationId: act_runs_last_requestQueue_requests_batch_delete
export def "actors-runs-last-request-queue-requests-batch delete" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --Content-Type: string
  --body: record
]: any -> record<data: record<processedRequests: list<any>, unprocessedRequests: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/request-queue/requests/batch" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unlock requests in last run's default request queue
#
# POST /v2/actors/{actorId}/runs/last/request-queue/requests/unlock
# operationId: act_runs_last_requestQueue_requests_unlock_post
export def "actors-runs-last-request-queue-requests-unlock post" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
]: nothing -> record<data: record<unlockedCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/request-queue/requests/unlock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get request from last run's default request queue
#
# GET /v2/actors/{actorId}/runs/last/request-queue/requests/{requestId}
# operationId: act_runs_last_requestQueue_request_get
export def "actors-runs-last-request-queue-requests get" [
  actorId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> record<data: record<uniqueKey: string, url: string, method: string, retryCount: int, loadedUrl: string, payload: string, headers: record, userData: record, noRetry: bool, errorMessages: list<string>, handledAt: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/request-queue/requests/($requestId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update request in last run's default request queue
#
# PUT /v2/actors/{actorId}/runs/last/request-queue/requests/{requestId}
# operationId: act_runs_last_requestQueue_request_put
export def "actors-runs-last-request-queue-requests put" [
  actorId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --forefront: string # Determines if request should be added to the head of the queue or to the end. Default value is `false` (end of queue).  (e.g. false)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --uniqueKey: string # A unique key used for request de-duplication. Requests with the same unique key are considered identical.
  --body-url: string # The URL of the request.
  --method: string@method-completer
  --retryCount: int # The number of times this request has been retried.
  --loadedUrl: string # The final URL that was loaded, after redirects (if any). (nullable)
  --payload: string # The request payload, typically used with POST or PUT requests. (nullable)
  --headers: record # HTTP headers sent with the request. (nullable)
  --userData: record # Custom user data attached to the request. Can contain arbitrary fields. (e.g. {label: DETAIL, customField: custom-value})
  --noRetry: oneof<nothing, bool> # Indicates whether the request should not be retried if processing fails. (nullable)
  --errorMessages: list # Error messages recorded from failed processing attempts. (nullable)
  --handledAt: string # The timestamp when the request was marked as handled, if applicable. (nullable, format: date-time)
  --id: string # A unique identifier assigned to the request.
]: any -> record<data: record<requestId: string, wasAlreadyPresent: bool, wasAlreadyHandled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "forefront" $forefront "scalar") (serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/request-queue/requests/($requestId)" $qp)
  let body = {uniqueKey: $uniqueKey, url: $body_url, method: $method, retryCount: $retryCount, loadedUrl: $loadedUrl, payload: $payload, headers: $headers, userData: $userData, noRetry: $noRetry, errorMessages: $errorMessages, handledAt: $handledAt, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete request from last run's default request queue
#
# DELETE /v2/actors/{actorId}/runs/last/request-queue/requests/{requestId}
# operationId: act_runs_last_requestQueue_request_delete
export def "actors-runs-last-request-queue-requests delete" [
  actorId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/request-queue/requests/($requestId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Prolong lock on request in last run's default request queue
#
# PUT /v2/actors/{actorId}/runs/last/request-queue/requests/{requestId}/lock
# operationId: act_runs_last_requestQueue_request_lock_put
export def "actors-runs-last-request-queue-requests-lock put" [
  actorId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --lockSecs: float # How long the requests will be locked for (in seconds). (format: double, e.g. 60)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --forefront: string # Determines if request should be added to the head of the queue or to the end after lock expires.  (e.g. false)
]: nothing -> record<data: record<lockExpiresAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "lockSecs" $lockSecs "scalar") (serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "forefront" $forefront "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/request-queue/requests/($requestId)/lock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete lock on request in last run's default request queue
#
# DELETE /v2/actors/{actorId}/runs/last/request-queue/requests/{requestId}/lock
# operationId: act_runs_last_requestQueue_request_lock_delete
export def "actors-runs-last-request-queue-requests-lock delete" [
  actorId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --forefront: string # Determines if request should be added to the head of the queue or to the end after lock was removed.  (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "forefront" $forefront "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/request-queue/requests/($requestId)/lock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last run's default request queue head
#
# GET /v2/actors/{actorId}/runs/last/request-queue/head
# operationId: act_runs_last_requestQueue_head_get
export def "actors-runs-last-request-queue-head get" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --limit: float # How many items from queue should be returned. (format: double, e.g. 100)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
]: nothing -> record<data: record<limit: int, queueModifiedAt: string, hadMultipleClients: bool, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/request-queue/head" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get and lock last run's default request queue head
#
# POST /v2/actors/{actorId}/runs/last/request-queue/head/lock
# operationId: act_runs_last_requestQueue_head_lock_post
export def "actors-runs-last-request-queue-head-lock post" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --lockSecs: float # How long the requests will be locked for (in seconds). (format: double, e.g. 60)
  --limit: float # How many items from the queue should be returned. (format: double, e.g. 25)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
]: nothing -> record<data: record<limit: int, queueModifiedAt: string, queueHasLockedRequests: bool, clientKey: string, hadMultipleClients: bool, lockSecs: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "lockSecs" $lockSecs "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/request-queue/head/lock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last Actor run's log
#
# GET /v2/actors/{actorId}/runs/last/log
# operationId: act_runs_last_log_get
export def "actors-runs-last-log get" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stream: oneof<nothing, bool> # If `true` or `1` then the logs will be streamed as long as the run or build is running.  (e.g. false)
  --download: oneof<nothing, bool> # If `true` or `1` then the web browser will download the log file rather than open it in a tab.  (e.g. false)
  --qp-raw: oneof<nothing, bool> # If `true` or `1`, the logs will be kept verbatim. By default, the API removes ANSI escape codes from the logs, keeping only printable characters.  (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stream" $stream "scalar") (serialize-qp "download" $download "scalar") (serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/log" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abort Actor's last run
#
# POST /v2/actors/{actorId}/runs/last/abort
# operationId: act_runs_last_abort_post
export def "actors-runs-last-abort post" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --gracefully: oneof<nothing, bool> # If true passed, the Actor run will abort gracefully. It will send `aborting` and `persistState` event into run and force-stop the run after 30 seconds. It is helpful in cases where you plan to resurrect the run later.  (e.g. true)
]: nothing -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "gracefully" $gracefully "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/abort" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Metamorph Actor's last run
#
# POST /v2/actors/{actorId}/runs/last/metamorph
# operationId: act_runs_last_metamorph_post
export def "actors-runs-last-metamorph post" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --targetActorId: string # ID of a target Actor that the run should be transformed into. (e.g. HDSasDasz78YcAPEB)
  --build: string # Optional build of the target Actor.  It can be either a build tag or build number. By default, the run uses the build specified in the default run configuration for the target Actor (typically `latest`).  (e.g. beta)
]: nothing -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "targetActorId" $targetActorId "scalar") (serialize-qp "build" $build "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/metamorph" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reboot Actor's last run
#
# POST /v2/actors/{actorId}/runs/last/reboot
# operationId: act_runs_last_reboot_post
export def "actors-runs-last-reboot post" [
  actorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/last/reboot" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get run
#
# GET /v2/actors/{actorId}/runs/{runId}
# DEPRECATED
# operationId: act_run_get
@deprecated
export def "actors-runs get" [
  actorId: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --waitForFinish: float # The maximum number of seconds the server waits for the run to finish. By default it is `0`, the maximum value is `60`. <!-- MAX_ACTOR_JOB_ASYNC_WAIT_SECS --> If the run finishes in time then the returned run object will have a terminal status (e.g. `SUCCEEDED`), otherwise it will have a transitional status (e.g. `RUNNING`).  (format: double, e.g. 60)
]: nothing -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "waitForFinish" $waitForFinish "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/($runId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abort run
#
# POST /v2/actors/{actorId}/runs/{runId}/abort
# DEPRECATED
# operationId: act_run_abort_post
@deprecated
export def "actors-runs-abort post" [
  actorId: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --gracefully: oneof<nothing, bool> # If true passed, the Actor run will abort gracefully. It will send `aborting` and `persistState` event into run and force-stop the run after 30 seconds. It is helpful in cases where you plan to resurrect the run later.  (e.g. true)
]: nothing -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gracefully" $gracefully "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/($runId)/abort" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Metamorph run
#
# POST /v2/actors/{actorId}/runs/{runId}/metamorph
# DEPRECATED
# operationId: act_run_metamorph_post
@deprecated
export def "actors-runs-metamorph post" [
  actorId: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --targetActorId: string # ID of a target Actor that the run should be transformed into. (e.g. HDSasDasz78YcAPEB)
  --build: string # Optional build of the target Actor.  It can be either a build tag or build number. By default, the run uses the build specified in the default run configuration for the target Actor (typically `latest`).  (e.g. beta)
]: nothing -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "targetActorId" $targetActorId "scalar") (serialize-qp "build" $build "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actors/($actorId)/runs/($runId)/metamorph" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of tasks
#
# GET /v2/actor-tasks
# operationId: actorTasks_get
export def "actor-tasks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. The default value as well as the maximum is `1000`.  (format: double, e.g. 1000)
  --desc: oneof<nothing, bool> # If `true` or `1` then the objects are sorted by the `createdAt` field in descending order. By default, they are sorted in ascending order.  (e.g. true)
]: nothing -> record<data: record<total: int, offset: int, limit: int, desc: bool, count: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "desc" $desc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/actor-tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create task
#
# POST /v2/actor-tasks
# operationId: actorTasks_post
export def "actor-tasks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  actId: string
  --name: string
  --options: any
  --input: any
  --title: string # nullable
  --actorStandby: any
]: any -> record<data: record<id: string, userId: string, actId: string, name: string, username: string, createdAt: string, modifiedAt: string, removedAt: string, stats: any, options: any, input: any, title: string, actorStandby: any, standbyUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/actor-tasks")
  let body = {actId: $actId, name: $name, options: $options, input: $input, title: $title, actorStandby: $actorStandby} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get task
#
# GET /v2/actor-tasks/{actorTaskId}
# operationId: actorTask_get
export def "actor-tasks get" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, userId: string, actId: string, name: string, username: string, createdAt: string, modifiedAt: string, removedAt: string, stats: any, options: any, input: any, title: string, actorStandby: any, standbyUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update task
#
# PUT /v2/actor-tasks/{actorTaskId}
# operationId: actorTask_put
export def "actor-tasks put" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --options: any
  --input: any
  --title: string # nullable
  --actorStandby: any
]: any -> record<data: record<id: string, userId: string, actId: string, name: string, username: string, createdAt: string, modifiedAt: string, removedAt: string, stats: any, options: any, input: any, title: string, actorStandby: any, standbyUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)")
  let body = {name: $name, options: $options, input: $input, title: $title, actorStandby: $actorStandby} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete task
#
# DELETE /v2/actor-tasks/{actorTaskId}
# operationId: actorTask_delete
export def "actor-tasks delete" [
  actorTaskId: string
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
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get task input
#
# GET /v2/actor-tasks/{actorTaskId}/input
# operationId: actorTask_input_get
export def "actor-tasks-input get" [
  actorTaskId: string
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
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/input")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update task input
#
# PUT /v2/actor-tasks/{actorTaskId}/input
# operationId: actorTask_input_put
export def "actor-tasks-input put" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/input")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get list of webhooks
#
# GET /v2/actor-tasks/{actorTaskId}/webhooks
# operationId: actorTask_webhooks_get
export def "actor-tasks-webhooks get" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. The default value as well as the maximum is `1000`.  (format: double, e.g. 1000)
  --desc: oneof<nothing, bool> # If `true` or `1` then the objects are sorted by the `createdAt` field in descending order. By default, they are sorted in ascending order.  (e.g. true)
]: nothing -> record<data: record<total: int, offset: int, limit: int, desc: bool, count: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "desc" $desc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of task runs
#
# GET /v2/actor-tasks/{actorTaskId}/runs
# operationId: actorTask_runs_get
export def "actor-tasks-runs get" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. The default value as well as the maximum is `1000`.  (format: double, e.g. 1000)
  --desc: oneof<nothing, bool> # If `true` or `1` then the objects are sorted by the `startedAt` field in descending order. By default, they are sorted in ascending order.  (e.g. true)
  --status: list # Single status or comma-separated list of statuses, see ([available statuses](https://docs.apify.com/platform/actors/running/runs-and-builds#lifecycle)). Used to filter runs by the specified statuses only.  (e.g. [SUCCEEDED])
]: nothing -> record<data: record<total: int, offset: int, limit: int, desc: bool, count: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "status" $status "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run task
#
# POST /v2/actor-tasks/{actorTaskId}/runs
# operationId: actorTask_runs_post
export def "actor-tasks-runs post" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: float # Optional timeout for the run, in seconds. By default, the run uses the timeout from its configuration.  (format: double, e.g. 60)
  --memory: float # Memory limit for the run, in megabytes. The amount of memory can be set to a power of 2 with a minimum of 128. By default, the run uses the memory limit from its configuration.  (format: double, e.g. 256)
  --maxItems: float # Specifies the maximum number of dataset items that will be charged for pay-per-result Actors. This does NOT guarantee that the Actor will return only this many items. It only ensures you won't be charged for more than this number of items. Only works for pay-per-result Actors. Value can be accessed in the actor run using `ACTOR_MAX_PAID_DATASET_ITEMS` environment variable.  (format: double, e.g. 1000)
  --maxTotalChargeUsd: float # Specifies the maximum cost of the run. This parameter is useful for pay-per-event Actors, as it allows you to limit the amount charged to your subscription. You can access the maximum cost in your Actor by using the `ACTOR_MAX_TOTAL_CHARGE_USD` environment variable.  (format: double, e.g. 5)
  --restartOnError: oneof<nothing, bool> # Determines whether the run will be restarted if it fails.  (e.g. false)
  --build: string # Specifies the Actor build to run. It can be either a build tag or build number. By default, the run uses the build from its configuration (typically `latest`).  (e.g. 0.1.234)
  --waitForFinish: float # The maximum number of seconds the server waits for the run to finish. By default it is `0`, the maximum value is `60`. <!-- MAX_ACTOR_JOB_ASYNC_WAIT_SECS --> If the run finishes in time then the returned run object will have a terminal status (e.g. `SUCCEEDED`), otherwise it will have a transitional status (e.g. `RUNNING`).  (format: double, e.g. 60)
  --webhooks: string # Specifies optional webhooks associated with the Actor run, which can be used to receive a notification e.g. when the Actor finished or failed. The value is a Base64-encoded JSON array whose items follow the WebhookRepresentation schema. For more information, see [Webhooks documentation](https://docs.apify.com/platform/integrations/webhooks).  (e.g. dGhpcyBpcyBqdXN0IGV4YW1wbGUK...)
  --body: record
]: any -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "memory" $memory "scalar") (serialize-qp "maxItems" $maxItems "scalar") (serialize-qp "maxTotalChargeUsd" $maxTotalChargeUsd "scalar") (serialize-qp "restartOnError" $restartOnError "scalar") (serialize-qp "build" $build "scalar") (serialize-qp "waitForFinish" $waitForFinish "scalar") (serialize-qp "webhooks" $webhooks "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Run task synchronously
#
# GET /v2/actor-tasks/{actorTaskId}/run-sync
# operationId: actorTask_runSync_get
export def "actor-tasks-run-sync get" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: float # Optional timeout for the run, in seconds. By default, the run uses the timeout from its configuration.  (format: double, e.g. 60)
  --memory: float # Memory limit for the run, in megabytes. The amount of memory can be set to a power of 2 with a minimum of 128. By default, the run uses the memory limit from its configuration.  (format: double, e.g. 256)
  --maxItems: float # Specifies the maximum number of dataset items that will be charged for pay-per-result Actors. This does NOT guarantee that the Actor will return only this many items. It only ensures you won't be charged for more than this number of items. Only works for pay-per-result Actors. Value can be accessed in the actor run using `ACTOR_MAX_PAID_DATASET_ITEMS` environment variable.  (format: double, e.g. 1000)
  --build: string # Specifies the Actor build to run. It can be either a build tag or build number. By default, the run uses the build from its configuration (typically `latest`).  (e.g. 0.1.234)
  --outputRecordKey: string # Key of the record from run's default key-value store to be returned in the response. By default, it is `OUTPUT`.  (e.g. OUTPUT)
  --webhooks: string # Specifies optional webhooks associated with the Actor run, which can be used to receive a notification e.g. when the Actor finished or failed. The value is a Base64-encoded JSON array whose items follow the WebhookRepresentation schema. For more information, see [Webhooks documentation](https://docs.apify.com/platform/integrations/webhooks).  (e.g. dGhpcyBpcyBqdXN0IGV4YW1wbGUK...)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "memory" $memory "scalar") (serialize-qp "maxItems" $maxItems "scalar") (serialize-qp "build" $build "scalar") (serialize-qp "outputRecordKey" $outputRecordKey "scalar") (serialize-qp "webhooks" $webhooks "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/run-sync" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run task synchronously
#
# POST /v2/actor-tasks/{actorTaskId}/run-sync
# operationId: actorTask_runSync_post
export def "actor-tasks-run-sync post" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: float # Optional timeout for the run, in seconds. By default, the run uses the timeout from its configuration.  (format: double, e.g. 60)
  --memory: float # Memory limit for the run, in megabytes. The amount of memory can be set to a power of 2 with a minimum of 128. By default, the run uses the memory limit from its configuration.  (format: double, e.g. 256)
  --maxItems: float # Specifies the maximum number of dataset items that will be charged for pay-per-result Actors. This does NOT guarantee that the Actor will return only this many items. It only ensures you won't be charged for more than this number of items. Only works for pay-per-result Actors. Value can be accessed in the actor run using `ACTOR_MAX_PAID_DATASET_ITEMS` environment variable.  (format: double, e.g. 1000)
  --maxTotalChargeUsd: float # Specifies the maximum cost of the run. This parameter is useful for pay-per-event Actors, as it allows you to limit the amount charged to your subscription. You can access the maximum cost in your Actor by using the `ACTOR_MAX_TOTAL_CHARGE_USD` environment variable.  (format: double, e.g. 5)
  --restartOnError: oneof<nothing, bool> # Determines whether the run will be restarted if it fails.  (e.g. false)
  --build: string # Specifies the Actor build to run. It can be either a build tag or build number. By default, the run uses the build from its configuration (typically `latest`).  (e.g. 0.1.234)
  --outputRecordKey: string # Key of the record from run's default key-value store to be returned in the response. By default, it is `OUTPUT`.  (e.g. OUTPUT)
  --webhooks: string # Specifies optional webhooks associated with the Actor run, which can be used to receive a notification e.g. when the Actor finished or failed. The value is a Base64-encoded JSON array whose items follow the WebhookRepresentation schema. For more information, see [Webhooks documentation](https://docs.apify.com/platform/integrations/webhooks).  (e.g. dGhpcyBpcyBqdXN0IGV4YW1wbGUK...)
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "memory" $memory "scalar") (serialize-qp "maxItems" $maxItems "scalar") (serialize-qp "maxTotalChargeUsd" $maxTotalChargeUsd "scalar") (serialize-qp "restartOnError" $restartOnError "scalar") (serialize-qp "build" $build "scalar") (serialize-qp "outputRecordKey" $outputRecordKey "scalar") (serialize-qp "webhooks" $webhooks "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/run-sync" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Run task synchronously and get dataset items
#
# GET /v2/actor-tasks/{actorTaskId}/run-sync-get-dataset-items
# operationId: actorTask_runSyncGetDatasetItems_get
export def "actor-tasks-run-sync-get-dataset-items get" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: float # Optional timeout for the run, in seconds. By default, the run uses the timeout from its configuration.  (format: double, e.g. 60)
  --memory: float # Memory limit for the run, in megabytes. The amount of memory can be set to a power of 2 with a minimum of 128. By default, the run uses the memory limit from its configuration.  (format: double, e.g. 256)
  --maxItems: float # Specifies the maximum number of dataset items that will be charged for pay-per-result Actors. This does NOT guarantee that the Actor will return only this many items. It only ensures you won't be charged for more than this number of items. Only works for pay-per-result Actors. Value can be accessed in the actor run using `ACTOR_MAX_PAID_DATASET_ITEMS` environment variable.  (format: double, e.g. 1000)
  --build: string # Specifies the Actor build to run. It can be either a build tag or build number. By default, the run uses the build from its configuration (typically `latest`).  (e.g. 0.1.234)
  --webhooks: string # Specifies optional webhooks associated with the Actor run, which can be used to receive a notification e.g. when the Actor finished or failed. The value is a Base64-encoded JSON array whose items follow the WebhookRepresentation schema. For more information, see [Webhooks documentation](https://docs.apify.com/platform/integrations/webhooks).  (e.g. dGhpcyBpcyBqdXN0IGV4YW1wbGUK...)
  --format: string # Format of the results, possible values are: `json`, `jsonl`, `csv`, `html`, `xlsx`, `xml` and `rss`. The default value is `json`.  (e.g. json)
  --clean: oneof<nothing, bool> # If `true` or `1` then the API endpoint returns only non-empty items and skips hidden fields (i.e. fields starting with the # character). The `clean` parameter is just a shortcut for `skipHidden=true` and `skipEmpty=true` parameters. Note that since some objects might be skipped from the output, that the result might contain less items than the `limit` value.  (e.g. false)
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. By default there is no limit. (format: double)
  --qp-fields: string # A comma-separated list of fields which should be picked from the items, only these fields will remain in the resulting record objects. Note that the fields in the outputted items are sorted the same way as they are specified in the `fields` query parameter. You can use this feature to effectively fix the output format.  (e.g. myValue,myOtherValue)
  --outputFields: string # A comma-separated list of output field names that positionally rename the fields specified in the `fields` parameter. For example, `?fields=headline,url&outputFields=title,link` renames `headline` to `title` and `url` to `link` in the output. The number of names in `outputFields` must match the number of names in `fields`. Requires the `fields` parameter to be specified as well.  (e.g. title,link)
  --omit: string # A comma-separated list of fields which should be omitted from the items. (e.g. myValue,myOtherValue)
  --unwind: string # A comma-separated list of fields which should be unwound, in order which they should be processed. Each field should be either an array or an object. If the field is an array then every element of the array will become a separate record and merged with parent object. If the unwound field is an object then it is merged with the parent object. If the unwound field is missing or its value is neither an array nor an object and therefore cannot be merged with a parent object then the item gets preserved as it is. Note that the unwound items ignore the `desc` parameter.  (e.g. myValue,myOtherValue)
  --flatten: string # A comma-separated list of fields which should transform nested objects into flat structures.  For example, with `flatten="foo"` the object `{"foo":{"bar": "hello"}}` is turned into `{"foo.bar": "hello"}`.  The original object with properties is replaced with the flattened object.  (e.g. myValue)
  --desc: oneof<nothing, bool> # By default, results are returned in the same order as they were stored. To reverse the order, set this parameter to `true` or `1`.  (e.g. true)
  --attachment: oneof<nothing, bool> # If `true` or `1` then the response will define the `Content-Disposition: attachment` header, forcing a web browser to download the file rather than to display it. By default this header is not present.  (e.g. true)
  --delimiter: string # A delimiter character for CSV files, only used if `format=csv`. You might need to URL-encode the character (e.g. use `%09` for tab or `%3B` for semicolon). The default delimiter is a simple comma (`,`).  (e.g. ;)
  --bom: oneof<nothing, bool> # All text responses are encoded in UTF-8 encoding. By default, the `format=csv` files are prefixed with the UTF-8 Byte Order Mark (BOM), while `json`, `jsonl`, `xml`, `html` and `rss` files are not.  If you want to override this default behavior, specify `bom=1` query parameter to include the BOM or `bom=0` to skip it.  (e.g. false)
  --xmlRoot: string # Overrides default root element name of `xml` output. By default the root element is `items`.  (e.g. items)
  --xmlRow: string # Overrides default element name that wraps each page or page function result object in `xml` output. By default the element name is `item`.  (e.g. item)
  --skipHeaderRow: oneof<nothing, bool> # If `true` or `1` then header row in the `csv` format is skipped. (e.g. true)
  --skipHidden: oneof<nothing, bool> # If `true` or `1` then hidden fields are skipped from the output, i.e. fields starting with the `#` character.  (e.g. false)
  --skipEmpty: oneof<nothing, bool> # If `true` or `1` then empty items are skipped from the output.  Note that if used, the results might contain less items than the limit value.  (e.g. false)
  --simplified: oneof<nothing, bool> # If `true` or `1` then, the endpoint applies the `fields=url,pageFunctionResult,errorInfo` and `unwind=pageFunctionResult` query parameters. This feature is used to emulate simplified results provided by the legacy Apify Crawler product and it's not recommended to use it in new integrations.  (e.g. false)
  --view: string # Defines the view configuration for dataset items based on the schema definition. This parameter determines how the data will be filtered and presented. For complete specification details, see the [dataset schema documentation](/platform/actors/development/actor-definition/dataset-schema).  (e.g. overview)
  --skipFailedPages: oneof<nothing, bool> # If `true` or `1` then, the all the items with errorInfo property will be skipped from the output.  This feature is here to emulate functionality of API version 1 used for the legacy Apify Crawler product and it's not recommended to use it in new integrations.  (e.g. false)
  --feedTitle: string # Overrides the auto-generated RSS channel `<title>` element. Only used when `format=rss`. If not provided, the title defaults to `Dataset <label>`.  (e.g. Latest posts from r/pasta)
  --feedDescription: string # Overrides the auto-generated RSS channel `<description>` element. Only used when `format=rss`. If not provided, the description defaults to `Items in dataset with id "<datasetId>".`  (e.g. Scraped forum posts)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "memory" $memory "scalar") (serialize-qp "maxItems" $maxItems "scalar") (serialize-qp "build" $build "scalar") (serialize-qp "webhooks" $webhooks "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "clean" $clean "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "outputFields" $outputFields "scalar") (serialize-qp "omit" $omit "scalar") (serialize-qp "unwind" $unwind "scalar") (serialize-qp "flatten" $flatten "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "attachment" $attachment "scalar") (serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "bom" $bom "scalar") (serialize-qp "xmlRoot" $xmlRoot "scalar") (serialize-qp "xmlRow" $xmlRow "scalar") (serialize-qp "skipHeaderRow" $skipHeaderRow "scalar") (serialize-qp "skipHidden" $skipHidden "scalar") (serialize-qp "skipEmpty" $skipEmpty "scalar") (serialize-qp "simplified" $simplified "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "skipFailedPages" $skipFailedPages "scalar") (serialize-qp "feedTitle" $feedTitle "scalar") (serialize-qp "feedDescription" $feedDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/run-sync-get-dataset-items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run task synchronously and get dataset items
#
# POST /v2/actor-tasks/{actorTaskId}/run-sync-get-dataset-items
# operationId: actorTask_runSyncGetDatasetItems_post
export def "actor-tasks-run-sync-get-dataset-items post" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: float # Optional timeout for the run, in seconds. By default, the run uses the timeout from its configuration.  (format: double, e.g. 60)
  --memory: float # Memory limit for the run, in megabytes. The amount of memory can be set to a power of 2 with a minimum of 128. By default, the run uses the memory limit from its configuration.  (format: double, e.g. 256)
  --maxItems: float # Specifies the maximum number of dataset items that will be charged for pay-per-result Actors. This does NOT guarantee that the Actor will return only this many items. It only ensures you won't be charged for more than this number of items. Only works for pay-per-result Actors. Value can be accessed in the actor run using `ACTOR_MAX_PAID_DATASET_ITEMS` environment variable.  (format: double, e.g. 1000)
  --maxTotalChargeUsd: float # Specifies the maximum cost of the run. This parameter is useful for pay-per-event Actors, as it allows you to limit the amount charged to your subscription. You can access the maximum cost in your Actor by using the `ACTOR_MAX_TOTAL_CHARGE_USD` environment variable.  (format: double, e.g. 5)
  --restartOnError: oneof<nothing, bool> # Determines whether the run will be restarted if it fails.  (e.g. false)
  --build: string # Specifies the Actor build to run. It can be either a build tag or build number. By default, the run uses the build from its configuration (typically `latest`).  (e.g. 0.1.234)
  --webhooks: string # Specifies optional webhooks associated with the Actor run, which can be used to receive a notification e.g. when the Actor finished or failed. The value is a Base64-encoded JSON array whose items follow the WebhookRepresentation schema. For more information, see [Webhooks documentation](https://docs.apify.com/platform/integrations/webhooks).  (e.g. dGhpcyBpcyBqdXN0IGV4YW1wbGUK...)
  --format: string # Format of the results, possible values are: `json`, `jsonl`, `csv`, `html`, `xlsx`, `xml` and `rss`. The default value is `json`.  (e.g. json)
  --clean: oneof<nothing, bool> # If `true` or `1` then the API endpoint returns only non-empty items and skips hidden fields (i.e. fields starting with the # character). The `clean` parameter is just a shortcut for `skipHidden=true` and `skipEmpty=true` parameters. Note that since some objects might be skipped from the output, that the result might contain less items than the `limit` value.  (e.g. false)
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. By default there is no limit. (format: double)
  --qp-fields: string # A comma-separated list of fields which should be picked from the items, only these fields will remain in the resulting record objects. Note that the fields in the outputted items are sorted the same way as they are specified in the `fields` query parameter. You can use this feature to effectively fix the output format.  (e.g. myValue,myOtherValue)
  --outputFields: string # A comma-separated list of output field names that positionally rename the fields specified in the `fields` parameter. For example, `?fields=headline,url&outputFields=title,link` renames `headline` to `title` and `url` to `link` in the output. The number of names in `outputFields` must match the number of names in `fields`. Requires the `fields` parameter to be specified as well.  (e.g. title,link)
  --omit: string # A comma-separated list of fields which should be omitted from the items. (e.g. myValue,myOtherValue)
  --unwind: string # A comma-separated list of fields which should be unwound, in order which they should be processed. Each field should be either an array or an object. If the field is an array then every element of the array will become a separate record and merged with parent object. If the unwound field is an object then it is merged with the parent object. If the unwound field is missing or its value is neither an array nor an object and therefore cannot be merged with a parent object then the item gets preserved as it is. Note that the unwound items ignore the `desc` parameter.  (e.g. myValue,myOtherValue)
  --flatten: string # A comma-separated list of fields which should transform nested objects into flat structures.  For example, with `flatten="foo"` the object `{"foo":{"bar": "hello"}}` is turned into `{"foo.bar": "hello"}`.  The original object with properties is replaced with the flattened object.  (e.g. myValue)
  --desc: oneof<nothing, bool> # By default, results are returned in the same order as they were stored. To reverse the order, set this parameter to `true` or `1`.  (e.g. true)
  --attachment: oneof<nothing, bool> # If `true` or `1` then the response will define the `Content-Disposition: attachment` header, forcing a web browser to download the file rather than to display it. By default this header is not present.  (e.g. true)
  --delimiter: string # A delimiter character for CSV files, only used if `format=csv`. You might need to URL-encode the character (e.g. use `%09` for tab or `%3B` for semicolon). The default delimiter is a simple comma (`,`).  (e.g. ;)
  --bom: oneof<nothing, bool> # All text responses are encoded in UTF-8 encoding. By default, the `format=csv` files are prefixed with the UTF-8 Byte Order Mark (BOM), while `json`, `jsonl`, `xml`, `html` and `rss` files are not.  If you want to override this default behavior, specify `bom=1` query parameter to include the BOM or `bom=0` to skip it.  (e.g. false)
  --xmlRoot: string # Overrides default root element name of `xml` output. By default the root element is `items`.  (e.g. items)
  --xmlRow: string # Overrides default element name that wraps each page or page function result object in `xml` output. By default the element name is `item`.  (e.g. item)
  --skipHeaderRow: oneof<nothing, bool> # If `true` or `1` then header row in the `csv` format is skipped. (e.g. true)
  --skipHidden: oneof<nothing, bool> # If `true` or `1` then hidden fields are skipped from the output, i.e. fields starting with the `#` character.  (e.g. false)
  --skipEmpty: oneof<nothing, bool> # If `true` or `1` then empty items are skipped from the output.  Note that if used, the results might contain less items than the limit value.  (e.g. false)
  --simplified: oneof<nothing, bool> # If `true` or `1` then, the endpoint applies the `fields=url,pageFunctionResult,errorInfo` and `unwind=pageFunctionResult` query parameters. This feature is used to emulate simplified results provided by the legacy Apify Crawler product and it's not recommended to use it in new integrations.  (e.g. false)
  --view: string # Defines the view configuration for dataset items based on the schema definition. This parameter determines how the data will be filtered and presented. For complete specification details, see the [dataset schema documentation](/platform/actors/development/actor-definition/dataset-schema).  (e.g. overview)
  --skipFailedPages: oneof<nothing, bool> # If `true` or `1` then, the all the items with errorInfo property will be skipped from the output.  This feature is here to emulate functionality of API version 1 used for the legacy Apify Crawler product and it's not recommended to use it in new integrations.  (e.g. false)
  --feedTitle: string # Overrides the auto-generated RSS channel `<title>` element. Only used when `format=rss`. If not provided, the title defaults to `Dataset <label>`.  (e.g. Latest posts from r/pasta)
  --feedDescription: string # Overrides the auto-generated RSS channel `<description>` element. Only used when `format=rss`. If not provided, the description defaults to `Items in dataset with id "<datasetId>".`  (e.g. Scraped forum posts)
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "memory" $memory "scalar") (serialize-qp "maxItems" $maxItems "scalar") (serialize-qp "maxTotalChargeUsd" $maxTotalChargeUsd "scalar") (serialize-qp "restartOnError" $restartOnError "scalar") (serialize-qp "build" $build "scalar") (serialize-qp "webhooks" $webhooks "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "clean" $clean "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "outputFields" $outputFields "scalar") (serialize-qp "omit" $omit "scalar") (serialize-qp "unwind" $unwind "scalar") (serialize-qp "flatten" $flatten "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "attachment" $attachment "scalar") (serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "bom" $bom "scalar") (serialize-qp "xmlRoot" $xmlRoot "scalar") (serialize-qp "xmlRow" $xmlRow "scalar") (serialize-qp "skipHeaderRow" $skipHeaderRow "scalar") (serialize-qp "skipHidden" $skipHidden "scalar") (serialize-qp "skipEmpty" $skipEmpty "scalar") (serialize-qp "simplified" $simplified "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "skipFailedPages" $skipFailedPages "scalar") (serialize-qp "feedTitle" $feedTitle "scalar") (serialize-qp "feedDescription" $feedDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/run-sync-get-dataset-items" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get last run
#
# GET /v2/actor-tasks/{actorTaskId}/runs/last
# operationId: actorTask_runs_last_get
export def "actor-tasks-runs-last get" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --waitForFinish: float # The maximum number of seconds the server waits for the run to finish. By default it is `0`, the maximum value is `60`. <!-- MAX_ACTOR_JOB_ASYNC_WAIT_SECS --> If the run finishes in time then the returned run object will have a terminal status (e.g. `SUCCEEDED`), otherwise it will have a transitional status (e.g. `RUNNING`).  (format: double, e.g. 60)
]: nothing -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "waitForFinish" $waitForFinish "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last Actor task run's log
#
# GET /v2/actor-tasks/{actorTaskId}/runs/last/log
# operationId: actorTask_last_log_get
export def "actor-tasks-runs-last-log get" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stream: oneof<nothing, bool> # If `true` or `1` then the logs will be streamed as long as the run or build is running.  (e.g. false)
  --download: oneof<nothing, bool> # If `true` or `1` then the web browser will download the log file rather than open it in a tab.  (e.g. false)
  --qp-raw: oneof<nothing, bool> # If `true` or `1`, the logs will be kept verbatim. By default, the API removes ANSI escape codes from the logs, keeping only printable characters.  (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stream" $stream "scalar") (serialize-qp "download" $download "scalar") (serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/log" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abort Actor task's last run
#
# POST /v2/actor-tasks/{actorTaskId}/runs/last/abort
# operationId: actorTask_runs_last_abort_post
export def "actor-tasks-runs-last-abort post" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --gracefully: oneof<nothing, bool> # If true passed, the Actor run will abort gracefully. It will send `aborting` and `persistState` event into run and force-stop the run after 30 seconds. It is helpful in cases where you plan to resurrect the run later.  (e.g. true)
]: nothing -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "gracefully" $gracefully "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/abort" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Metamorph Actor task's last run
#
# POST /v2/actor-tasks/{actorTaskId}/runs/last/metamorph
# operationId: actorTask_runs_last_metamorph_post
export def "actor-tasks-runs-last-metamorph post" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --targetActorId: string # ID of a target Actor that the run should be transformed into. (e.g. HDSasDasz78YcAPEB)
  --build: string # Optional build of the target Actor.  It can be either a build tag or build number. By default, the run uses the build specified in the default run configuration for the target Actor (typically `latest`).  (e.g. beta)
]: nothing -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "targetActorId" $targetActorId "scalar") (serialize-qp "build" $build "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/metamorph" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reboot Actor task's last run
#
# POST /v2/actor-tasks/{actorTaskId}/runs/last/reboot
# operationId: actorTask_runs_last_reboot_post
export def "actor-tasks-runs-last-reboot post" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/reboot" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last task run's default dataset
#
# GET /v2/actor-tasks/{actorTaskId}/runs/last/dataset
# operationId: actorTask_runs_last_dataset_get
export def "actor-tasks-runs-last-dataset get" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> record<data: record<id: string, name: string, userId: string, createdAt: string, modifiedAt: string, accessedAt: string, itemCount: int, cleanItemCount: int, actId: string, actRunId: string, fields: list<string>, schema: record, consoleUrl: string, itemsPublicUrl: string, urlSigningSecretKey: string, generalAccess: string, stats: record<readCount: int, writeCount: int, storageBytes: int, inflatedBytes: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/dataset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update last task run's default dataset
#
# PUT /v2/actor-tasks/{actorTaskId}/runs/last/dataset
# operationId: actorTask_runs_last_dataset_put
export def "actor-tasks-runs-last-dataset put" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --name: string # nullable
  --generalAccess: string@generalAccess-completer # Defines the general access level for the resource.
]: any -> record<data: record<id: string, name: string, userId: string, createdAt: string, modifiedAt: string, accessedAt: string, itemCount: int, cleanItemCount: int, actId: string, actRunId: string, fields: list<string>, schema: record, consoleUrl: string, itemsPublicUrl: string, urlSigningSecretKey: string, generalAccess: string, stats: record<readCount: int, writeCount: int, storageBytes: int, inflatedBytes: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/dataset" $qp)
  let body = {name: $name, generalAccess: $generalAccess} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete last task run's default dataset
#
# DELETE /v2/actor-tasks/{actorTaskId}/runs/last/dataset
# operationId: actorTask_runs_last_dataset_delete
export def "actor-tasks-runs-last-dataset delete" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/dataset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last task run's dataset items
#
# GET /v2/actor-tasks/{actorTaskId}/runs/last/dataset/items
# operationId: actorTask_runs_last_dataset_items_get
export def "actor-tasks-runs-last-dataset-items get" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --format: string # Format of the results, possible values are: `json`, `jsonl`, `csv`, `html`, `xlsx`, `xml` and `rss`. The default value is `json`.  (e.g. json)
  --clean: oneof<nothing, bool> # If `true` or `1` then the API endpoint returns only non-empty items and skips hidden fields (i.e. fields starting with the # character). The `clean` parameter is just a shortcut for `skipHidden=true` and `skipEmpty=true` parameters. Note that since some objects might be skipped from the output, that the result might contain less items than the `limit` value.  (e.g. false)
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. By default there is no limit. (format: double)
  --qp-fields: string # A comma-separated list of fields which should be picked from the items, only these fields will remain in the resulting record objects. Note that the fields in the outputted items are sorted the same way as they are specified in the `fields` query parameter. You can use this feature to effectively fix the output format.  (e.g. myValue,myOtherValue)
  --outputFields: string # A comma-separated list of output field names that positionally rename the fields specified in the `fields` parameter. For example, `?fields=headline,url&outputFields=title,link` renames `headline` to `title` and `url` to `link` in the output. The number of names in `outputFields` must match the number of names in `fields`. Requires the `fields` parameter to be specified as well.  (e.g. title,link)
  --omit: string # A comma-separated list of fields which should be omitted from the items. (e.g. myValue,myOtherValue)
  --unwind: string # A comma-separated list of fields which should be unwound, in order which they should be processed. Each field should be either an array or an object. If the field is an array then every element of the array will become a separate record and merged with parent object. If the unwound field is an object then it is merged with the parent object. If the unwound field is missing or its value is neither an array nor an object and therefore cannot be merged with a parent object then the item gets preserved as it is. Note that the unwound items ignore the `desc` parameter.  (e.g. myValue,myOtherValue)
  --flatten: string # A comma-separated list of fields which should transform nested objects into flat structures.  For example, with `flatten="foo"` the object `{"foo":{"bar": "hello"}}` is turned into `{"foo.bar": "hello"}`.  The original object with properties is replaced with the flattened object.  (e.g. myValue)
  --desc: oneof<nothing, bool> # By default, results are returned in the same order as they were stored. To reverse the order, set this parameter to `true` or `1`.  (e.g. true)
  --attachment: oneof<nothing, bool> # If `true` or `1` then the response will define the `Content-Disposition: attachment` header, forcing a web browser to download the file rather than to display it. By default this header is not present.  (e.g. true)
  --delimiter: string # A delimiter character for CSV files, only used if `format=csv`. You might need to URL-encode the character (e.g. use `%09` for tab or `%3B` for semicolon). The default delimiter is a simple comma (`,`).  (e.g. ;)
  --bom: oneof<nothing, bool> # All text responses are encoded in UTF-8 encoding. By default, the `format=csv` files are prefixed with the UTF-8 Byte Order Mark (BOM), while `json`, `jsonl`, `xml`, `html` and `rss` files are not.  If you want to override this default behavior, specify `bom=1` query parameter to include the BOM or `bom=0` to skip it.  (e.g. false)
  --xmlRoot: string # Overrides default root element name of `xml` output. By default the root element is `items`.  (e.g. items)
  --xmlRow: string # Overrides default element name that wraps each page or page function result object in `xml` output. By default the element name is `item`.  (e.g. item)
  --skipHeaderRow: oneof<nothing, bool> # If `true` or `1` then header row in the `csv` format is skipped. (e.g. true)
  --skipHidden: oneof<nothing, bool> # If `true` or `1` then hidden fields are skipped from the output, i.e. fields starting with the `#` character.  (e.g. false)
  --skipEmpty: oneof<nothing, bool> # If `true` or `1` then empty items are skipped from the output.  Note that if used, the results might contain less items than the limit value.  (e.g. false)
  --simplified: oneof<nothing, bool> # If `true` or `1` then, the endpoint applies the `fields=url,pageFunctionResult,errorInfo` and `unwind=pageFunctionResult` query parameters. This feature is used to emulate simplified results provided by the legacy Apify Crawler product and it's not recommended to use it in new integrations.  (e.g. false)
  --view: string # Defines the view configuration for dataset items based on the schema definition. This parameter determines how the data will be filtered and presented. For complete specification details, see the [dataset schema documentation](/platform/actors/development/actor-definition/dataset-schema).  (e.g. overview)
  --skipFailedPages: oneof<nothing, bool> # If `true` or `1` then, the all the items with errorInfo property will be skipped from the output.  This feature is here to emulate functionality of API version 1 used for the legacy Apify Crawler product and it's not recommended to use it in new integrations.  (e.g. false)
  --feedTitle: string # Overrides the auto-generated RSS channel `<title>` element. Only used when `format=rss`. If not provided, the title defaults to `Dataset <label>`.  (e.g. Latest posts from r/pasta)
  --feedDescription: string # Overrides the auto-generated RSS channel `<description>` element. Only used when `format=rss`. If not provided, the description defaults to `Items in dataset with id "<datasetId>".`  (e.g. Scraped forum posts)
  --signature: string # Signature used for the access. (e.g. 2wTI46Bg8qWQrV7tavlPI)
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "clean" $clean "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "outputFields" $outputFields "scalar") (serialize-qp "omit" $omit "scalar") (serialize-qp "unwind" $unwind "scalar") (serialize-qp "flatten" $flatten "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "attachment" $attachment "scalar") (serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "bom" $bom "scalar") (serialize-qp "xmlRoot" $xmlRoot "scalar") (serialize-qp "xmlRow" $xmlRow "scalar") (serialize-qp "skipHeaderRow" $skipHeaderRow "scalar") (serialize-qp "skipHidden" $skipHidden "scalar") (serialize-qp "skipEmpty" $skipEmpty "scalar") (serialize-qp "simplified" $simplified "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "skipFailedPages" $skipFailedPages "scalar") (serialize-qp "feedTitle" $feedTitle "scalar") (serialize-qp "feedDescription" $feedDescription "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/dataset/items" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Store items in last task run's dataset
#
# POST /v2/actor-tasks/{actorTaskId}/runs/last/dataset/items
# operationId: actorTask_runs_last_dataset_items_post
export def "actor-tasks-runs-last-dataset-items post" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/dataset/items" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get last task run's dataset statistics
#
# GET /v2/actor-tasks/{actorTaskId}/runs/last/dataset/statistics
# operationId: actorTask_runs_last_dataset_statistics_get
export def "actor-tasks-runs-last-dataset-statistics get" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> record<data: record<fieldStatistics: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/dataset/statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last task run's default store
#
# GET /v2/actor-tasks/{actorTaskId}/runs/last/key-value-store
# operationId: actorTask_runs_last_keyValueStore_get
export def "actor-tasks-runs-last-key-value-store get" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> record<data: record<id: string, name: string, userId: string, username: string, createdAt: string, modifiedAt: string, accessedAt: string, actId: string, actRunId: string, consoleUrl: string, keysPublicUrl: string, recordsPublicUrl: string, schema: record, urlSigningSecretKey: string, generalAccess: string, stats: record<readCount: int, writeCount: int, deleteCount: int, listCount: int, s3StorageBytes: int, storageBytes: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/key-value-store" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update last task run's default store
#
# PUT /v2/actor-tasks/{actorTaskId}/runs/last/key-value-store
# operationId: actorTask_runs_last_keyValueStore_put
export def "actor-tasks-runs-last-key-value-store put" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --name: string # nullable
  --generalAccess: string@generalAccess-completer # Defines the general access level for the resource.
]: any -> record<data: record<id: string, name: string, userId: string, username: string, createdAt: string, modifiedAt: string, accessedAt: string, actId: string, actRunId: string, consoleUrl: string, keysPublicUrl: string, recordsPublicUrl: string, schema: record, urlSigningSecretKey: string, generalAccess: string, stats: record<readCount: int, writeCount: int, deleteCount: int, listCount: int, s3StorageBytes: int, storageBytes: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/key-value-store" $qp)
  let body = {name: $name, generalAccess: $generalAccess} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete last task run's default store
#
# DELETE /v2/actor-tasks/{actorTaskId}/runs/last/key-value-store
# operationId: actorTask_runs_last_keyValueStore_delete
export def "actor-tasks-runs-last-key-value-store delete" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/key-value-store" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last task run's default store's list of keys
#
# GET /v2/actor-tasks/{actorTaskId}/runs/last/key-value-store/keys
# operationId: actorTask_runs_last_keyValueStore_keys_get
export def "actor-tasks-runs-last-key-value-store-keys get" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --exclusiveStartKey: string # All keys up to this one (including) are skipped from the result. (e.g. Ihnsp8YrvJ8102Kj)
  --limit: float # Number of keys to be returned. (format: int32, default: 1000, e.g. 100)
  --collection: string # Limit the results to keys that belong to a specific collection from the key-value store schema. The key-value store need to have a schema defined for this parameter to work. (e.g. postImages)
  --prefix: string # Limit the results to keys that start with a specific prefix. (e.g. post-images-)
  --signature: string # Signature used for the access. (e.g. 2wTI46Bg8qWQrV7tavlPI)
]: nothing -> record<data: record<items: list<record>, count: int, limit: int, exclusiveStartKey: string, isTruncated: bool, nextExclusiveStartKey: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "exclusiveStartKey" $exclusiveStartKey "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "collection" $collection "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/key-value-store/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download last task run's default store's records
#
# GET /v2/actor-tasks/{actorTaskId}/runs/last/key-value-store/records
# operationId: actorTask_runs_last_keyValueStore_records_get
export def "actor-tasks-runs-last-key-value-store-records list" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --collection: string # If specified, only records belonging to a specific collection from the key-value store schema. The key-value store need to have a schema defined for this parameter to work.  (e.g. my-collection)
  --prefix: string # If specified, only records whose key starts with the given prefix are included in the archive.  (e.g. my-prefix/)
  --signature: string # Signature used for the access. (e.g. 2wTI46Bg8qWQrV7tavlPI)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "collection" $collection "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/key-value-store/records" $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last task run's default store's record
#
# GET /v2/actor-tasks/{actorTaskId}/runs/last/key-value-store/records/{recordKey}
# operationId: actorTask_runs_last_keyValueStore_record_get
export def "actor-tasks-runs-last-key-value-store-records get" [
  actorTaskId: string
  recordKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --signature: string # Signature used for the access. (e.g. 2wTI46Bg8qWQrV7tavlPI)
  --attachment: oneof<nothing, bool> # If `true` or `1`, the response will be served with `Content-Disposition: attachment` header, causing web browsers to offer downloading HTML records instead of displaying them.  (e.g. true)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "signature" $signature "scalar") (serialize-qp "attachment" $attachment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/key-value-store/records/($recordKey)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Store record in last task run's default store
#
# PUT /v2/actor-tasks/{actorTaskId}/runs/last/key-value-store/records/{recordKey}
# operationId: actorTask_runs_last_keyValueStore_record_put
export def "actor-tasks-runs-last-key-value-store-records put" [
  actorTaskId: string
  recordKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --Content-Encoding: string@Content-Encoding-completer
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/key-value-store/records/($recordKey)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Encoding": $Content_Encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Store record in last task run's default store (POST)
#
# POST /v2/actor-tasks/{actorTaskId}/runs/last/key-value-store/records/{recordKey}
# operationId: actorTask_runs_last_keyValueStore_record_post
export def "actor-tasks-runs-last-key-value-store-records post" [
  actorTaskId: string
  recordKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --Content-Encoding: string@Content-Encoding-completer
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/key-value-store/records/($recordKey)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Encoding": $Content_Encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete last task run's default store's record
#
# DELETE /v2/actor-tasks/{actorTaskId}/runs/last/key-value-store/records/{recordKey}
# operationId: actorTask_runs_last_keyValueStore_record_delete
export def "actor-tasks-runs-last-key-value-store-records delete" [
  actorTaskId: string
  recordKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/key-value-store/records/($recordKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last task run's default request queue
#
# GET /v2/actor-tasks/{actorTaskId}/runs/last/request-queue
# operationId: actorTask_runs_last_requestQueue_get
export def "actor-tasks-runs-last-request-queue get" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> record<data: record<id: string, name: string, userId: string, actId: string, actRunId: string, createdAt: string, modifiedAt: string, accessedAt: string, totalRequestCount: int, handledRequestCount: int, pendingRequestCount: int, hadMultipleClients: bool, consoleUrl: string, stats: record<deleteCount: int, headItemReadCount: int, readCount: int, storageBytes: int, writeCount: int>, generalAccess: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/request-queue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update last task run's default request queue
#
# PUT /v2/actor-tasks/{actorTaskId}/runs/last/request-queue
# operationId: actorTask_runs_last_requestQueue_put
export def "actor-tasks-runs-last-request-queue put" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --name: string # The new name for the request queue. (nullable)
  --generalAccess: string@generalAccess-completer # Defines the general access level for the resource.
]: any -> record<data: record<id: string, name: string, userId: string, actId: string, actRunId: string, createdAt: string, modifiedAt: string, accessedAt: string, totalRequestCount: int, handledRequestCount: int, pendingRequestCount: int, hadMultipleClients: bool, consoleUrl: string, stats: record<deleteCount: int, headItemReadCount: int, readCount: int, storageBytes: int, writeCount: int>, generalAccess: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/request-queue" $qp)
  let body = {name: $name, generalAccess: $generalAccess} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete last task run's default request queue
#
# DELETE /v2/actor-tasks/{actorTaskId}/runs/last/request-queue
# operationId: actorTask_runs_last_requestQueue_delete
export def "actor-tasks-runs-last-request-queue delete" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/request-queue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last task run's default request queue head
#
# GET /v2/actor-tasks/{actorTaskId}/runs/last/request-queue/head
# operationId: actorTask_runs_last_requestQueue_head_get
export def "actor-tasks-runs-last-request-queue-head get" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --limit: float # How many items from queue should be returned. (format: double, e.g. 100)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
]: nothing -> record<data: record<limit: int, queueModifiedAt: string, hadMultipleClients: bool, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/request-queue/head" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get and lock last task run's default request queue head
#
# POST /v2/actor-tasks/{actorTaskId}/runs/last/request-queue/head/lock
# operationId: actorTask_runs_last_requestQueue_head_lock_post
export def "actor-tasks-runs-last-request-queue-head-lock post" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --lockSecs: float # How long the requests will be locked for (in seconds). (format: double, e.g. 60)
  --limit: float # How many items from the queue should be returned. (format: double, e.g. 25)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
]: nothing -> record<data: record<limit: int, queueModifiedAt: string, queueHasLockedRequests: bool, clientKey: string, hadMultipleClients: bool, lockSecs: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "lockSecs" $lockSecs "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/request-queue/head/lock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List last task run's default request queue's requests
#
# GET /v2/actor-tasks/{actorTaskId}/runs/last/request-queue/requests
# operationId: actorTask_runs_last_requestQueue_requests_get
@deprecated --flag exclusiveStartId
export def "actor-tasks-runs-last-request-queue-requests list" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --exclusiveStartId: string # All requests up to this one (including) are skipped from the result. (Deprecated, use `cursor` instead.) (DEPRECATED, e.g. Ihnsp8YrvJ8102Kj)
  --limit: float # Number of keys to be returned. Maximum value is `10000`. (format: double, e.g. 100)
  --cursor: string # A cursor string for pagination, returned in the previous response as `nextCursor`. Use this to retrieve the next page of requests. (e.g. eyJyZXF1ZXN0SWQiOiI2OFRqQ2RaTDNvM2hiUU0ifQ)
  --filter: list # Filter requests by their state. Possible values are `locked` and `pending`. You can combine multiple values separated by commas, which will mean the union of these filters – requests matching any of the specified states will be returned. (Not compatible with deprecated `exclusiveStartId` parameter.) (e.g. [locked])
]: nothing -> record<data: record<items: list<record>, limit: int, exclusiveStartId: string, cursor: string, nextCursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "exclusiveStartId" $exclusiveStartId "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "filter" $filter "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/request-queue/requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add request to last task run's default request queue
#
# POST /v2/actor-tasks/{actorTaskId}/runs/last/request-queue/requests
# operationId: actorTask_runs_last_requestQueue_requests_post
export def "actor-tasks-runs-last-request-queue-requests post" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --forefront: string # Determines if request should be added to the head of the queue or to the end. Default value is `false` (end of queue).  (e.g. false)
  --uniqueKey: string # A unique key used for request de-duplication. Requests with the same unique key are considered identical.
  --body-url: string # The URL of the request.
  --method: string@method-completer
  --retryCount: int # The number of times this request has been retried.
  --loadedUrl: string # The final URL that was loaded, after redirects (if any). (nullable)
  --payload: string # The request payload, typically used with POST or PUT requests. (nullable)
  --headers: record # HTTP headers sent with the request. (nullable)
  --userData: record # Custom user data attached to the request. Can contain arbitrary fields. (e.g. {label: DETAIL, customField: custom-value})
  --noRetry: oneof<nothing, bool> # Indicates whether the request should not be retried if processing fails. (nullable)
  --errorMessages: list # Error messages recorded from failed processing attempts. (nullable)
  --handledAt: string # The timestamp when the request was marked as handled, if applicable. (nullable, format: date-time)
]: any -> record<data: record<requestId: string, wasAlreadyPresent: bool, wasAlreadyHandled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "forefront" $forefront "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/request-queue/requests" $qp)
  let body = {uniqueKey: $uniqueKey, url: $body_url, method: $method, retryCount: $retryCount, loadedUrl: $loadedUrl, payload: $payload, headers: $headers, userData: $userData, noRetry: $noRetry, errorMessages: $errorMessages, handledAt: $handledAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Batch add requests to last task run's default request queue
#
# POST /v2/actor-tasks/{actorTaskId}/runs/last/request-queue/requests/batch
# operationId: actorTask_runs_last_requestQueue_requests_batch_post
export def "actor-tasks-runs-last-request-queue-requests-batch post" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --forefront: string # Determines if request should be added to the head of the queue or to the end. Default value is `false` (end of queue).  (e.g. false)
  --body: record
]: any -> record<data: record<processedRequests: list<record>, unprocessedRequests: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "forefront" $forefront "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/request-queue/requests/batch" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Batch delete requests from last task run's default request queue
#
# DELETE /v2/actor-tasks/{actorTaskId}/runs/last/request-queue/requests/batch
# operationId: actorTask_runs_last_requestQueue_requests_batch_delete
export def "actor-tasks-runs-last-request-queue-requests-batch delete" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --Content-Type: string
  --body: record
]: any -> record<data: record<processedRequests: list<any>, unprocessedRequests: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/request-queue/requests/batch" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unlock requests in last task run's default request queue
#
# POST /v2/actor-tasks/{actorTaskId}/runs/last/request-queue/requests/unlock
# operationId: actorTask_runs_last_requestQueue_requests_unlock_post
export def "actor-tasks-runs-last-request-queue-requests-unlock post" [
  actorTaskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
]: nothing -> record<data: record<unlockedCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/request-queue/requests/unlock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get request from last task run's default request queue
#
# GET /v2/actor-tasks/{actorTaskId}/runs/last/request-queue/requests/{requestId}
# operationId: actorTask_runs_last_requestQueue_request_get
export def "actor-tasks-runs-last-request-queue-requests get" [
  actorTaskId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
]: nothing -> record<data: record<uniqueKey: string, url: string, method: string, retryCount: int, loadedUrl: string, payload: string, headers: record, userData: record, noRetry: bool, errorMessages: list<string>, handledAt: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/request-queue/requests/($requestId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update request in last task run's default request queue
#
# PUT /v2/actor-tasks/{actorTaskId}/runs/last/request-queue/requests/{requestId}
# operationId: actorTask_runs_last_requestQueue_request_put
export def "actor-tasks-runs-last-request-queue-requests put" [
  actorTaskId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --forefront: string # Determines if request should be added to the head of the queue or to the end. Default value is `false` (end of queue).  (e.g. false)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --uniqueKey: string # A unique key used for request de-duplication. Requests with the same unique key are considered identical.
  --body-url: string # The URL of the request.
  --method: string@method-completer
  --retryCount: int # The number of times this request has been retried.
  --loadedUrl: string # The final URL that was loaded, after redirects (if any). (nullable)
  --payload: string # The request payload, typically used with POST or PUT requests. (nullable)
  --headers: record # HTTP headers sent with the request. (nullable)
  --userData: record # Custom user data attached to the request. Can contain arbitrary fields. (e.g. {label: DETAIL, customField: custom-value})
  --noRetry: oneof<nothing, bool> # Indicates whether the request should not be retried if processing fails. (nullable)
  --errorMessages: list # Error messages recorded from failed processing attempts. (nullable)
  --handledAt: string # The timestamp when the request was marked as handled, if applicable. (nullable, format: date-time)
  --id: string # A unique identifier assigned to the request.
]: any -> record<data: record<requestId: string, wasAlreadyPresent: bool, wasAlreadyHandled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "forefront" $forefront "scalar") (serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/request-queue/requests/($requestId)" $qp)
  let body = {uniqueKey: $uniqueKey, url: $body_url, method: $method, retryCount: $retryCount, loadedUrl: $loadedUrl, payload: $payload, headers: $headers, userData: $userData, noRetry: $noRetry, errorMessages: $errorMessages, handledAt: $handledAt, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete request from last task run's default request queue
#
# DELETE /v2/actor-tasks/{actorTaskId}/runs/last/request-queue/requests/{requestId}
# operationId: actorTask_runs_last_requestQueue_request_delete
export def "actor-tasks-runs-last-request-queue-requests delete" [
  actorTaskId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/request-queue/requests/($requestId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Prolong lock on request in last task run's default request queue
#
# PUT /v2/actor-tasks/{actorTaskId}/runs/last/request-queue/requests/{requestId}/lock
# operationId: actorTask_runs_last_requestQueue_request_lock_put
export def "actor-tasks-runs-last-request-queue-requests-lock put" [
  actorTaskId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --lockSecs: float # How long the requests will be locked for (in seconds). (format: double, e.g. 60)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --forefront: string # Determines if request should be added to the head of the queue or to the end after lock expires.  (e.g. false)
]: nothing -> record<data: record<lockExpiresAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "lockSecs" $lockSecs "scalar") (serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "forefront" $forefront "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/request-queue/requests/($requestId)/lock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete lock on request in last task run's default request queue
#
# DELETE /v2/actor-tasks/{actorTaskId}/runs/last/request-queue/requests/{requestId}/lock
# operationId: actorTask_runs_last_requestQueue_request_lock_delete
export def "actor-tasks-runs-last-request-queue-requests-lock delete" [
  actorTaskId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Filter for the run status. (e.g. SUCCEEDED)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --forefront: string # Determines if request should be added to the head of the queue or to the end after lock was removed.  (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "forefront" $forefront "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-tasks/($actorTaskId)/runs/last/request-queue/requests/($requestId)/lock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user runs list
#
# GET /v2/actor-runs
# operationId: actorRuns_get
export def "actor-runs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. The default value as well as the maximum is `1000`.  (format: double, e.g. 1000)
  --desc: oneof<nothing, bool> # If `true` or `1` then the objects are sorted by the `startedAt` field in descending order. By default, they are sorted in ascending order.  (e.g. true)
  --status: list # Single status or comma-separated list of statuses, see ([available statuses](https://docs.apify.com/platform/actors/running/runs-and-builds#lifecycle)). Used to filter runs by the specified statuses only.  (e.g. [SUCCEEDED])
  --startedAfter: string # Filter runs that started after the specified date and time (inclusive). The value must be a valid ISO 8601 datetime string (UTC).  (format: date-time, e.g. 2025-09-01T00:00:00.000Z)
  --startedBefore: string # Filter runs that started before the specified date and time (inclusive). The value must be a valid ISO 8601 datetime string (UTC).  (format: date-time, e.g. 2025-09-17T23:59:59.000Z)
]: nothing -> record<data: record<total: int, offset: int, limit: int, desc: bool, count: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "status" $status "csv") (serialize-qp "startedAfter" $startedAfter "scalar") (serialize-qp "startedBefore" $startedBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/actor-runs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get run
#
# GET /v2/actor-runs/{runId}
# operationId: actorRun_get
export def "actor-runs get" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --waitForFinish: float # The maximum number of seconds the server waits for the run to finish. By default it is `0`, the maximum value is `60`. <!-- MAX_ACTOR_JOB_ASYNC_WAIT_SECS --> If the run finishes in time then the returned run object will have a terminal status (e.g. `SUCCEEDED`), otherwise it will have a transitional status (e.g. `RUNNING`).  (format: double, e.g. 60)
]: nothing -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "waitForFinish" $waitForFinish "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update run
#
# PUT /v2/actor-runs/{runId}
# operationId: actorRun_put
export def "actor-runs put" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-runId: string
  --statusMessage: string
  --isStatusMessageTerminal: oneof<nothing, bool>
  --generalAccess: string@generalAccess-completer # Defines the general access level for the resource.
]: any -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actor-runs/($runId)")
  let body = {runId: $body_runId, statusMessage: $statusMessage, isStatusMessageTerminal: $isStatusMessageTerminal, generalAccess: $generalAccess} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete run
#
# DELETE /v2/actor-runs/{runId}
# operationId: actorRun_delete
export def "actor-runs delete" [
  runId: string
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
  let full_url = (build-url $base $"/v2/actor-runs/($runId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abort run
#
# POST /v2/actor-runs/{runId}/abort
# operationId: actorRun_abort_post
export def "actor-runs-abort post" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --gracefully: oneof<nothing, bool> # If true passed, the Actor run will abort gracefully. It will send `aborting` and `persistState` event into run and force-stop the run after 30 seconds. It is helpful in cases where you plan to resurrect the run later.  (e.g. true)
]: nothing -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gracefully" $gracefully "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/abort" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Metamorph run
#
# POST /v2/actor-runs/{runId}/metamorph
# operationId: actorRun_metamorph_post
export def "actor-runs-metamorph post" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --targetActorId: string # ID of a target Actor that the run should be transformed into. (e.g. HDSasDasz78YcAPEB)
  --build: string # Optional build of the target Actor.  It can be either a build tag or build number. By default, the run uses the build specified in the default run configuration for the target Actor (typically `latest`).  (e.g. beta)
]: nothing -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "targetActorId" $targetActorId "scalar") (serialize-qp "build" $build "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/metamorph" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reboot run
#
# POST /v2/actor-runs/{runId}/reboot
# operationId: actorRun_reboot_post
export def "actor-runs-reboot post" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/reboot")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resurrect run
#
# POST /v2/actor-runs/{runId}/resurrect
# operationId: PostResurrectRun
export def "actor-runs-resurrect PostResurrectRun" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --build: string # Specifies the Actor build to run. It can be either a build tag or build number. By default, the run is resurrected with the same build it originally used. Specifically, if a run was first started with the `latest` tag, which resolves to version `0.0.3` at the time, a run resurrected without this parameter will continue running with `0.0.3`, even if `latest` already points to a newer build.  (e.g. 0.1.234)
  --timeout: float # Optional timeout for the run, in seconds. By default, the run uses the timeout specified in the run that is being resurrected.  (format: double, e.g. 60)
  --memory: float # Memory limit for the run, in megabytes. The amount of memory can be set to a power of 2 with a minimum of 128. By default, the run uses the memory limit specified in the run that is being resurrected.  (format: double, e.g. 256)
  --maxItems: float # Specifies the maximum number of dataset items that will be charged for pay-per-result Actors. This does NOT guarantee that the Actor will return only this many items. It only ensures you won't be charged for more than this number of items. Only works for pay-per-result Actors. Value can be accessed in the actor run using `ACTOR_MAX_PAID_DATASET_ITEMS` environment variable.  (format: double, e.g. 1000)
  --maxTotalChargeUsd: float # Specifies the maximum cost of the run. This parameter is useful for pay-per-event Actors, as it allows you to limit the amount charged to your subscription. You can access the maximum cost in your Actor by using the `ACTOR_MAX_TOTAL_CHARGE_USD` environment variable.  (format: double, e.g. 5)
  --restartOnError: oneof<nothing, bool> # Determines whether the resurrected run will be restarted if it fails. By default, the resurrected run uses the same setting as before.  (e.g. false)
]: nothing -> record<data: record<id: string, actId: string, userId: string, actorTaskId: string, startedAt: string, finishedAt: string, status: string, statusMessage: string, isStatusMessageTerminal: bool, meta: record<origin: string, clientIp: string, userAgent: string, scheduleId: string, scheduledAt: string>, pricingInfo: any, stats: record<inputBodyLen: int, migrationCount: int, rebootCount: int, restartCount: int, resurrectCount: int, memAvgBytes: float, memMaxBytes: int, memCurrentBytes: int, cpuAvgUsage: float, cpuMaxUsage: float, cpuCurrentUsage: float, netRxBytes: int, netTxBytes: int, durationMillis: int, runTimeSecs: float, metamorph: int, computeUnits: float>, chargedEventCounts: record, options: record<build: string, timeoutSecs: int, memoryMbytes: int, diskMbytes: int, maxItems: int, maxTotalChargeUsd: float>, buildId: string, exitCode: int, generalAccess: string, defaultKeyValueStoreId: string, defaultDatasetId: string, defaultRequestQueueId: string, storageIds: record<datasets: record, keyValueStores: record, requestQueues: record>, buildNumber: string, containerUrl: string, isContainerServerReady: bool, gitBranchName: string, usage: any, usageTotalUsd: float, usageUsd: any, metamorphs: any, platformUsageBillingModel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "build" $build "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "memory" $memory "scalar") (serialize-qp "maxItems" $maxItems "scalar") (serialize-qp "maxTotalChargeUsd" $maxTotalChargeUsd "scalar") (serialize-qp "restartOnError" $restartOnError "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/resurrect" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Charge events in run
#
# POST /v2/actor-runs/{runId}/charge
# operationId: PostChargeRun
export def "actor-runs-charge PostChargeRun" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # Always pass a unique idempotency key (any unique string) for each charge to avoid double charging in case of retries or network errors. (e.g. 2024-12-09T01:23:45.000Z-random-uuid)
  eventName: string
  count: int
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/charge")
  let body = {eventName: $eventName, count: $count} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get default dataset
#
# GET /v2/actor-runs/{runId}/dataset
# operationId: actorRun_dataset_get
export def "actor-runs-dataset get" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, name: string, userId: string, createdAt: string, modifiedAt: string, accessedAt: string, itemCount: int, cleanItemCount: int, actId: string, actRunId: string, fields: list<string>, schema: record, consoleUrl: string, itemsPublicUrl: string, urlSigningSecretKey: string, generalAccess: string, stats: record<readCount: int, writeCount: int, storageBytes: int, inflatedBytes: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/dataset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update default dataset
#
# PUT /v2/actor-runs/{runId}/dataset
# operationId: actorRun_dataset_put
export def "actor-runs-dataset put" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # nullable
  --generalAccess: string@generalAccess-completer # Defines the general access level for the resource.
]: any -> record<data: record<id: string, name: string, userId: string, createdAt: string, modifiedAt: string, accessedAt: string, itemCount: int, cleanItemCount: int, actId: string, actRunId: string, fields: list<string>, schema: record, consoleUrl: string, itemsPublicUrl: string, urlSigningSecretKey: string, generalAccess: string, stats: record<readCount: int, writeCount: int, storageBytes: int, inflatedBytes: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/dataset")
  let body = {name: $name, generalAccess: $generalAccess} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete default dataset
#
# DELETE /v2/actor-runs/{runId}/dataset
# operationId: actorRun_dataset_delete
export def "actor-runs-dataset delete" [
  runId: string
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
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/dataset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get default dataset items
#
# GET /v2/actor-runs/{runId}/dataset/items
# operationId: actorRun_dataset_items_get
export def "actor-runs-dataset-items get" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string # Format of the results, possible values are: `json`, `jsonl`, `csv`, `html`, `xlsx`, `xml` and `rss`. The default value is `json`.  (e.g. json)
  --clean: oneof<nothing, bool> # If `true` or `1` then the API endpoint returns only non-empty items and skips hidden fields (i.e. fields starting with the # character). The `clean` parameter is just a shortcut for `skipHidden=true` and `skipEmpty=true` parameters. Note that since some objects might be skipped from the output, that the result might contain less items than the `limit` value.  (e.g. false)
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. By default there is no limit. (format: double)
  --qp-fields: string # A comma-separated list of fields which should be picked from the items, only these fields will remain in the resulting record objects. Note that the fields in the outputted items are sorted the same way as they are specified in the `fields` query parameter. You can use this feature to effectively fix the output format.  (e.g. myValue,myOtherValue)
  --outputFields: string # A comma-separated list of output field names that positionally rename the fields specified in the `fields` parameter. For example, `?fields=headline,url&outputFields=title,link` renames `headline` to `title` and `url` to `link` in the output. The number of names in `outputFields` must match the number of names in `fields`. Requires the `fields` parameter to be specified as well.  (e.g. title,link)
  --omit: string # A comma-separated list of fields which should be omitted from the items. (e.g. myValue,myOtherValue)
  --unwind: string # A comma-separated list of fields which should be unwound, in order which they should be processed. Each field should be either an array or an object. If the field is an array then every element of the array will become a separate record and merged with parent object. If the unwound field is an object then it is merged with the parent object. If the unwound field is missing or its value is neither an array nor an object and therefore cannot be merged with a parent object then the item gets preserved as it is. Note that the unwound items ignore the `desc` parameter.  (e.g. myValue,myOtherValue)
  --flatten: string # A comma-separated list of fields which should transform nested objects into flat structures.  For example, with `flatten="foo"` the object `{"foo":{"bar": "hello"}}` is turned into `{"foo.bar": "hello"}`.  The original object with properties is replaced with the flattened object.  (e.g. myValue)
  --desc: oneof<nothing, bool> # By default, results are returned in the same order as they were stored. To reverse the order, set this parameter to `true` or `1`.  (e.g. true)
  --attachment: oneof<nothing, bool> # If `true` or `1` then the response will define the `Content-Disposition: attachment` header, forcing a web browser to download the file rather than to display it. By default this header is not present.  (e.g. true)
  --delimiter: string # A delimiter character for CSV files, only used if `format=csv`. You might need to URL-encode the character (e.g. use `%09` for tab or `%3B` for semicolon). The default delimiter is a simple comma (`,`).  (e.g. ;)
  --bom: oneof<nothing, bool> # All text responses are encoded in UTF-8 encoding. By default, the `format=csv` files are prefixed with the UTF-8 Byte Order Mark (BOM), while `json`, `jsonl`, `xml`, `html` and `rss` files are not.  If you want to override this default behavior, specify `bom=1` query parameter to include the BOM or `bom=0` to skip it.  (e.g. false)
  --xmlRoot: string # Overrides default root element name of `xml` output. By default the root element is `items`.  (e.g. items)
  --xmlRow: string # Overrides default element name that wraps each page or page function result object in `xml` output. By default the element name is `item`.  (e.g. item)
  --skipHeaderRow: oneof<nothing, bool> # If `true` or `1` then header row in the `csv` format is skipped. (e.g. true)
  --skipHidden: oneof<nothing, bool> # If `true` or `1` then hidden fields are skipped from the output, i.e. fields starting with the `#` character.  (e.g. false)
  --skipEmpty: oneof<nothing, bool> # If `true` or `1` then empty items are skipped from the output.  Note that if used, the results might contain less items than the limit value.  (e.g. false)
  --simplified: oneof<nothing, bool> # If `true` or `1` then, the endpoint applies the `fields=url,pageFunctionResult,errorInfo` and `unwind=pageFunctionResult` query parameters. This feature is used to emulate simplified results provided by the legacy Apify Crawler product and it's not recommended to use it in new integrations.  (e.g. false)
  --view: string # Defines the view configuration for dataset items based on the schema definition. This parameter determines how the data will be filtered and presented. For complete specification details, see the [dataset schema documentation](/platform/actors/development/actor-definition/dataset-schema).  (e.g. overview)
  --skipFailedPages: oneof<nothing, bool> # If `true` or `1` then, the all the items with errorInfo property will be skipped from the output.  This feature is here to emulate functionality of API version 1 used for the legacy Apify Crawler product and it's not recommended to use it in new integrations.  (e.g. false)
  --feedTitle: string # Overrides the auto-generated RSS channel `<title>` element. Only used when `format=rss`. If not provided, the title defaults to `Dataset <label>`.  (e.g. Latest posts from r/pasta)
  --feedDescription: string # Overrides the auto-generated RSS channel `<description>` element. Only used when `format=rss`. If not provided, the description defaults to `Items in dataset with id "<datasetId>".`  (e.g. Scraped forum posts)
  --signature: string # Signature used for the access. (e.g. 2wTI46Bg8qWQrV7tavlPI)
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "clean" $clean "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "outputFields" $outputFields "scalar") (serialize-qp "omit" $omit "scalar") (serialize-qp "unwind" $unwind "scalar") (serialize-qp "flatten" $flatten "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "attachment" $attachment "scalar") (serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "bom" $bom "scalar") (serialize-qp "xmlRoot" $xmlRoot "scalar") (serialize-qp "xmlRow" $xmlRow "scalar") (serialize-qp "skipHeaderRow" $skipHeaderRow "scalar") (serialize-qp "skipHidden" $skipHidden "scalar") (serialize-qp "skipEmpty" $skipEmpty "scalar") (serialize-qp "simplified" $simplified "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "skipFailedPages" $skipFailedPages "scalar") (serialize-qp "feedTitle" $feedTitle "scalar") (serialize-qp "feedDescription" $feedDescription "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/dataset/items" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Store items
#
# POST /v2/actor-runs/{runId}/dataset/items
# operationId: actorRun_dataset_items_post
export def "actor-runs-dataset-items post" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/dataset/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get default dataset statistics
#
# GET /v2/actor-runs/{runId}/dataset/statistics
# operationId: actorRun_dataset_statistics_get
export def "actor-runs-dataset-statistics get" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<fieldStatistics: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/dataset/statistics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get default store
#
# GET /v2/actor-runs/{runId}/key-value-store
# operationId: actorRun_keyValueStore_get
export def "actor-runs-key-value-store get" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, name: string, userId: string, username: string, createdAt: string, modifiedAt: string, accessedAt: string, actId: string, actRunId: string, consoleUrl: string, keysPublicUrl: string, recordsPublicUrl: string, schema: record, urlSigningSecretKey: string, generalAccess: string, stats: record<readCount: int, writeCount: int, deleteCount: int, listCount: int, s3StorageBytes: int, storageBytes: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/key-value-store")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update default store
#
# PUT /v2/actor-runs/{runId}/key-value-store
# operationId: actorRun_keyValueStore_put
export def "actor-runs-key-value-store put" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # nullable
  --generalAccess: string@generalAccess-completer # Defines the general access level for the resource.
]: any -> record<data: record<id: string, name: string, userId: string, username: string, createdAt: string, modifiedAt: string, accessedAt: string, actId: string, actRunId: string, consoleUrl: string, keysPublicUrl: string, recordsPublicUrl: string, schema: record, urlSigningSecretKey: string, generalAccess: string, stats: record<readCount: int, writeCount: int, deleteCount: int, listCount: int, s3StorageBytes: int, storageBytes: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/key-value-store")
  let body = {name: $name, generalAccess: $generalAccess} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete default store
#
# DELETE /v2/actor-runs/{runId}/key-value-store
# operationId: actorRun_keyValueStore_delete
export def "actor-runs-key-value-store delete" [
  runId: string
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
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/key-value-store")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get default store's list of keys
#
# GET /v2/actor-runs/{runId}/key-value-store/keys
# operationId: actorRun_keyValueStore_keys_get
export def "actor-runs-key-value-store-keys get" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --exclusiveStartKey: string # All keys up to this one (including) are skipped from the result. (e.g. Ihnsp8YrvJ8102Kj)
  --limit: float # Number of keys to be returned. (format: int32, default: 1000, e.g. 100)
  --collection: string # Limit the results to keys that belong to a specific collection from the key-value store schema. The key-value store need to have a schema defined for this parameter to work. (e.g. postImages)
  --prefix: string # Limit the results to keys that start with a specific prefix. (e.g. post-images-)
  --signature: string # Signature used for the access. (e.g. 2wTI46Bg8qWQrV7tavlPI)
]: nothing -> record<data: record<items: list<record>, count: int, limit: int, exclusiveStartKey: string, isTruncated: bool, nextExclusiveStartKey: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exclusiveStartKey" $exclusiveStartKey "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "collection" $collection "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/key-value-store/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download default store's records
#
# GET /v2/actor-runs/{runId}/key-value-store/records
# operationId: actorRun_keyValueStore_records_get
export def "actor-runs-key-value-store-records list" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --collection: string # If specified, only records belonging to a specific collection from the key-value store schema. The key-value store need to have a schema defined for this parameter to work.  (e.g. my-collection)
  --prefix: string # If specified, only records whose key starts with the given prefix are included in the archive.  (e.g. my-prefix/)
  --signature: string # Signature used for the access. (e.g. 2wTI46Bg8qWQrV7tavlPI)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "collection" $collection "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/key-value-store/records" $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get default store's record
#
# GET /v2/actor-runs/{runId}/key-value-store/records/{recordKey}
# operationId: actorRun_keyValueStore_record_get
export def "actor-runs-key-value-store-records get" [
  runId: string
  recordKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --signature: string # Signature used for the access. (e.g. 2wTI46Bg8qWQrV7tavlPI)
  --attachment: oneof<nothing, bool> # If `true` or `1`, the response will be served with `Content-Disposition: attachment` header, causing web browsers to offer downloading HTML records instead of displaying them.  (e.g. true)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "signature" $signature "scalar") (serialize-qp "attachment" $attachment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/key-value-store/records/($recordKey)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Store record in default store
#
# PUT /v2/actor-runs/{runId}/key-value-store/records/{recordKey}
# operationId: actorRun_keyValueStore_record_put
export def "actor-runs-key-value-store-records put" [
  runId: string
  recordKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Encoding: string@Content-Encoding-completer
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/key-value-store/records/($recordKey)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Encoding": $Content_Encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Store record in default store (POST)
#
# POST /v2/actor-runs/{runId}/key-value-store/records/{recordKey}
# operationId: actorRun_keyValueStore_record_post
export def "actor-runs-key-value-store-records post" [
  runId: string
  recordKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Encoding: string@Content-Encoding-completer
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/key-value-store/records/($recordKey)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Encoding": $Content_Encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete default store's record
#
# DELETE /v2/actor-runs/{runId}/key-value-store/records/{recordKey}
# operationId: actorRun_keyValueStore_record_delete
export def "actor-runs-key-value-store-records delete" [
  runId: string
  recordKey: string
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
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/key-value-store/records/($recordKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get default request queue
#
# GET /v2/actor-runs/{runId}/request-queue
# operationId: actorRun_requestQueue_get
export def "actor-runs-request-queue get" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, name: string, userId: string, actId: string, actRunId: string, createdAt: string, modifiedAt: string, accessedAt: string, totalRequestCount: int, handledRequestCount: int, pendingRequestCount: int, hadMultipleClients: bool, consoleUrl: string, stats: record<deleteCount: int, headItemReadCount: int, readCount: int, storageBytes: int, writeCount: int>, generalAccess: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/request-queue")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update default request queue
#
# PUT /v2/actor-runs/{runId}/request-queue
# operationId: actorRun_requestQueue_put
export def "actor-runs-request-queue put" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name for the request queue. (nullable)
  --generalAccess: string@generalAccess-completer # Defines the general access level for the resource.
]: any -> record<data: record<id: string, name: string, userId: string, actId: string, actRunId: string, createdAt: string, modifiedAt: string, accessedAt: string, totalRequestCount: int, handledRequestCount: int, pendingRequestCount: int, hadMultipleClients: bool, consoleUrl: string, stats: record<deleteCount: int, headItemReadCount: int, readCount: int, storageBytes: int, writeCount: int>, generalAccess: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/request-queue")
  let body = {name: $name, generalAccess: $generalAccess} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete default request queue
#
# DELETE /v2/actor-runs/{runId}/request-queue
# operationId: actorRun_requestQueue_delete
export def "actor-runs-request-queue delete" [
  runId: string
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
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/request-queue")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List default request queue's requests
#
# GET /v2/actor-runs/{runId}/request-queue/requests
# operationId: actorRun_requestQueue_requests_get
@deprecated --flag exclusiveStartId
export def "actor-runs-request-queue-requests list" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --exclusiveStartId: string # All requests up to this one (including) are skipped from the result. (Deprecated, use `cursor` instead.) (DEPRECATED, e.g. Ihnsp8YrvJ8102Kj)
  --limit: float # Number of keys to be returned. Maximum value is `10000`. (format: double, e.g. 100)
  --cursor: string # A cursor string for pagination, returned in the previous response as `nextCursor`. Use this to retrieve the next page of requests. (e.g. eyJyZXF1ZXN0SWQiOiI2OFRqQ2RaTDNvM2hiUU0ifQ)
  --filter: list # Filter requests by their state. Possible values are `locked` and `pending`. You can combine multiple values separated by commas, which will mean the union of these filters – requests matching any of the specified states will be returned. (Not compatible with deprecated `exclusiveStartId` parameter.) (e.g. [locked])
]: nothing -> record<data: record<items: list<record>, limit: int, exclusiveStartId: string, cursor: string, nextCursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "exclusiveStartId" $exclusiveStartId "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "filter" $filter "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/request-queue/requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add request to default request queue
#
# POST /v2/actor-runs/{runId}/request-queue/requests
# operationId: actorRun_requestQueue_requests_post
export def "actor-runs-request-queue-requests post" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --forefront: string # Determines if request should be added to the head of the queue or to the end. Default value is `false` (end of queue).  (e.g. false)
  --uniqueKey: string # A unique key used for request de-duplication. Requests with the same unique key are considered identical.
  --body-url: string # The URL of the request.
  --method: string@method-completer
  --retryCount: int # The number of times this request has been retried.
  --loadedUrl: string # The final URL that was loaded, after redirects (if any). (nullable)
  --payload: string # The request payload, typically used with POST or PUT requests. (nullable)
  --headers: record # HTTP headers sent with the request. (nullable)
  --userData: record # Custom user data attached to the request. Can contain arbitrary fields. (e.g. {label: DETAIL, customField: custom-value})
  --noRetry: oneof<nothing, bool> # Indicates whether the request should not be retried if processing fails. (nullable)
  --errorMessages: list # Error messages recorded from failed processing attempts. (nullable)
  --handledAt: string # The timestamp when the request was marked as handled, if applicable. (nullable, format: date-time)
]: any -> record<data: record<requestId: string, wasAlreadyPresent: bool, wasAlreadyHandled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "forefront" $forefront "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/request-queue/requests" $qp)
  let body = {uniqueKey: $uniqueKey, url: $body_url, method: $method, retryCount: $retryCount, loadedUrl: $loadedUrl, payload: $payload, headers: $headers, userData: $userData, noRetry: $noRetry, errorMessages: $errorMessages, handledAt: $handledAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Batch add requests to default request queue
#
# POST /v2/actor-runs/{runId}/request-queue/requests/batch
# operationId: actorRun_requestQueue_requests_batch_post
export def "actor-runs-request-queue-requests-batch post" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --forefront: string # Determines if request should be added to the head of the queue or to the end. Default value is `false` (end of queue).  (e.g. false)
  --body: record
]: any -> record<data: record<processedRequests: list<record>, unprocessedRequests: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "forefront" $forefront "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/request-queue/requests/batch" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Batch delete requests from default request queue
#
# DELETE /v2/actor-runs/{runId}/request-queue/requests/batch
# operationId: actorRun_requestQueue_requests_batch_delete
export def "actor-runs-request-queue-requests-batch delete" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --Content-Type: string
  --body: record
]: any -> record<data: record<processedRequests: list<any>, unprocessedRequests: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/request-queue/requests/batch" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unlock requests in default request queue
#
# POST /v2/actor-runs/{runId}/request-queue/requests/unlock
# operationId: actorRun_requestQueue_requests_unlock_post
export def "actor-runs-request-queue-requests-unlock post" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
]: nothing -> record<data: record<unlockedCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/request-queue/requests/unlock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get request from default request queue
#
# GET /v2/actor-runs/{runId}/request-queue/requests/{requestId}
# operationId: actorRun_requestQueue_request_get
export def "actor-runs-request-queue-requests get" [
  runId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<uniqueKey: string, url: string, method: string, retryCount: int, loadedUrl: string, payload: string, headers: record, userData: record, noRetry: bool, errorMessages: list<string>, handledAt: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/request-queue/requests/($requestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update request in default request queue
#
# PUT /v2/actor-runs/{runId}/request-queue/requests/{requestId}
# operationId: actorRun_requestQueue_request_put
export def "actor-runs-request-queue-requests put" [
  runId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forefront: string # Determines if request should be added to the head of the queue or to the end. Default value is `false` (end of queue).  (e.g. false)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --uniqueKey: string # A unique key used for request de-duplication. Requests with the same unique key are considered identical.
  --body-url: string # The URL of the request.
  --method: string@method-completer
  --retryCount: int # The number of times this request has been retried.
  --loadedUrl: string # The final URL that was loaded, after redirects (if any). (nullable)
  --payload: string # The request payload, typically used with POST or PUT requests. (nullable)
  --headers: record # HTTP headers sent with the request. (nullable)
  --userData: record # Custom user data attached to the request. Can contain arbitrary fields. (e.g. {label: DETAIL, customField: custom-value})
  --noRetry: oneof<nothing, bool> # Indicates whether the request should not be retried if processing fails. (nullable)
  --errorMessages: list # Error messages recorded from failed processing attempts. (nullable)
  --handledAt: string # The timestamp when the request was marked as handled, if applicable. (nullable, format: date-time)
  --id: string # A unique identifier assigned to the request.
]: any -> record<data: record<requestId: string, wasAlreadyPresent: bool, wasAlreadyHandled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forefront" $forefront "scalar") (serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/request-queue/requests/($requestId)" $qp)
  let body = {uniqueKey: $uniqueKey, url: $body_url, method: $method, retryCount: $retryCount, loadedUrl: $loadedUrl, payload: $payload, headers: $headers, userData: $userData, noRetry: $noRetry, errorMessages: $errorMessages, handledAt: $handledAt, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete request from default request queue
#
# DELETE /v2/actor-runs/{runId}/request-queue/requests/{requestId}
# operationId: actorRun_requestQueue_request_delete
export def "actor-runs-request-queue-requests delete" [
  runId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/request-queue/requests/($requestId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Prolong lock on request in default request queue
#
# PUT /v2/actor-runs/{runId}/request-queue/requests/{requestId}/lock
# operationId: actorRun_requestQueue_request_lock_put
export def "actor-runs-request-queue-requests-lock put" [
  runId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lockSecs: float # How long the requests will be locked for (in seconds). (format: double, e.g. 60)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --forefront: string # Determines if request should be added to the head of the queue or to the end after lock expires.  (e.g. false)
]: nothing -> record<data: record<lockExpiresAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lockSecs" $lockSecs "scalar") (serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "forefront" $forefront "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/request-queue/requests/($requestId)/lock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete lock on request in default request queue
#
# DELETE /v2/actor-runs/{runId}/request-queue/requests/{requestId}/lock
# operationId: actorRun_requestQueue_request_lock_delete
export def "actor-runs-request-queue-requests-lock delete" [
  runId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --forefront: string # Determines if request should be added to the head of the queue or to the end after lock was removed.  (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "forefront" $forefront "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/request-queue/requests/($requestId)/lock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get default request queue head
#
# GET /v2/actor-runs/{runId}/request-queue/head
# operationId: actorRun_requestQueue_head_get
export def "actor-runs-request-queue-head get" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # How many items from queue should be returned. (format: double, e.g. 100)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
]: nothing -> record<data: record<limit: int, queueModifiedAt: string, hadMultipleClients: bool, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/request-queue/head" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get and lock default request queue head
#
# POST /v2/actor-runs/{runId}/request-queue/head/lock
# operationId: actorRun_requestQueue_head_lock_post
export def "actor-runs-request-queue-head-lock post" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lockSecs: float # How long the requests will be locked for (in seconds). (format: double, e.g. 60)
  --limit: float # How many items from the queue should be returned. (format: double, e.g. 25)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
]: nothing -> record<data: record<limit: int, queueModifiedAt: string, queueHasLockedRequests: bool, clientKey: string, hadMultipleClients: bool, lockSecs: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lockSecs" $lockSecs "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/request-queue/head/lock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get run's log
#
# GET /v2/actor-runs/{runId}/log
# operationId: actorRun_log_get
export def "actor-runs-log get" [
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stream: oneof<nothing, bool> # If `true` or `1` then the logs will be streamed as long as the run or build is running.  (e.g. false)
  --download: oneof<nothing, bool> # If `true` or `1` then the web browser will download the log file rather than open it in a tab.  (e.g. false)
  --qp-raw: oneof<nothing, bool> # If `true` or `1`, the logs will be kept verbatim. By default, the API removes ANSI escape codes from the logs, keeping only printable characters.  (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stream" $stream "scalar") (serialize-qp "download" $download "scalar") (serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-runs/($runId)/log" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user builds list
#
# GET /v2/actor-builds
# operationId: actorBuilds_get
export def "actor-builds list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. The default value as well as the maximum is `1000`.  (format: double, e.g. 1000)
  --desc: oneof<nothing, bool> # If `true` or `1` then the objects are sorted by the `startedAt` field in descending order. By default, they are sorted in ascending order.  (e.g. true)
]: nothing -> record<data: record<total: int, offset: int, limit: int, desc: bool, count: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "desc" $desc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/actor-builds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get build
#
# GET /v2/actor-builds/{buildId}
# operationId: actorBuild_get
export def "actor-builds get" [
  buildId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --waitForFinish: float # The maximum number of seconds the server waits for the build to finish. By default it is `0`, the maximum value is `60`. <!-- MAX_ACTOR_JOB_ASYNC_WAIT_SECS --> If the build finishes in time then the returned build object will have a terminal status (e.g. `SUCCEEDED`), otherwise it will have a transitional status (e.g. `RUNNING`).  (format: double, e.g. 60)
]: nothing -> record<data: record<id: string, actId: string, userId: string, startedAt: string, finishedAt: string, status: string, meta: record<origin: string, clientIp: string, userAgent: string>, stats: any, options: any, usage: any, usageTotalUsd: float, usageUsd: any, inputSchema: string, readme: string, buildNumber: string, actVersion: record<sourceType: string, buildTag: string, versionNumber: string, gitRepoUrl: string, sourceFiles: list>, actorDefinition: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "waitForFinish" $waitForFinish "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-builds/($buildId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete build
#
# DELETE /v2/actor-builds/{buildId}
# operationId: actorBuild_delete
export def "actor-builds delete" [
  buildId: string
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
  let full_url = (build-url $base $"/v2/actor-builds/($buildId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abort build
#
# POST /v2/actor-builds/{buildId}/abort
# operationId: actorBuild_abort_post
export def "actor-builds-abort post" [
  buildId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, actId: string, userId: string, startedAt: string, finishedAt: string, status: string, meta: record<origin: string, clientIp: string, userAgent: string>, stats: any, options: any, usage: any, usageTotalUsd: float, usageUsd: any, inputSchema: string, readme: string, buildNumber: string, actVersion: record<sourceType: string, buildTag: string, versionNumber: string, gitRepoUrl: string, sourceFiles: list>, actorDefinition: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/actor-builds/($buildId)/abort")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get build's Log
#
# GET /v2/actor-builds/{buildId}/log
# operationId: actorBuild_log_get
export def "actor-builds-log get" [
  buildId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stream: oneof<nothing, bool> # If `true` or `1` then the logs will be streamed as long as the run or build is running.  (e.g. false)
  --download: oneof<nothing, bool> # If `true` or `1` then the web browser will download the log file rather than open it in a tab.  (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stream" $stream "scalar") (serialize-qp "download" $download "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/actor-builds/($buildId)/log" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get OpenAPI definition
#
# GET /v2/actor-builds/{buildId}/openapi.json
# operationId: actorBuild_openapi_json_get
export def "actor-builds-openapijson get" [
  buildId: string
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
  let full_url = (build-url $base $"/v2/actor-builds/($buildId)/openapi.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of key-value stores
#
# GET /v2/key-value-stores
# operationId: keyValueStores_get
export def "key-value-stores list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. The default value as well as the maximum is `1000`.  (format: double, e.g. 1000)
  --desc: oneof<nothing, bool> # If `true` or `1` then the objects are sorted by the `createdAt` field in descending order. By default, they are sorted in ascending order.  (e.g. true)
  --unnamed: oneof<nothing, bool> # If `true` or `1` then all the storages are returned. By default, only named storages are returned.  (e.g. true)
  --ownership: string@ownership-completer # Filter by ownership. If this parameter is omitted, all accessible key-value stores are returned.  - `ownedByMe`: Return only key-value stores owned by the user. - `sharedWithMe`: Return only key-value stores shared with the user by other users.
]: nothing -> record<data: record<total: int, offset: int, limit: int, desc: bool, count: int, unnamed: bool, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "unnamed" $unnamed "scalar") (serialize-qp "ownership" $ownership "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/key-value-stores" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create key-value store
#
# POST /v2/key-value-stores
# operationId: keyValueStores_post
export def "key-value-stores post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Custom unique name to easily identify the store in the future. (e.g. eshop-values)
]: nothing -> record<data: record<id: string, name: string, userId: string, username: string, createdAt: string, modifiedAt: string, accessedAt: string, actId: string, actRunId: string, consoleUrl: string, keysPublicUrl: string, recordsPublicUrl: string, schema: record, urlSigningSecretKey: string, generalAccess: string, stats: record<readCount: int, writeCount: int, deleteCount: int, listCount: int, s3StorageBytes: int, storageBytes: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/key-value-stores" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get store
#
# GET /v2/key-value-stores/{storeId}
# operationId: keyValueStore_get
export def "key-value-stores get" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, name: string, userId: string, username: string, createdAt: string, modifiedAt: string, accessedAt: string, actId: string, actRunId: string, consoleUrl: string, keysPublicUrl: string, recordsPublicUrl: string, schema: record, urlSigningSecretKey: string, generalAccess: string, stats: record<readCount: int, writeCount: int, deleteCount: int, listCount: int, s3StorageBytes: int, storageBytes: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/key-value-stores/($storeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update store
#
# PUT /v2/key-value-stores/{storeId}
# operationId: keyValueStore_put
export def "key-value-stores put" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # nullable
  --generalAccess: string@generalAccess-completer # Defines the general access level for the resource.
]: any -> record<data: record<id: string, name: string, userId: string, username: string, createdAt: string, modifiedAt: string, accessedAt: string, actId: string, actRunId: string, consoleUrl: string, keysPublicUrl: string, recordsPublicUrl: string, schema: record, urlSigningSecretKey: string, generalAccess: string, stats: record<readCount: int, writeCount: int, deleteCount: int, listCount: int, s3StorageBytes: int, storageBytes: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/key-value-stores/($storeId)")
  let body = {name: $name, generalAccess: $generalAccess} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete store
#
# DELETE /v2/key-value-stores/{storeId}
# operationId: keyValueStore_delete
export def "key-value-stores delete" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/key-value-stores/($storeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of keys
#
# GET /v2/key-value-stores/{storeId}/keys
# operationId: keyValueStore_keys_get
export def "key-value-stores-keys get" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --exclusiveStartKey: string # All keys up to this one (including) are skipped from the result. (e.g. Ihnsp8YrvJ8102Kj)
  --limit: float # Number of keys to be returned. (format: int32, default: 1000, e.g. 100)
  --collection: string # Limit the results to keys that belong to a specific collection from the key-value store schema. The key-value store need to have a schema defined for this parameter to work. (e.g. postImages)
  --prefix: string # Limit the results to keys that start with a specific prefix. (e.g. post-images-)
  --signature: string # Signature used for the access. (e.g. 2wTI46Bg8qWQrV7tavlPI)
]: nothing -> record<data: record<items: list<record>, count: int, limit: int, exclusiveStartKey: string, isTruncated: bool, nextExclusiveStartKey: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exclusiveStartKey" $exclusiveStartKey "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "collection" $collection "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/key-value-stores/($storeId)/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download records
#
# GET /v2/key-value-stores/{storeId}/records
# operationId: keyValueStore_records_get
export def "key-value-stores-records list" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --collection: string # If specified, only records belonging to a specific collection from the key-value store schema. The key-value store need to have a schema defined for this parameter to work.  (e.g. my-collection)
  --prefix: string # If specified, only records whose key starts with the given prefix are included in the archive.  (e.g. my-prefix/)
  --signature: string # Signature used for the access. (e.g. 2wTI46Bg8qWQrV7tavlPI)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "collection" $collection "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/key-value-stores/($storeId)/records" $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get record
#
# GET /v2/key-value-stores/{storeId}/records/{recordKey}
# operationId: keyValueStore_record_get
export def "key-value-stores-records get" [
  storeId: string
  recordKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --attachment: oneof<nothing, bool> # If `true` or `1`, the response will be served with `Content-Disposition: attachment` header, causing web browsers to offer downloading HTML records instead of displaying them.  (e.g. true)
  --signature: string # Signature used for the access. (e.g. 2wTI46Bg8qWQrV7tavlPI)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attachment" $attachment "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/key-value-stores/($storeId)/records/($recordKey)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if a record exists
#
# HEAD /v2/key-value-stores/{storeId}/records/{recordKey}
# operationId: keyValueStore_record_head
export def "key-value-stores-records head" [
  storeId: string
  recordKey: string
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
  let full_url = (build-url $base $"/v2/key-value-stores/($storeId)/records/($recordKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Store record
#
# PUT /v2/key-value-stores/{storeId}/records/{recordKey}
# operationId: keyValueStore_record_put
export def "key-value-stores-records put" [
  storeId: string
  recordKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Encoding: string@Content-Encoding-completer
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/key-value-stores/($storeId)/records/($recordKey)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Encoding": $Content_Encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Store record (POST)
#
# POST /v2/key-value-stores/{storeId}/records/{recordKey}
# operationId: keyValueStore_record_post
export def "key-value-stores-records post" [
  storeId: string
  recordKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Encoding: string@Content-Encoding-completer
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/key-value-stores/($storeId)/records/($recordKey)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Encoding": $Content_Encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete record
#
# DELETE /v2/key-value-stores/{storeId}/records/{recordKey}
# operationId: keyValueStore_record_delete
export def "key-value-stores-records delete" [
  storeId: string
  recordKey: string
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
  let full_url = (build-url $base $"/v2/key-value-stores/($storeId)/records/($recordKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of datasets
#
# GET /v2/datasets
# operationId: datasets_get
export def "datasets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. The default value as well as the maximum is `1000`.  (format: double, e.g. 1000)
  --desc: oneof<nothing, bool> # If `true` or `1` then the objects are sorted by the `createdAt` field in descending order. By default, they are sorted in ascending order.  (e.g. true)
  --unnamed: oneof<nothing, bool> # If `true` or `1` then all the storages are returned. By default, only named storages are returned.  (e.g. true)
  --ownership: string@ownership-completer # Filter by ownership. If this parameter is omitted, all accessible datasets are returned.  - `ownedByMe`: Return only datasets owned by the user. - `sharedWithMe`: Return only datasets shared with the user by other users.
]: nothing -> record<data: record<total: int, offset: int, limit: int, desc: bool, count: int, unnamed: bool, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "unnamed" $unnamed "scalar") (serialize-qp "ownership" $ownership "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/datasets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create dataset
#
# POST /v2/datasets
# operationId: datasets_post
export def "datasets post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Custom unique name to easily identify the dataset in the future. (e.g. eshop-items)
]: nothing -> record<data: record<id: string, name: string, userId: string, createdAt: string, modifiedAt: string, accessedAt: string, itemCount: int, cleanItemCount: int, actId: string, actRunId: string, fields: list<string>, schema: record, consoleUrl: string, itemsPublicUrl: string, urlSigningSecretKey: string, generalAccess: string, stats: record<readCount: int, writeCount: int, storageBytes: int, inflatedBytes: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/datasets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get dataset
#
# GET /v2/datasets/{datasetId}
# operationId: dataset_get
export def "datasets get" [
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, name: string, userId: string, createdAt: string, modifiedAt: string, accessedAt: string, itemCount: int, cleanItemCount: int, actId: string, actRunId: string, fields: list<string>, schema: record, consoleUrl: string, itemsPublicUrl: string, urlSigningSecretKey: string, generalAccess: string, stats: record<readCount: int, writeCount: int, storageBytes: int, inflatedBytes: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/datasets/($datasetId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update dataset
#
# PUT /v2/datasets/{datasetId}
# operationId: dataset_put
export def "datasets put" [
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # nullable
  --generalAccess: string@generalAccess-completer # Defines the general access level for the resource.
]: any -> record<data: record<id: string, name: string, userId: string, createdAt: string, modifiedAt: string, accessedAt: string, itemCount: int, cleanItemCount: int, actId: string, actRunId: string, fields: list<string>, schema: record, consoleUrl: string, itemsPublicUrl: string, urlSigningSecretKey: string, generalAccess: string, stats: record<readCount: int, writeCount: int, storageBytes: int, inflatedBytes: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/datasets/($datasetId)")
  let body = {name: $name, generalAccess: $generalAccess} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete dataset
#
# DELETE /v2/datasets/{datasetId}
# operationId: dataset_delete
export def "datasets delete" [
  datasetId: string
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
  let full_url = (build-url $base $"/v2/datasets/($datasetId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get dataset items
#
# GET /v2/datasets/{datasetId}/items
# operationId: dataset_items_get
export def "datasets-items get" [
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string # Format of the results, possible values are: `json`, `jsonl`, `csv`, `html`, `xlsx`, `xml` and `rss`. The default value is `json`.  (e.g. json)
  --clean: oneof<nothing, bool> # If `true` or `1` then the API endpoint returns only non-empty items and skips hidden fields (i.e. fields starting with the # character). The `clean` parameter is just a shortcut for `skipHidden=true` and `skipEmpty=true` parameters. Note that since some objects might be skipped from the output, that the result might contain less items than the `limit` value.  (e.g. false)
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. By default there is no limit. (format: double)
  --qp-fields: string # A comma-separated list of fields which should be picked from the items, only these fields will remain in the resulting record objects. Note that the fields in the outputted items are sorted the same way as they are specified in the `fields` query parameter. You can use this feature to effectively fix the output format.  (e.g. myValue,myOtherValue)
  --outputFields: string # A comma-separated list of output field names that positionally rename the fields specified in the `fields` parameter. For example, `?fields=headline,url&outputFields=title,link` renames `headline` to `title` and `url` to `link` in the output. The number of names in `outputFields` must match the number of names in `fields`. Requires the `fields` parameter to be specified as well.  (e.g. title,link)
  --omit: string # A comma-separated list of fields which should be omitted from the items. (e.g. myValue,myOtherValue)
  --unwind: string # A comma-separated list of fields which should be unwound, in order which they should be processed. Each field should be either an array or an object. If the field is an array then every element of the array will become a separate record and merged with parent object. If the unwound field is an object then it is merged with the parent object. If the unwound field is missing or its value is neither an array nor an object and therefore cannot be merged with a parent object then the item gets preserved as it is. Note that the unwound items ignore the `desc` parameter.  (e.g. myValue,myOtherValue)
  --flatten: string # A comma-separated list of fields which should transform nested objects into flat structures.  For example, with `flatten="foo"` the object `{"foo":{"bar": "hello"}}` is turned into `{"foo.bar": "hello"}`.  The original object with properties is replaced with the flattened object.  (e.g. myValue)
  --desc: oneof<nothing, bool> # By default, results are returned in the same order as they were stored. To reverse the order, set this parameter to `true` or `1`.  (e.g. true)
  --attachment: oneof<nothing, bool> # If `true` or `1` then the response will define the `Content-Disposition: attachment` header, forcing a web browser to download the file rather than to display it. By default this header is not present.  (e.g. true)
  --delimiter: string # A delimiter character for CSV files, only used if `format=csv`. You might need to URL-encode the character (e.g. use `%09` for tab or `%3B` for semicolon). The default delimiter is a simple comma (`,`).  (e.g. ;)
  --bom: oneof<nothing, bool> # All text responses are encoded in UTF-8 encoding. By default, the `format=csv` files are prefixed with the UTF-8 Byte Order Mark (BOM), while `json`, `jsonl`, `xml`, `html` and `rss` files are not.  If you want to override this default behavior, specify `bom=1` query parameter to include the BOM or `bom=0` to skip it.  (e.g. false)
  --xmlRoot: string # Overrides default root element name of `xml` output. By default the root element is `items`.  (e.g. items)
  --xmlRow: string # Overrides default element name that wraps each page or page function result object in `xml` output. By default the element name is `item`.  (e.g. item)
  --skipHeaderRow: oneof<nothing, bool> # If `true` or `1` then header row in the `csv` format is skipped. (e.g. true)
  --skipHidden: oneof<nothing, bool> # If `true` or `1` then hidden fields are skipped from the output, i.e. fields starting with the `#` character.  (e.g. false)
  --skipEmpty: oneof<nothing, bool> # If `true` or `1` then empty items are skipped from the output.  Note that if used, the results might contain less items than the limit value.  (e.g. false)
  --simplified: oneof<nothing, bool> # If `true` or `1` then, the endpoint applies the `fields=url,pageFunctionResult,errorInfo` and `unwind=pageFunctionResult` query parameters. This feature is used to emulate simplified results provided by the legacy Apify Crawler product and it's not recommended to use it in new integrations.  (e.g. false)
  --view: string # Defines the view configuration for dataset items based on the schema definition. This parameter determines how the data will be filtered and presented. For complete specification details, see the [dataset schema documentation](/platform/actors/development/actor-definition/dataset-schema).  (e.g. overview)
  --skipFailedPages: oneof<nothing, bool> # If `true` or `1` then, the all the items with errorInfo property will be skipped from the output.  This feature is here to emulate functionality of API version 1 used for the legacy Apify Crawler product and it's not recommended to use it in new integrations.  (e.g. false)
  --feedTitle: string # Overrides the auto-generated RSS channel `<title>` element. Only used when `format=rss`. If not provided, the title defaults to `Dataset <label>`.  (e.g. Latest posts from r/pasta)
  --feedDescription: string # Overrides the auto-generated RSS channel `<description>` element. Only used when `format=rss`. If not provided, the description defaults to `Items in dataset with id "<datasetId>".`  (e.g. Scraped forum posts)
  --signature: string # Signature used for the access. (e.g. 2wTI46Bg8qWQrV7tavlPI)
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "clean" $clean "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "outputFields" $outputFields "scalar") (serialize-qp "omit" $omit "scalar") (serialize-qp "unwind" $unwind "scalar") (serialize-qp "flatten" $flatten "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "attachment" $attachment "scalar") (serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "bom" $bom "scalar") (serialize-qp "xmlRoot" $xmlRoot "scalar") (serialize-qp "xmlRow" $xmlRow "scalar") (serialize-qp "skipHeaderRow" $skipHeaderRow "scalar") (serialize-qp "skipHidden" $skipHidden "scalar") (serialize-qp "skipEmpty" $skipEmpty "scalar") (serialize-qp "simplified" $simplified "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "skipFailedPages" $skipFailedPages "scalar") (serialize-qp "feedTitle" $feedTitle "scalar") (serialize-qp "feedDescription" $feedDescription "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/datasets/($datasetId)/items" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get dataset items headers
#
# HEAD /v2/datasets/{datasetId}/items
# operationId: dataset_items_head
export def "datasets-items head" [
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # Format of the results, possible values are: `json`, `jsonl`, `csv`, `html`, `xlsx`, `xml` and `rss`. The default value is `json`.  (e.g. json)
  --clean: oneof<nothing, bool> # If `true` or `1` then the API endpoint returns only non-empty items and skips hidden fields (i.e. fields starting with the # character). The `clean` parameter is just a shortcut for `skipHidden=true` and `skipEmpty=true` parameters. Note that since some objects might be skipped from the output, that the result might contain less items than the `limit` value.  (e.g. false)
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. By default there is no limit. (format: double)
  --qp-fields: string # A comma-separated list of fields which should be picked from the items, only these fields will remain in the resulting record objects. Note that the fields in the outputted items are sorted the same way as they are specified in the `fields` query parameter. You can use this feature to effectively fix the output format.  (e.g. myValue,myOtherValue)
  --outputFields: string # A comma-separated list of output field names that positionally rename the fields specified in the `fields` parameter. For example, `?fields=headline,url&outputFields=title,link` renames `headline` to `title` and `url` to `link` in the output. The number of names in `outputFields` must match the number of names in `fields`. Requires the `fields` parameter to be specified as well.  (e.g. title,link)
  --omit: string # A comma-separated list of fields which should be omitted from the items. (e.g. myValue,myOtherValue)
  --unwind: string # A comma-separated list of fields which should be unwound, in order which they should be processed. Each field should be either an array or an object. If the field is an array then every element of the array will become a separate record and merged with parent object. If the unwound field is an object then it is merged with the parent object. If the unwound field is missing or its value is neither an array nor an object and therefore cannot be merged with a parent object then the item gets preserved as it is. Note that the unwound items ignore the `desc` parameter.  (e.g. myValue,myOtherValue)
  --flatten: string # A comma-separated list of fields which should transform nested objects into flat structures.  For example, with `flatten="foo"` the object `{"foo":{"bar": "hello"}}` is turned into `{"foo.bar": "hello"}`.  The original object with properties is replaced with the flattened object.  (e.g. myValue)
  --desc: oneof<nothing, bool> # By default, results are returned in the same order as they were stored. To reverse the order, set this parameter to `true` or `1`.  (e.g. true)
  --attachment: oneof<nothing, bool> # If `true` or `1` then the response will define the `Content-Disposition: attachment` header, forcing a web browser to download the file rather than to display it. By default this header is not present.  (e.g. true)
  --delimiter: string # A delimiter character for CSV files, only used if `format=csv`. You might need to URL-encode the character (e.g. use `%09` for tab or `%3B` for semicolon). The default delimiter is a simple comma (`,`).  (e.g. ;)
  --bom: oneof<nothing, bool> # All text responses are encoded in UTF-8 encoding. By default, the `format=csv` files are prefixed with the UTF-8 Byte Order Mark (BOM), while `json`, `jsonl`, `xml`, `html` and `rss` files are not.  If you want to override this default behavior, specify `bom=1` query parameter to include the BOM or `bom=0` to skip it.  (e.g. false)
  --xmlRoot: string # Overrides default root element name of `xml` output. By default the root element is `items`.  (e.g. items)
  --xmlRow: string # Overrides default element name that wraps each page or page function result object in `xml` output. By default the element name is `item`.  (e.g. item)
  --skipHeaderRow: oneof<nothing, bool> # If `true` or `1` then header row in the `csv` format is skipped. (e.g. true)
  --skipHidden: oneof<nothing, bool> # If `true` or `1` then hidden fields are skipped from the output, i.e. fields starting with the `#` character.  (e.g. false)
  --skipEmpty: oneof<nothing, bool> # If `true` or `1` then empty items are skipped from the output.  Note that if used, the results might contain less items than the limit value.  (e.g. false)
  --simplified: oneof<nothing, bool> # If `true` or `1` then, the endpoint applies the `fields=url,pageFunctionResult,errorInfo` and `unwind=pageFunctionResult` query parameters. This feature is used to emulate simplified results provided by the legacy Apify Crawler product and it's not recommended to use it in new integrations.  (e.g. false)
  --view: string # Defines the view configuration for dataset items based on the schema definition. This parameter determines how the data will be filtered and presented. For complete specification details, see the [dataset schema documentation](/platform/actors/development/actor-definition/dataset-schema).  (e.g. overview)
  --skipFailedPages: oneof<nothing, bool> # If `true` or `1` then, the all the items with errorInfo property will be skipped from the output.  This feature is here to emulate functionality of API version 1 used for the legacy Apify Crawler product and it's not recommended to use it in new integrations.  (e.g. false)
  --feedTitle: string # Overrides the auto-generated RSS channel `<title>` element. Only used when `format=rss`. If not provided, the title defaults to `Dataset <label>`.  (e.g. Latest posts from r/pasta)
  --feedDescription: string # Overrides the auto-generated RSS channel `<description>` element. Only used when `format=rss`. If not provided, the description defaults to `Items in dataset with id "<datasetId>".`  (e.g. Scraped forum posts)
  --signature: string # Signature used for the access. (e.g. 2wTI46Bg8qWQrV7tavlPI)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "clean" $clean "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "outputFields" $outputFields "scalar") (serialize-qp "omit" $omit "scalar") (serialize-qp "unwind" $unwind "scalar") (serialize-qp "flatten" $flatten "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "attachment" $attachment "scalar") (serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "bom" $bom "scalar") (serialize-qp "xmlRoot" $xmlRoot "scalar") (serialize-qp "xmlRow" $xmlRow "scalar") (serialize-qp "skipHeaderRow" $skipHeaderRow "scalar") (serialize-qp "skipHidden" $skipHidden "scalar") (serialize-qp "skipEmpty" $skipEmpty "scalar") (serialize-qp "simplified" $simplified "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "skipFailedPages" $skipFailedPages "scalar") (serialize-qp "feedTitle" $feedTitle "scalar") (serialize-qp "feedDescription" $feedDescription "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/datasets/($datasetId)/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Store items
#
# POST /v2/datasets/{datasetId}/items
# operationId: dataset_items_post
export def "datasets-items post" [
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/datasets/($datasetId)/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get dataset statistics
#
# GET /v2/datasets/{datasetId}/statistics
# operationId: dataset_statistics_get
export def "datasets-statistics get" [
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<fieldStatistics: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/datasets/($datasetId)/statistics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of request queues
#
# GET /v2/request-queues
# operationId: requestQueues_get
export def "request-queues list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. The default value as well as the maximum is `1000`.  (format: double, e.g. 1000)
  --desc: oneof<nothing, bool> # If `true` or `1` then the objects are sorted by the `createdAt` field in descending order. By default, they are sorted in ascending order.  (e.g. true)
  --unnamed: oneof<nothing, bool> # If `true` or `1` then all the storages are returned. By default, only named storages are returned.  (e.g. true)
  --ownership: string@ownership-completer # Filter by ownership. If this parameter is omitted, all accessible request queues are returned.  - `ownedByMe`: Return only request queues owned by the user. - `sharedWithMe`: Return only request queues shared with the user by other users.
]: nothing -> record<data: record<total: int, offset: int, limit: int, desc: bool, count: int, unnamed: bool, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "unnamed" $unnamed "scalar") (serialize-qp "ownership" $ownership "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/request-queues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create request queue
#
# POST /v2/request-queues
# operationId: requestQueues_post
export def "request-queues post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Custom unique name to easily identify the queue in the future. (e.g. example-com)
]: nothing -> record<data: record<id: string, name: string, userId: string, actId: string, actRunId: string, createdAt: string, modifiedAt: string, accessedAt: string, totalRequestCount: int, handledRequestCount: int, pendingRequestCount: int, hadMultipleClients: bool, consoleUrl: string, stats: record<deleteCount: int, headItemReadCount: int, readCount: int, storageBytes: int, writeCount: int>, generalAccess: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/request-queues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get request queue
#
# GET /v2/request-queues/{queueId}
# operationId: requestQueue_get
export def "request-queues get" [
  queueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, name: string, userId: string, actId: string, actRunId: string, createdAt: string, modifiedAt: string, accessedAt: string, totalRequestCount: int, handledRequestCount: int, pendingRequestCount: int, hadMultipleClients: bool, consoleUrl: string, stats: record<deleteCount: int, headItemReadCount: int, readCount: int, storageBytes: int, writeCount: int>, generalAccess: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/request-queues/($queueId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update request queue
#
# PUT /v2/request-queues/{queueId}
# operationId: requestQueue_put
export def "request-queues put" [
  queueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name for the request queue. (nullable)
  --generalAccess: string@generalAccess-completer # Defines the general access level for the resource.
]: any -> record<data: record<id: string, name: string, userId: string, actId: string, actRunId: string, createdAt: string, modifiedAt: string, accessedAt: string, totalRequestCount: int, handledRequestCount: int, pendingRequestCount: int, hadMultipleClients: bool, consoleUrl: string, stats: record<deleteCount: int, headItemReadCount: int, readCount: int, storageBytes: int, writeCount: int>, generalAccess: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/request-queues/($queueId)")
  let body = {name: $name, generalAccess: $generalAccess} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete request queue
#
# DELETE /v2/request-queues/{queueId}
# operationId: requestQueue_delete
export def "request-queues delete" [
  queueId: string
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
  let full_url = (build-url $base $"/v2/request-queues/($queueId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add requests
#
# POST /v2/request-queues/{queueId}/requests/batch
# operationId: requestQueue_requests_batch_post
export def "request-queues-requests-batch post" [
  queueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --forefront: string # Determines if request should be added to the head of the queue or to the end. Default value is `false` (end of queue).  (e.g. false)
  --body: record
]: any -> record<data: record<processedRequests: list<record>, unprocessedRequests: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "forefront" $forefront "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/request-queues/($queueId)/requests/batch" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete requests
#
# DELETE /v2/request-queues/{queueId}/requests/batch
# operationId: requestQueue_requests_batch_delete
export def "request-queues-requests-batch delete" [
  queueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --Content-Type: string
  --body: record
]: any -> record<data: record<processedRequests: list<any>, unprocessedRequests: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/request-queues/($queueId)/requests/batch" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unlock requests
#
# POST /v2/request-queues/{queueId}/requests/unlock
# operationId: requestQueue_requests_unlock_post
export def "request-queues-requests-unlock post" [
  queueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
]: nothing -> record<data: record<unlockedCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/request-queues/($queueId)/requests/unlock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List requests
#
# GET /v2/request-queues/{queueId}/requests
# operationId: requestQueue_requests_get
@deprecated --flag exclusiveStartId
export def "request-queues-requests list" [
  queueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --exclusiveStartId: string # All requests up to this one (including) are skipped from the result. (Deprecated, use `cursor` instead.) (DEPRECATED, e.g. Ihnsp8YrvJ8102Kj)
  --limit: float # Number of keys to be returned. Maximum value is `10000`. (format: double, e.g. 100)
  --cursor: string # A cursor string for pagination, returned in the previous response as `nextCursor`. Use this to retrieve the next page of requests. (e.g. eyJyZXF1ZXN0SWQiOiI2OFRqQ2RaTDNvM2hiUU0ifQ)
  --filter: list # Filter requests by their state. Possible values are `locked` and `pending`. You can combine multiple values separated by commas, which will mean the union of these filters – requests matching any of the specified states will be returned. (Not compatible with deprecated `exclusiveStartId` parameter.) (e.g. [locked])
]: nothing -> record<data: record<items: list<record>, limit: int, exclusiveStartId: string, cursor: string, nextCursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "exclusiveStartId" $exclusiveStartId "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "filter" $filter "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/request-queues/($queueId)/requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add request
#
# POST /v2/request-queues/{queueId}/requests
# operationId: requestQueue_requests_post
export def "request-queues-requests post" [
  queueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --forefront: string # Determines if request should be added to the head of the queue or to the end. Default value is `false` (end of queue).  (e.g. false)
  --uniqueKey: string # A unique key used for request de-duplication. Requests with the same unique key are considered identical.
  --body-url: string # The URL of the request.
  --method: string@method-completer
  --retryCount: int # The number of times this request has been retried.
  --loadedUrl: string # The final URL that was loaded, after redirects (if any). (nullable)
  --payload: string # The request payload, typically used with POST or PUT requests. (nullable)
  --headers: record # HTTP headers sent with the request. (nullable)
  --userData: record # Custom user data attached to the request. Can contain arbitrary fields. (e.g. {label: DETAIL, customField: custom-value})
  --noRetry: oneof<nothing, bool> # Indicates whether the request should not be retried if processing fails. (nullable)
  --errorMessages: list # Error messages recorded from failed processing attempts. (nullable)
  --handledAt: string # The timestamp when the request was marked as handled, if applicable. (nullable, format: date-time)
]: any -> record<data: record<requestId: string, wasAlreadyPresent: bool, wasAlreadyHandled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "forefront" $forefront "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/request-queues/($queueId)/requests" $qp)
  let body = {uniqueKey: $uniqueKey, url: $body_url, method: $method, retryCount: $retryCount, loadedUrl: $loadedUrl, payload: $payload, headers: $headers, userData: $userData, noRetry: $noRetry, errorMessages: $errorMessages, handledAt: $handledAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get request
#
# GET /v2/request-queues/{queueId}/requests/{requestId}
# operationId: requestQueue_request_get
export def "request-queues-requests get" [
  queueId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<uniqueKey: string, url: string, method: string, retryCount: int, loadedUrl: string, payload: string, headers: record, userData: record, noRetry: bool, errorMessages: list<string>, handledAt: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/request-queues/($queueId)/requests/($requestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update request
#
# PUT /v2/request-queues/{queueId}/requests/{requestId}
# operationId: requestQueue_request_put
export def "request-queues-requests put" [
  queueId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forefront: string # Determines if request should be added to the head of the queue or to the end. Default value is `false` (end of queue).  (e.g. false)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --uniqueKey: string # A unique key used for request de-duplication. Requests with the same unique key are considered identical.
  --body-url: string # The URL of the request.
  --method: string@method-completer
  --retryCount: int # The number of times this request has been retried.
  --loadedUrl: string # The final URL that was loaded, after redirects (if any). (nullable)
  --payload: string # The request payload, typically used with POST or PUT requests. (nullable)
  --headers: record # HTTP headers sent with the request. (nullable)
  --userData: record # Custom user data attached to the request. Can contain arbitrary fields. (e.g. {label: DETAIL, customField: custom-value})
  --noRetry: oneof<nothing, bool> # Indicates whether the request should not be retried if processing fails. (nullable)
  --errorMessages: list # Error messages recorded from failed processing attempts. (nullable)
  --handledAt: string # The timestamp when the request was marked as handled, if applicable. (nullable, format: date-time)
  --id: string # A unique identifier assigned to the request.
]: any -> record<data: record<requestId: string, wasAlreadyPresent: bool, wasAlreadyHandled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forefront" $forefront "scalar") (serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/request-queues/($queueId)/requests/($requestId)" $qp)
  let body = {uniqueKey: $uniqueKey, url: $body_url, method: $method, retryCount: $retryCount, loadedUrl: $loadedUrl, payload: $payload, headers: $headers, userData: $userData, noRetry: $noRetry, errorMessages: $errorMessages, handledAt: $handledAt, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete request
#
# DELETE /v2/request-queues/{queueId}/requests/{requestId}
# operationId: requestQueue_request_delete
export def "request-queues-requests delete" [
  queueId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/request-queues/($queueId)/requests/($requestId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get head
#
# GET /v2/request-queues/{queueId}/head
# operationId: requestQueue_head_get
export def "request-queues-head get" [
  queueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # How many items from queue should be returned. (format: double, e.g. 100)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
]: nothing -> record<data: record<limit: int, queueModifiedAt: string, hadMultipleClients: bool, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/request-queues/($queueId)/head" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get head and lock
#
# POST /v2/request-queues/{queueId}/head/lock
# operationId: requestQueue_head_lock_post
export def "request-queues-head-lock post" [
  queueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lockSecs: float # How long the requests will be locked for (in seconds). (format: double, e.g. 60)
  --limit: float # How many items from the queue should be returned. (format: double, e.g. 25)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
]: nothing -> record<data: record<limit: int, queueModifiedAt: string, queueHasLockedRequests: bool, clientKey: string, hadMultipleClients: bool, lockSecs: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lockSecs" $lockSecs "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "clientKey" $clientKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/request-queues/($queueId)/head/lock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Prolong request lock
#
# PUT /v2/request-queues/{queueId}/requests/{requestId}/lock
# operationId: requestQueue_request_lock_put
export def "request-queues-requests-lock put" [
  queueId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lockSecs: float # How long the requests will be locked for (in seconds). (format: double, e.g. 60)
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --forefront: string # Determines if request should be added to the head of the queue or to the end after lock expires.  (e.g. false)
]: nothing -> record<data: record<lockExpiresAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lockSecs" $lockSecs "scalar") (serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "forefront" $forefront "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/request-queues/($queueId)/requests/($requestId)/lock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete request lock
#
# DELETE /v2/request-queues/{queueId}/requests/{requestId}/lock
# operationId: requestQueue_request_lock_delete
export def "request-queues-requests-lock delete" [
  queueId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientKey: string # A unique identifier of the client accessing the request queue. It must be a string between 1 and 32 characters long. This identifier is used to determine whether the queue was accessed by multiple clients. If `clientKey` is not provided, the system considers this API call to come from a new client. For details, see the `hadMultipleClients` field returned by the [Get head](#/reference/request-queues/queue-head) operation.  (e.g. client-abc)
  --forefront: string # Determines if request should be added to the head of the queue or to the end after lock was removed.  (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientKey" $clientKey "scalar") (serialize-qp "forefront" $forefront "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/request-queues/($queueId)/requests/($requestId)/lock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of webhooks
#
# GET /v2/webhooks
# operationId: webhooks_get
export def "webhooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. The default value as well as the maximum is `1000`.  (format: double, e.g. 1000)
  --desc: oneof<nothing, bool> # If `true` or `1` then the objects are sorted by the `createdAt` field in descending order. By default, they are sorted in ascending order.  (e.g. true)
]: nothing -> record<data: record<total: int, offset: int, limit: int, desc: bool, count: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "desc" $desc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create webhook
#
# POST /v2/webhooks
# operationId: webhooks_post
# --condition shape: {actorId?: string, actorTaskId?: string, actorRunId?: string}
export def "webhooks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isAdHoc: oneof<nothing, bool> # nullable
  eventTypes: list
  condition: record # shape: {actorId?: string, actorTaskId?: string, actorRunId?: string}
  --idempotencyKey: string # nullable
  --ignoreSslErrors: oneof<nothing, bool> # nullable
  --doNotRetry: oneof<nothing, bool> # nullable
  requestUrl: string
  --payloadTemplate: string # nullable
  --headersTemplate: string # nullable
  --description: string # nullable
  --shouldInterpolateStrings: oneof<nothing, bool> # nullable
]: any -> record<data: record<id: string, createdAt: string, modifiedAt: string, userId: string, isAdHoc: bool, shouldInterpolateStrings: bool, eventTypes: list<string>, condition: record<actorId: string, actorTaskId: string, actorRunId: string>, ignoreSslErrors: bool, doNotRetry: bool, requestUrl: string, payloadTemplate: string, headersTemplate: string, description: string, lastDispatch: any, stats: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/webhooks")
  let body = {isAdHoc: $isAdHoc, eventTypes: $eventTypes, condition: $condition, idempotencyKey: $idempotencyKey, ignoreSslErrors: $ignoreSslErrors, doNotRetry: $doNotRetry, requestUrl: $requestUrl, payloadTemplate: $payloadTemplate, headersTemplate: $headersTemplate, description: $description, shouldInterpolateStrings: $shouldInterpolateStrings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get webhook
#
# GET /v2/webhooks/{webhookId}
# operationId: webhook_get
export def "webhooks get" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, createdAt: string, modifiedAt: string, userId: string, isAdHoc: bool, shouldInterpolateStrings: bool, eventTypes: list<string>, condition: record<actorId: string, actorTaskId: string, actorRunId: string>, ignoreSslErrors: bool, doNotRetry: bool, requestUrl: string, payloadTemplate: string, headersTemplate: string, description: string, lastDispatch: any, stats: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update webhook
#
# PUT /v2/webhooks/{webhookId}
# operationId: webhook_put
export def "webhooks put" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isAdHoc: oneof<nothing, bool> # nullable
  --eventTypes: list # nullable
  --condition: any
  --ignoreSslErrors: oneof<nothing, bool> # nullable
  --doNotRetry: oneof<nothing, bool> # nullable
  --requestUrl: string # nullable, format: uri
  --payloadTemplate: string # nullable
  --headersTemplate: string # nullable
  --description: string # nullable
  --shouldInterpolateStrings: oneof<nothing, bool> # nullable
]: any -> record<data: record<id: string, createdAt: string, modifiedAt: string, userId: string, isAdHoc: bool, shouldInterpolateStrings: bool, eventTypes: list<string>, condition: record<actorId: string, actorTaskId: string, actorRunId: string>, ignoreSslErrors: bool, doNotRetry: bool, requestUrl: string, payloadTemplate: string, headersTemplate: string, description: string, lastDispatch: any, stats: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/webhooks/($webhookId)")
  let body = {isAdHoc: $isAdHoc, eventTypes: $eventTypes, condition: $condition, ignoreSslErrors: $ignoreSslErrors, doNotRetry: $doNotRetry, requestUrl: $requestUrl, payloadTemplate: $payloadTemplate, headersTemplate: $headersTemplate, description: $description, shouldInterpolateStrings: $shouldInterpolateStrings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete webhook
#
# DELETE /v2/webhooks/{webhookId}
# operationId: webhook_delete
export def "webhooks delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test webhook
#
# POST /v2/webhooks/{webhookId}/test
# operationId: webhook_test_post
export def "webhooks-test post" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, userId: string, webhookId: string, createdAt: string, status: string, eventType: string, eventData: record<actorId: string, actorRunId: string>, webhook: any, calls: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/webhooks/($webhookId)/test")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get collection
#
# GET /v2/webhooks/{webhookId}/dispatches
# operationId: webhook_webhookDispatches_get
export def "webhooks-dispatches get" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<total: int, offset: int, limit: int, desc: bool, count: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/webhooks/($webhookId)/dispatches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of webhook dispatches
#
# GET /v2/webhook-dispatches
# operationId: webhookDispatches_get
export def "webhook-dispatches list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. The default value as well as the maximum is `1000`.  (format: double, e.g. 1000)
  --desc: oneof<nothing, bool> # If `true` or `1` then the objects are sorted by the `createdAt` field in descending order. By default, they are sorted in ascending order.  (e.g. true)
]: nothing -> record<data: record<total: int, offset: int, limit: int, desc: bool, count: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "desc" $desc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/webhook-dispatches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get webhook dispatch
#
# GET /v2/webhook-dispatches/{dispatchId}
# operationId: webhookDispatch_get
export def "webhook-dispatches get" [
  dispatchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, userId: string, webhookId: string, createdAt: string, status: string, eventType: string, eventData: record<actorId: string, actorRunId: string>, webhook: any, calls: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/webhook-dispatches/($dispatchId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of schedules
#
# GET /v2/schedules
# operationId: schedules_get
export def "schedules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --limit: float # Maximum number of items to return. The default value as well as the maximum is `1000`.  (format: double, e.g. 1000)
  --desc: oneof<nothing, bool> # If `true` or `1` then the objects are sorted by the `createdAt` field in descending order. By default, they are sorted in ascending order.  (e.g. true)
]: nothing -> record<data: record<total: int, offset: int, limit: int, desc: bool, count: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "desc" $desc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create schedule
#
# POST /v2/schedules
# operationId: schedules_post
export def "schedules post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # nullable
  --isEnabled: oneof<nothing, bool> # nullable
  --isExclusive: oneof<nothing, bool> # nullable
  --cronExpression: string # nullable
  --timezone: string # nullable
  --description: string # nullable
  --title: string # nullable
  --actions: list # nullable
]: any -> record<data: record<id: string, userId: string, name: string, cronExpression: string, timezone: string, isEnabled: bool, isExclusive: bool, createdAt: string, modifiedAt: string, nextRunAt: string, lastRunAt: string, description: string, title: string, notifications: record<email: bool>, actions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/schedules")
  let body = {name: $name, isEnabled: $isEnabled, isExclusive: $isExclusive, cronExpression: $cronExpression, timezone: $timezone, description: $description, title: $title, actions: $actions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get schedule
#
# GET /v2/schedules/{scheduleId}
# operationId: schedule_get
export def "schedules get" [
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, userId: string, name: string, cronExpression: string, timezone: string, isEnabled: bool, isExclusive: bool, createdAt: string, modifiedAt: string, nextRunAt: string, lastRunAt: string, description: string, title: string, notifications: record<email: bool>, actions: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/schedules/($scheduleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update schedule
#
# PUT /v2/schedules/{scheduleId}
# operationId: schedule_put
export def "schedules put" [
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # nullable
  --isEnabled: oneof<nothing, bool> # nullable
  --isExclusive: oneof<nothing, bool> # nullable
  --cronExpression: string # nullable
  --timezone: string # nullable
  --description: string # nullable
  --title: string # nullable
  --actions: list # nullable
]: any -> record<data: record<id: string, userId: string, name: string, cronExpression: string, timezone: string, isEnabled: bool, isExclusive: bool, createdAt: string, modifiedAt: string, nextRunAt: string, lastRunAt: string, description: string, title: string, notifications: record<email: bool>, actions: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/schedules/($scheduleId)")
  let body = {name: $name, isEnabled: $isEnabled, isExclusive: $isExclusive, cronExpression: $cronExpression, timezone: $timezone, description: $description, title: $title, actions: $actions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete schedule
#
# DELETE /v2/schedules/{scheduleId}
# operationId: schedule_delete
export def "schedules delete" [
  scheduleId: string
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
  let full_url = (build-url $base $"/v2/schedules/($scheduleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get schedule log
#
# GET /v2/schedules/{scheduleId}/log
# operationId: schedule_log_get
export def "schedules-log get" [
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<message: string, level: string, createdAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/schedules/($scheduleId)/log")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of Actors in Store
#
# GET /v2/store
# operationId: store_get
export def "store get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # Maximum number of items to return. The default value as well as the maximum is `1000`.  (format: double, e.g. 1000)
  --offset: float # Number of items that should be skipped at the start. The default value is `0`.  (format: double, e.g. 0)
  --search: string # String to search by. The search runs on the following fields: `title`, `name`, `description`, `username`, `readme`.  (e.g. web scraper)
  --sortBy: string # Specifies the field by which to sort the results. The supported values are `relevance` (default), `popularity`, `newest` and `lastUpdate`.  (e.g. 'popularity')
  --category: string # Filters the results by the specified category. (e.g. 'AI')
  --username: string # Filters the results by the specified username. (e.g. 'apify')
  --pricingModel: string@pricingModel-completer # Only return Actors with the specified pricing model.  (e.g. FREE)
  --allowsAgenticUsers: oneof<nothing, bool> # If true, only return Actors that allow agentic users. If false, only return Actors that do not allow agentic users.  (e.g. true)
  --responseFormat: string@responseFormat-completer # Controls the shape of the response. Use `full` (default) for the complete response including image URLs and all fields. Use `agent` for a reduced field set optimized for LLM consumers, which only includes `id`, `title`, `name`, `username`, `description`, `notice`, `badge`, `categories`, and minimal `stats`.  (default: full, e.g. agent)
  --includeUnrunnableActors: oneof<nothing, bool> # By default, search results exclude Actors that are not safe to run automatically (e.g. Actors from developers who haven't passed KYC, or full-permission Actors without a large user base). Set to `true` to bypass this safety filtering and include all Actors in the results.  (default: false, e.g. true)
]: nothing -> record<data: record<total: int, offset: int, limit: int, desc: bool, count: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "pricingModel" $pricingModel "scalar") (serialize-qp "allowsAgenticUsers" $allowsAgenticUsers "scalar") (serialize-qp "responseFormat" $responseFormat "scalar") (serialize-qp "includeUnrunnableActors" $includeUnrunnableActors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/store" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get log
#
# GET /v2/logs/{buildOrRunId}
# operationId: log_get
export def "logs get" [
  buildOrRunId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stream: oneof<nothing, bool> # If `true` or `1` then the logs will be streamed as long as the run or build is running.  (e.g. false)
  --download: oneof<nothing, bool> # If `true` or `1` then the web browser will download the log file rather than open it in a tab.  (e.g. false)
  --qp-raw: oneof<nothing, bool> # If `true` or `1`, the logs will be kept verbatim. By default, the API removes ANSI escape codes from the logs, keeping only printable characters.  (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stream" $stream "scalar") (serialize-qp "download" $download "scalar") (serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/logs/($buildOrRunId)" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get public user data
#
# GET /v2/users/{userId}
# operationId: user_get
export def "users get" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<username: string, profile: record<bio: string, name: string, pictureUrl: string, githubUsername: string, websiteUrl: string, twitterUsername: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get private user data
#
# GET /v2/users/me
# operationId: users_me_get
export def "users-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, username: string, profile: record<bio: string, name: string, pictureUrl: string, githubUsername: string, websiteUrl: string, twitterUsername: string>, email: string, proxy: record<password: string, groups: list>, plan: record<id: string, description: string, isEnabled: bool, monthlyBasePriceUsd: float, monthlyUsageCreditsUsd: float, usageDiscountPercent: float, enabledPlatformFeatures: list, maxMonthlyUsageUsd: float, maxActorMemoryGbytes: float, maxMonthlyActorComputeUnits: float, maxMonthlyResidentialProxyGbytes: float, maxMonthlyProxySerps: int, maxMonthlyExternalDataTransferGbytes: float, maxActorCount: int, maxActorTaskCount: int, dataRetentionDays: int, availableProxyGroups: record, teamAccountSeatCount: int, supportLevel: string, availableAddOns: list, tier: string, apiRateLimitBoosts: int, maxScheduleCount: int, maxConcurrentActorRuns: int, planPricing: record>, effectivePlatformFeatures: record<ACTORS: record, STORAGE: record, SCHEDULER: record, PROXY: record, PROXY_EXTERNAL_ACCESS: record, PROXY_RESIDENTIAL: record, PROXY_SERPS: record, WEBHOOKS: record, ACTORS_PUBLIC_ALL: record, ACTORS_PUBLIC_DEVELOPER: record>, createdAt: string, isPaying: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get monthly usage
#
# GET /v2/users/me/usage/monthly
# operationId: users_me_usage_monthly_get
export def "users-me-usage-monthly get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Date in the YYYY-MM-DD format. (e.g. 2020-06-14)
]: nothing -> record<data: record<usageCycle: record<startAt: string, endAt: string>, monthlyServiceUsage: record, dailyServiceUsages: list<record>, totalUsageCreditsUsdBeforeVolumeDiscount: float, totalUsageCreditsUsdAfterVolumeDiscount: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/users/me/usage/monthly" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get limits
#
# GET /v2/users/me/limits
# operationId: users_me_limits_get
export def "users-me-limits get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<monthlyUsageCycle: record<startAt: string, endAt: string>, limits: record<maxMonthlyUsageUsd: float, maxMonthlyActorComputeUnits: float, maxMonthlyExternalDataTransferGbytes: float, maxMonthlyProxySerps: int, maxMonthlyResidentialProxyGbytes: float, maxActorMemoryGbytes: float, maxActorCount: int, maxActorTaskCount: int, maxConcurrentActorJobs: int, maxTeamAccountSeatCount: int, dataRetentionDays: int, maxScheduleCount: int>, current: record<monthlyUsageUsd: float, monthlyActorComputeUnits: float, monthlyExternalDataTransferGbytes: float, monthlyProxySerps: int, monthlyResidentialProxyGbytes: float, actorMemoryGbytes: float, actorCount: int, actorTaskCount: int, activeActorJobCount: int, teamAccountSeatCount: int, scheduleCount: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/users/me/limits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update limits
#
# PUT /v2/users/me/limits
# operationId: users_me_limits_put
export def "users-me-limits put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxMonthlyUsageUsd: float # If your platform usage in the billing period exceeds the prepaid usage, you will be charged extra. Setting this property you can update your hard limit on monthly platform usage to prevent accidental overage or to limit the extra charges.
  --dataRetentionDays: int # Apify securely stores your ten most recent Actor runs indefinitely, ensuring they are always accessible. Unnamed storages and other Actor runs are automatically deleted after the retention period. If you're subscribed, you can change it to keep data for longer or to limit your usage. [Lear more](https://docs.apify.com/platform/storage/usage#data-retention).
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/users/me/limits")
  let body = {maxMonthlyUsageUsd: $maxMonthlyUsageUsd, dataRetentionDays: $dataRetentionDays} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get browser info
#
# GET /v2/browser-info
# operationId: tools_browser_info_get
export def "browser-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skipHeaders: oneof<nothing, bool> # If `true` or `1`, the response omits the `headers` field.
  --rawHeaders: oneof<nothing, bool> # If `true` or `1`, the response includes the `rawHeaders` field with the raw request headers.
]: nothing -> record<method: string, clientIp: string, countryCode: string, bodyLength: int, headers: record, rawHeaders: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skipHeaders" $skipHeaders "scalar") (serialize-qp "rawHeaders" $rawHeaders "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/browser-info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get browser info
#
# POST /v2/browser-info
# operationId: tools_browser_info_post
export def "browser-info post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skipHeaders: oneof<nothing, bool> # If `true` or `1`, the response omits the `headers` field.
  --rawHeaders: oneof<nothing, bool> # If `true` or `1`, the response includes the `rawHeaders` field with the raw request headers.
]: nothing -> record<method: string, clientIp: string, countryCode: string, bodyLength: int, headers: record, rawHeaders: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skipHeaders" $skipHeaders "scalar") (serialize-qp "rawHeaders" $rawHeaders "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/browser-info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get browser info
#
# PUT /v2/browser-info
# operationId: tools_browser_info_put
export def "browser-info put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skipHeaders: oneof<nothing, bool> # If `true` or `1`, the response omits the `headers` field.
  --rawHeaders: oneof<nothing, bool> # If `true` or `1`, the response includes the `rawHeaders` field with the raw request headers.
]: nothing -> record<method: string, clientIp: string, countryCode: string, bodyLength: int, headers: record, rawHeaders: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skipHeaders" $skipHeaders "scalar") (serialize-qp "rawHeaders" $rawHeaders "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/browser-info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get browser info
#
# DELETE /v2/browser-info
# operationId: tools_browser_info_delete
export def "browser-info delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skipHeaders: oneof<nothing, bool> # If `true` or `1`, the response omits the `headers` field.
  --rawHeaders: oneof<nothing, bool> # If `true` or `1`, the response includes the `rawHeaders` field with the raw request headers.
]: nothing -> record<method: string, clientIp: string, countryCode: string, bodyLength: int, headers: record, rawHeaders: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skipHeaders" $skipHeaders "scalar") (serialize-qp "rawHeaders" $rawHeaders "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/browser-info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Encode and sign object
#
# POST /v2/tools/encode-and-sign
# operationId: tools_encode_and_sign_post
export def "tools-encode-and-sign post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<data: record<encoded: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/tools/encode-and-sign")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Decode and verify object
#
# POST /v2/tools/decode-and-verify
# operationId: tools_decode_and_verify_post
export def "tools-decode-and-verify post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  encoded: string
]: any -> record<data: record<decoded: any, encodedByUserId: string, isVerifiedUser: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/tools/decode-and-verify")
  let body = {encoded: $encoded} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
