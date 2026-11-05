# Auto-generated client for AppVeyor REST API v1.0.0
# Source: https://api.apis.guru/v2/specs/appveyor.com/1.0.0/swagger.json
# Auth: --token flag or $env.APPVEYOR_REST_API_TOKEN

const BASE_URL = "https://ci.appveyor.com/api"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o APPVEYOR_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://ci.appveyor.com/api"] }
def auth-scheme-completer [] { ["bearer" "none"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def provider-completer [] { ["Agent" "AzureBlob" "AzureCS" "AzureWebJob" "BinTray" "FTP" "GitHub" "NuGet" "S3" "SqlDatabase" "WebDeploy" "Webhook"] }
def projects-mode-completer [] { ["0" "1" "2"] }
def repository-authentication-completer [] { ["credentials" "ssh"] }
def repository-provider-completer [] { ["bitBucket" "git" "gitHub" "gitLab" "kiln" "mercurial" "stash" "subversion" "vso"] }
def repository-scm-completer [] { ["git" "mercurial" "subversion"] }
def repository-type-completer [] { ["bitBucket" "git" "gitHub" "gitLab" "kiln" "mercurial" "stash" "subversion" "vso"] }
def badge-repo-provider-completer [] { ["bitBucket" "gitHub"] }
def accept-completer-1 [] { ["image/png" "image/svg+xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["encrypt-value" "get-build-artifacts" "get-build-artifact" "get-build-log" "start-build" "re-run-build" "cancel-build" "get-collaborators" "update-collaborator" "delete-collaborator" "get-collaborator" "start-deployment" "cancel-deployment" "get-deployment" "get-environments" "add-environment" "update-environment" "delete-environment" "get-environment-deployments" "get-environment-settings" "get-projects" "add-project" "update-project" "get-public-project-status-badge" "get-project-status-badge" "get-project-branch-status-badge" "delete-project" "get-project-last-build" "get-project-artifact" "get-project-last-build-branch" "get-project-build-by-version" "delete-project-build-cache" "get-project-deployments" "get-project-history" "get-project-settings" "update-project-build-number" "get-project-environment-variables" "update-project-environment-variables" "get-project-settings-yaml" "update-project-settings-yaml" "get-roles" "add-role" "update-role" "delete-role" "get-role" "join-account" "get-users" "update-user" "get-user-invitations" "invite-user" "cancel-user-invitation" "delete-user" "get-user" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
export def "encrypt-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --plain-value: string # default: ""
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/encrypt" $auth.query)
  let req_body = {"plainValue": $plain_value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get build artifacts
#
# GET /buildjobs/{jobId}/artifacts
# Docs: https://www.appveyor.com/docs/api/samples/download-artifacts-advanced-ps/
# operationId: getBuildArtifacts
export def "get-build-artifacts" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<table<created: string, fileName: string, name: string, size: int, type: string, url: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/buildjobs/{job_id}/artifacts") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Download build artifact
#
# GET /buildjobs/{jobId}/artifacts/{artifactFileName}
# Docs: https://www.appveyor.com/docs/api/samples/download-artifacts-advanced-ps/
# operationId: getBuildArtifact
export def "get-build-artifact" [
  job_id: string
  artifact_file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  if ($artifact_file_name | is-empty) { error make --unspanned { msg: "path parameter 'artifactFileName' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id), artifact_file_name: (encode-path-segment $artifact_file_name)} | format pattern "/buildjobs/{job_id}/artifacts/{artifact_file_name}") $auth.query)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Download build log
#
# GET /buildjobs/{jobId}/log
# Docs: https://www.appveyor.com/docs/api/projects-builds/#download-build-log
# operationId: getBuildLog
export def "get-build-log" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/buildjobs/{job_id}/log") $auth.query)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Start build of branch most recent commit
#
# POST /builds
# Docs: https://www.appveyor.com/docs/api/projects-builds/#start-build-of-branch-most-recent-commit
# operationId: startBuild
export def "start-build" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  account_name: string
  --branch: string
  --commit-id: string
  --environment-variables: record
  project_slug: string
  --pull-request-id: int # Can not be used with `branch` or `commitId`
]: any -> oneof<record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: table<created: string, updated: string, finished: string, jobId: string, name: string, started: string, status: string, allowFailure: bool, artifactsCount: int, compilationErrorsCount: int, compilationMessagesCount: int, compilationWarningsCount: int, failedTestsCount: int, messagesCount: int, osType: string, passedTestsCount: int, testsCount: int>, messageExtended: string, messages: table<category: string, created: string, message: string>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/builds" $auth.query)
  let req_body = {"accountName": $account_name, "branch": $branch, "commitId": $commit_id, "environmentVariables": $environment_variables, "projectSlug": $project_slug, "pullRequestId": $pull_request_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Re-run build
#
# PUT /builds
# Docs: https://www.appveyor.com/docs/api/projects-builds/#re-run-build
# operationId: reRunBuild
export def "re-run-build" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  build_id: int
  --re-run-incomplete: oneof<nothing, bool> # Set `reRunIncomplete` set to `false` (default value) for full build re-run. Set it set to `true` to rerun only failed or cancelled jobs in multijob build.
]: any -> oneof<record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: table<created: string, updated: string, finished: string, jobId: string, name: string, started: string, status: string, allowFailure: bool, artifactsCount: int, compilationErrorsCount: int, compilationMessagesCount: int, compilationWarningsCount: int, failedTestsCount: int, messagesCount: int, osType: string, passedTestsCount: int, testsCount: int>, messageExtended: string, messages: table<category: string, created: string, message: string>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/builds" $auth.query)
  let req_body = {"buildId": $build_id, "reRunIncomplete": $re_run_incomplete} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Cancel build
#
# DELETE /builds/{accountName}/{projectSlug}/{buildVersion}
# Docs: https://www.appveyor.com/docs/api/projects-builds/#cancel-build
# operationId: cancelBuild
export def "cancel-build" [
  account_name: string
  project_slug: string
  build_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'projectSlug' must be non-empty" } }
  if ($build_version | is-empty) { error make --unspanned { msg: "path parameter 'buildVersion' must be non-empty" } }
  let full_url = (build-url $base ({account_name: (encode-path-segment $account_name), project_slug: (encode-path-segment $project_slug), build_version: (encode-path-segment $build_version)} | format pattern "/builds/{account_name}/{project_slug}/{build_version}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get collaborators
#
# GET /collaborators
# Docs: https://www.appveyor.com/docs/api/team/#get-collaborators
# operationId: getCollaborators
export def "get-collaborators" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<table<created: string, updated: string, accountId: int, accountName: string, email: string, fullName: string, isCollaborator: bool, isOwner: bool, pageSize: int, password: string, roleId: int, roleName: string, twoFactorAuthEnabled: bool, userId: int>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collaborators" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update collaborator
#
# PUT /collaborators
# Docs: https://www.appveyor.com/docs/api/team/#update-collaborator
# operationId: updateCollaborator
export def "update-collaborator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  role_id: int
  user_id: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collaborators" $auth.query)
  let req_body = {"roleId": $role_id, "userId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Delete collaborator
#
# DELETE /collaborators/{userId}
# Docs: https://www.appveyor.com/docs/api/team/#delete-collaborator
# operationId: deleteCollaborator
export def "delete-collaborator" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/collaborators/{user_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get collaborator
#
# GET /collaborators/{userId}
# Docs: https://www.appveyor.com/docs/api/team/#get-collaborator
# operationId: getCollaborator
export def "get-collaborator" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<roles: table<created: string, updated: string, isSystem: bool, name: string, roleId: int>, user: record<created: string, updated: string, accountId: int, accountName: string, email: string, fullName: string, isCollaborator: bool, isOwner: bool, pageSize: int, password: string, roleId: int, roleName: string, twoFactorAuthEnabled: bool, userId: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/collaborators/{user_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Start deployment
#
# POST /deployments
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#start-deployment
# operationId: startDeployment
export def "start-deployment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  account_name: string
  --build-job-id: string # Optional job id with artifacts if build contains multiple jobs.
  build_version: string # Build to deploy
  environment_name: string
  --environment-variables: record
  project_slug: string
]: any -> oneof<record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list<record>, messageExtended: string, messages: list<record>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, deploymentId: int, finished: string, started: string, status: string, created: string, updated: string, environment: record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, tags: string>, jobs: table<created: string, updated: string, finished: string, jobId: string, name: string, started: string, status: string, messagesCount: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployments" $auth.query)
  let req_body = {"accountName": $account_name, "buildJobId": $build_job_id, "buildVersion": $build_version, "environmentName": $environment_name, "environmentVariables": $environment_variables, "projectSlug": $project_slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Cancel deployment
#
# PUT /deployments/stop
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#cancel-deployment
# operationId: cancelDeployment
export def "cancel-deployment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  deployment_id: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployments/stop" $auth.query)
  let req_body = {"deploymentId": $deployment_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get deployment
#
# GET /deployments/{deploymentId}
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#get-deployment
# operationId: getDeployment
export def "get-deployment" [
  deployment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<deployment: record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list, messageExtended: string, messages: list, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, deploymentId: int, finished: string, started: string, status: string, created: string, updated: string, environment: record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record, tags: string>, jobs: list<record>>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deploymentId' must be non-empty" } }
  let full_url = (build-url $base ({deployment_id: (encode-path-segment $deployment_id)} | format pattern "/deployments/{deployment_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get environments
#
# GET /environments
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#get-environments
# operationId: getEnvironments
export def "get-environments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<table<deploymentEnvironmentId: int, name: string, provider: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/environments" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add environment
#
# POST /environments
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#add-environment
# operationId: addEnvironment
export def "add-environment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string
  provider: string@provider-completer
  settings: record # shape: {environmentVariables?: list, notifications?: list, providerSettings?: list}
]: any -> oneof<record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record<accessRightDefinitions: list<record>, roleAces: list<record>>, tags: string, environmentAccessKey: string, projects: table<isSelected: bool, name: string, projectId: int>, selectedProjects: list<int>, settings: record<environmentVariables: list<record>, notifications: list<record>, providerSettings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/environments" $auth.query)
  let req_body = {"name": $name, "provider": $provider, "settings": $settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update environment
#
# PUT /environments
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#update-environment
# operationId: updateEnvironment
export def "update-environment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --deployment-environment-id: int
  --name: string
  --provider: string@provider-completer
  --account-id: int
  --projects-mode: int@projects-mode-completer # Project selection mode for deployment environments.
  --security-descriptor: record # shape: {accessRightDefinitions?: list, roleAces?: list}
  --tags: string # Comma-separated list of environment tags for dynamic grouping. Appears that any input is accepted. The returned value only contains case-preserving but insensitive unique values where spaces around "," are removed but otherwise preserved. Empty values and items are allowed.
  --environment-access-key: string
  --projects: list # Projects available for selection in UI. Only present in response from getEnvironmentSettings. — item shape: {isSelected: bool, name: string, projectId: int}
  --selected-projects: list<int> # Project IDs of selected projects
  --settings: record # shape: {environmentVariables?: list, notifications?: list, providerSettings?: list}
]: any -> oneof<record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record<accessRightDefinitions: list<record>, roleAces: list<record>>, tags: string, environmentAccessKey: string, projects: table<isSelected: bool, name: string, projectId: int>, selectedProjects: list<int>, settings: record<environmentVariables: list<record>, notifications: list<record>, providerSettings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/environments" $auth.query)
  let req_body = {"deploymentEnvironmentId": $deployment_environment_id, "name": $name, "provider": $provider, "accountId": $account_id, "projectsMode": $projects_mode, "securityDescriptor": $security_descriptor, "tags": $tags, "environmentAccessKey": $environment_access_key, "projects": $projects, "selectedProjects": $selected_projects, "settings": $settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete environment
#
# DELETE /environments/{deploymentEnvironmentId}
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#delete-environment
# operationId: deleteEnvironment
export def "delete-environment" [
  deployment_environment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deployment_environment_id | is-empty) { error make --unspanned { msg: "path parameter 'deploymentEnvironmentId' must be non-empty" } }
  let full_url = (build-url $base ({deployment_environment_id: (encode-path-segment $deployment_environment_id)} | format pattern "/environments/{deployment_environment_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get environment deployments
#
# GET /environments/{deploymentEnvironmentId}/deployments
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#get-environment-deployments
# operationId: getEnvironmentDeployments
export def "get-environment-deployments" [
  deployment_environment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<deployments: table<build: record, deploymentId: int, finished: string, started: string, status: string, project: record>, environment: record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, tags: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deployment_environment_id | is-empty) { error make --unspanned { msg: "path parameter 'deploymentEnvironmentId' must be non-empty" } }
  let full_url = (build-url $base ({deployment_environment_id: (encode-path-segment $deployment_environment_id)} | format pattern "/environments/{deployment_environment_id}/deployments") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get environment settings
#
# GET /environments/{deploymentEnvironmentId}/settings
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#get-environment-settings
# operationId: getEnvironmentSettings
export def "get-environment-settings" [
  deployment_environment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<environment: record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, tags: string, environmentAccessKey: string, projects: list<record>, selectedProjects: list<int>, settings: record<environmentVariables: list, notifications: list, providerSettings: list>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deployment_environment_id | is-empty) { error make --unspanned { msg: "path parameter 'deploymentEnvironmentId' must be non-empty" } }
  let full_url = (build-url $base ({deployment_environment_id: (encode-path-segment $deployment_environment_id)} | format pattern "/environments/{deployment_environment_id}/settings") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get projects
#
# GET /projects
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-projects
# operationId: getProjects
export def "get-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<table<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add project
#
# POST /projects
# Docs: https://www.appveyor.com/docs/api/projects-builds/#add-project
# operationId: addProject
export def "add-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --repository-authentication: string@repository-authentication-completer
  repository_name: string # URL when repositoryProvider is git, mercurial, subversion username/project when repositoryProvider is gitHub
  --repository-password: string # Required if repositoryAuthentication is credentials (format: password)
  repository_provider: string@repository-provider-completer
  --repository-username: string # Required if repositoryAuthentication is credentials
]: any -> oneof<record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: table<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list, messageExtended: string, messages: list, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list<record>, roleAces: list<record>>, skipBranchesWithoutAppveyorYml: bool, tags: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects" $auth.query)
  let req_body = {"repositoryAuthentication": $repository_authentication, "repositoryName": $repository_name, "repositoryPassword": $repository_password, "repositoryProvider": $repository_provider, "repositoryUsername": $repository_username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update project
#
# PUT /projects
# Docs: https://www.appveyor.com/docs/api/projects-builds/#update-project
# operationId: updateProject
export def "update-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string
  project_id: int
  --always-build-closed-pull-requests: oneof<nothing, bool>
  --current-build-id: int
  --disable-pull-request-webhooks: oneof<nothing, bool>
  --disable-push-webhooks: oneof<nothing, bool>
  --enable-deployment-in-pull-requests: oneof<nothing, bool>
  --enable-secure-variables-in-pull-requests: oneof<nothing, bool>
  --enable-secure-variables-in-pull-requests-from-same-repo: oneof<nothing, bool>
  --is-git-hub-app: oneof<nothing, bool>
  --is-private: oneof<nothing, bool>
  --nu-get-feed: record # shape: {accountId?: int, id?: string, isPrivateProject?: bool, name?: string, nuGetFeedId?: int, projectId?: int, publishingEnabled?: bool}
  --repository-branch: string # Not present in response from addProject.
  repository_name: string
  --repository-scm: string@repository-scm-completer
  --repository-type: string@repository-type-completer
  --rolling-builds: oneof<nothing, bool>
  --rolling-builds-do-not-cancel-running-builds: oneof<nothing, bool>
  --rolling-builds-only-for-pull-requests: oneof<nothing, bool>
  --save-build-cache-in-pull-requests: oneof<nothing, bool>
  --security-descriptor: record # shape: {accessRightDefinitions?: list, roleAces?: list}
  --skip-branches-without-appveyor-yml: oneof<nothing, bool>
  --tags: string # Comma-separated list of project tags for dynamic grouping. Appears that any input is accepted. The returned value only contains case-preserving but insensitive unique values where spaces around "," are removed but otherwise preserved. Empty values and items are allowed.
  --build-priority: int
  configuration: record # shape: {afterBuildScripts?: list, afterDeployScripts?: list, afterTestScripts?: list, artifacts?: list, assemblyFileVersionFormat?: string, assemblyInfoFile?: string, assemblyInformationalVersionFormat?: string, assemblyVersionFormat?: string, beforeBuildScripts?: list, beforeDeployScripts?: list, beforePackageScripts?: list, beforeTestScripts?: list, branchesMode?: "exclude"|"include", buildCloud?: list, buildMode?: "msbuild"|"none"|"script", buildScripts?: list, cacheEntries?: list, cloneDepth?: int, ... (69 more fields)}
  --custom-yml-name: string
  --ignore-appveyor-yml: oneof<nothing, bool>
  --next-build-number: int
  --repository-authentication: string@repository-authentication-completer
  --repository-username: string
  --schedule-crontab-expression: string # Build schedule as an NCrontab Expression. See https://github.com/atifaziz/NCrontab/wiki/Crontab-Expression
  --ssh-public-key: string
  --status-badge-id: string
  version_format: string
  --webhook-id: string
  --webhook-url: string # format: uri
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects" $auth.query)
  let req_body = {"name": $name, "projectId": $project_id, "alwaysBuildClosedPullRequests": $always_build_closed_pull_requests, "currentBuildId": $current_build_id, "disablePullRequestWebhooks": $disable_pull_request_webhooks, "disablePushWebhooks": $disable_push_webhooks, "enableDeploymentInPullRequests": $enable_deployment_in_pull_requests, "enableSecureVariablesInPullRequests": $enable_secure_variables_in_pull_requests, "enableSecureVariablesInPullRequestsFromSameRepo": $enable_secure_variables_in_pull_requests_from_same_repo, "isGitHubApp": $is_git_hub_app, "isPrivate": $is_private, "nuGetFeed": $nu_get_feed, "repositoryBranch": $repository_branch, "repositoryName": $repository_name, "repositoryScm": $repository_scm, "repositoryType": $repository_type, "rollingBuilds": $rolling_builds, "rollingBuildsDoNotCancelRunningBuilds": $rolling_builds_do_not_cancel_running_builds, "rollingBuildsOnlyForPullRequests": $rolling_builds_only_for_pull_requests, "saveBuildCacheInPullRequests": $save_build_cache_in_pull_requests, "securityDescriptor": $security_descriptor, "skipBranchesWithoutAppveyorYml": $skip_branches_without_appveyor_yml, "tags": $tags, "buildPriority": $build_priority, "configuration": $configuration, "customYmlName": $custom_yml_name, "ignoreAppveyorYml": $ignore_appveyor_yml, "nextBuildNumber": $next_build_number, "repositoryAuthentication": $repository_authentication, "repositoryUsername": $repository_username, "scheduleCrontabExpression": $schedule_crontab_expression, "sshPublicKey": $ssh_public_key, "statusBadgeId": $status_badge_id, "versionFormat": $version_format, "webhookId": $webhook_id, "webhookUrl": $webhook_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get status badge image for a project with a public repository
#
# GET /projects/status/{badgeRepoProvider}/{repoAccountName}/{repoSlug}
# Docs: https://www.appveyor.com/docs/status-badges/
# operationId: getPublicProjectStatusBadge
export def "get-public-project-status-badge" [
  badge_repo_provider: string@badge-repo-provider-completer
  repo_account_name: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --branch: string # Repository Branch
  --svg: oneof<nothing, bool> # Return an SVG image instead of PNG? Exclusive with `retina`. (default: false)
  --retina: oneof<nothing, bool> # Return a larger image suitable for retina displays? Exclusive with `svg`. (default: false)
  --passing-text: string # Text to show in badge when build is passing.
  --failing-text: string # Text to show in badge when build is failing.
  --pending-text: string # Text to show in badge when build is pending.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($badge_repo_provider | is-empty) { error make --unspanned { msg: "path parameter 'badgeRepoProvider' must be non-empty" } }
  if ($repo_account_name | is-empty) { error make --unspanned { msg: "path parameter 'repoAccountName' must be non-empty" } }
  if ($repo_slug | is-empty) { error make --unspanned { msg: "path parameter 'repoSlug' must be non-empty" } }
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "svg" $svg "scalar") (serialize-qp "retina" $retina "scalar") (serialize-qp "passingText" $passing_text "scalar") (serialize-qp "failingText" $failing_text "scalar") (serialize-qp "pendingText" $pending_text "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({badge_repo_provider: (encode-path-segment $badge_repo_provider), repo_account_name: (encode-path-segment $repo_account_name), repo_slug: (encode-path-segment $repo_slug)} | format pattern "/projects/status/{badge_repo_provider}/{repo_account_name}/{repo_slug}") $qp $auth.query)
  let accept_val = ($accept | default "image/svg+xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"branch": $branch, "svg": $svg, "retina": $retina, "passingText": $passing_text, "failingText": $failing_text, "pendingText": $pending_text} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get project status badge image
#
# GET /projects/status/{statusBadgeId}
# Docs: https://www.appveyor.com/docs/status-badges/
# operationId: getProjectStatusBadge
export def "get-project-status-badge" [
  status_badge_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --svg: oneof<nothing, bool> # Return an SVG image instead of PNG? Exclusive with `retina`. (default: false)
  --retina: oneof<nothing, bool> # Return a larger image suitable for retina displays? Exclusive with `svg`. (default: false)
  --passing-text: string # Text to show in badge when build is passing.
  --failing-text: string # Text to show in badge when build is failing.
  --pending-text: string # Text to show in badge when build is pending.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($status_badge_id | is-empty) { error make --unspanned { msg: "path parameter 'statusBadgeId' must be non-empty" } }
  let qp = [(serialize-qp "svg" $svg "scalar") (serialize-qp "retina" $retina "scalar") (serialize-qp "passingText" $passing_text "scalar") (serialize-qp "failingText" $failing_text "scalar") (serialize-qp "pendingText" $pending_text "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({status_badge_id: (encode-path-segment $status_badge_id)} | format pattern "/projects/status/{status_badge_id}") $qp $auth.query)
  let accept_val = ($accept | default "image/svg+xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"svg": $svg, "retina": $retina, "passingText": $passing_text, "failingText": $failing_text, "pendingText": $pending_text} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get project branch status badge image
#
# GET /projects/status/{statusBadgeId}/branch/{buildBranch}
# Docs: https://www.appveyor.com/docs/status-badges/
# operationId: getProjectBranchStatusBadge
export def "get-project-branch-status-badge" [
  status_badge_id: string
  build_branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --svg: oneof<nothing, bool> # Return an SVG image instead of PNG? Exclusive with `retina`. (default: false)
  --retina: oneof<nothing, bool> # Return a larger image suitable for retina displays? Exclusive with `svg`. (default: false)
  --passing-text: string # Text to show in badge when build is passing.
  --failing-text: string # Text to show in badge when build is failing.
  --pending-text: string # Text to show in badge when build is pending.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($status_badge_id | is-empty) { error make --unspanned { msg: "path parameter 'statusBadgeId' must be non-empty" } }
  if ($build_branch | is-empty) { error make --unspanned { msg: "path parameter 'buildBranch' must be non-empty" } }
  let qp = [(serialize-qp "svg" $svg "scalar") (serialize-qp "retina" $retina "scalar") (serialize-qp "passingText" $passing_text "scalar") (serialize-qp "failingText" $failing_text "scalar") (serialize-qp "pendingText" $pending_text "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({status_badge_id: (encode-path-segment $status_badge_id), build_branch: (encode-path-segment $build_branch)} | format pattern "/projects/status/{status_badge_id}/branch/{build_branch}") $qp $auth.query)
  let accept_val = ($accept | default "image/svg+xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"svg": $svg, "retina": $retina, "passingText": $passing_text, "failingText": $failing_text, "pendingText": $pending_text} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete project
#
# DELETE /projects/{accountName}/{projectSlug}
# Docs: https://www.appveyor.com/docs/api/projects-builds/#delete-project
# operationId: deleteProject
export def "delete-project" [
  account_name: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'projectSlug' must be non-empty" } }
  let full_url = (build-url $base ({account_name: (encode-path-segment $account_name), project_slug: (encode-path-segment $project_slug)} | format pattern "/projects/{account_name}/{project_slug}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get project last build
#
# GET /projects/{accountName}/{projectSlug}
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-last-build
# operationId: getProjectLastBuild
export def "get-project-last-build" [
  account_name: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list<record>, messageExtended: string, messages: list<record>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'projectSlug' must be non-empty" } }
  let full_url = (build-url $base ({account_name: (encode-path-segment $account_name), project_slug: (encode-path-segment $project_slug)} | format pattern "/projects/{account_name}/{project_slug}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get last successful build artifact
#
# GET /projects/{accountName}/{projectSlug}/artifacts/{artifactFileName}
# Docs: https://www.appveyor.com/docs/packaging-artifacts/#permalink-to-the-last-successful-build-artifact
# operationId: getProjectArtifact
export def "get-project-artifact" [
  account_name: string
  project_slug: string
  artifact_file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch: string # Repository Branch
  --tag: string # A git (or other VCS) tag
  --job: string # Name of the build job.
  --all: oneof<nothing, bool> # Include not only `successful`, but also jobs with `failed`, and `cancelled` status. (default: false)
  --pr: oneof<nothing, bool> # Include PR builds in the search results? `true` - take artifact from PR builds only; `false` - do not look for artifact in PR builds; default/unspecified - look for artifact in both PR an non-PR builds.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'projectSlug' must be non-empty" } }
  if ($artifact_file_name | is-empty) { error make --unspanned { msg: "path parameter 'artifactFileName' must be non-empty" } }
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "job" $job "scalar") (serialize-qp "all" $all "scalar") (serialize-qp "pr" $pr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_name: (encode-path-segment $account_name), project_slug: (encode-path-segment $project_slug), artifact_file_name: (encode-path-segment $artifact_file_name)} | format pattern "/projects/{account_name}/{project_slug}/artifacts/{artifact_file_name}") $qp $auth.query)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"branch": $branch, "tag": $tag, "job": $job, "all": $all, "pr": $pr} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get project last branch build
#
# GET /projects/{accountName}/{projectSlug}/branch/{buildBranch}
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-last-branch-build
# operationId: getProjectLastBuildBranch
export def "get-project-last-build-branch" [
  account_name: string
  project_slug: string
  build_branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list<record>, messageExtended: string, messages: list<record>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'projectSlug' must be non-empty" } }
  if ($build_branch | is-empty) { error make --unspanned { msg: "path parameter 'buildBranch' must be non-empty" } }
  let full_url = (build-url $base ({account_name: (encode-path-segment $account_name), project_slug: (encode-path-segment $project_slug), build_branch: (encode-path-segment $build_branch)} | format pattern "/projects/{account_name}/{project_slug}/branch/{build_branch}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get project build by version
#
# GET /projects/{accountName}/{projectSlug}/build/{buildVersion}
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-build-by-version
# operationId: getProjectBuildByVersion
export def "get-project-build-by-version" [
  account_name: string
  project_slug: string
  build_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list<record>, messageExtended: string, messages: list<record>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'projectSlug' must be non-empty" } }
  if ($build_version | is-empty) { error make --unspanned { msg: "path parameter 'buildVersion' must be non-empty" } }
  let full_url = (build-url $base ({account_name: (encode-path-segment $account_name), project_slug: (encode-path-segment $project_slug), build_version: (encode-path-segment $build_version)} | format pattern "/projects/{account_name}/{project_slug}/build/{build_version}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete project build cache
#
# DELETE /projects/{accountName}/{projectSlug}/buildcache
# Docs: https://www.appveyor.com/docs/api/projects-builds/#delete-project-build-cache
# operationId: deleteProjectBuildCache
export def "delete-project-build-cache" [
  account_name: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'projectSlug' must be non-empty" } }
  let full_url = (build-url $base ({account_name: (encode-path-segment $account_name), project_slug: (encode-path-segment $project_slug)} | format pattern "/projects/{account_name}/{project_slug}/buildcache") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get project deployments
#
# GET /projects/{accountName}/{projectSlug}/deployments
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-deployments
# operationId: getProjectDeployments
export def "get-project-deployments" [
  account_name: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --records-number: int # Number of results to include in the response. getProjectDeployments is documented to have a maximum of 20. It currently returns 500 Internal Server Error for recordsNumber <= 5. In the past it has returned 500 Internal Server Error for many different values which did not match the value used by the ci.appveyor.com web interface at the time. As of 2018-09-08, the value used by the web interface is 10. (required)
]: nothing -> oneof<record<deployments: table<build: record, deploymentId: int, finished: string, started: string, status: string, environment: record>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'projectSlug' must be non-empty" } }
  if ($records_number == null) { error make --unspanned { msg: "required query parameter 'recordsNumber' missing: pass --records-number" } }
  let qp = [(serialize-qp "recordsNumber" $records_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_name: (encode-path-segment $account_name), project_slug: (encode-path-segment $project_slug)} | format pattern "/projects/{account_name}/{project_slug}/deployments") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"recordsNumber": $records_number} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get project history
#
# GET /projects/{accountName}/{projectSlug}/history
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-history
# operationId: getProjectHistory
export def "get-project-history" [
  account_name: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --records-number: int # Number of results to include in the response. getProjectDeployments is documented to have a maximum of 20. It currently returns 500 Internal Server Error for recordsNumber <= 5. In the past it has returned 500 Internal Server Error for many different values which did not match the value used by the ci.appveyor.com web interface at the time. As of 2018-09-08, the value used by the web interface is 10. (required)
  --start-build-id: int # Maximum `buildId` to include in the results (exclusive).
  --branch: string # Repository Branch
]: nothing -> oneof<record<builds: table<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list, messageExtended: string, messages: list, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'projectSlug' must be non-empty" } }
  if ($records_number == null) { error make --unspanned { msg: "required query parameter 'recordsNumber' missing: pass --records-number" } }
  let qp = [(serialize-qp "recordsNumber" $records_number "scalar") (serialize-qp "startBuildId" $start_build_id "scalar") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_name: (encode-path-segment $account_name), project_slug: (encode-path-segment $project_slug)} | format pattern "/projects/{account_name}/{project_slug}/history") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"recordsNumber": $records_number, "startBuildId": $start_build_id, "branch": $branch} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get project settings
#
# GET /projects/{accountName}/{projectSlug}/settings
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-settings
# operationId: getProjectSettings
export def "get-project-settings" [
  account_name: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<buildClouds: table<value: string>, defaultImageName: string, images: table<buildCloudName: string, buildWorkerImageId: int, name: string, osType: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>, settings: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string, buildPriority: int, configuration: record<afterBuildScripts: list, afterDeployScripts: list, afterTestScripts: list, artifacts: list, assemblyFileVersionFormat: string, assemblyInfoFile: string, assemblyInformationalVersionFormat: string, assemblyVersionFormat: string, beforeBuildScripts: list, beforeDeployScripts: list, beforePackageScripts: list, beforeTestScripts: list, branchesMode: string, buildCloud: list, buildMode: string, buildScripts: list, cacheEntries: list, cloneDepth: int, cloneFolder: string, cloneScripts: list, configuration: list, configureNuGetAccountSource: bool, configureNuGetProjectSource: bool, deployMode: string, deployScripts: list, deployments: list, disableNuGetPublishForOctopusPackages: bool, disableNuGetPublishOnPullRequests: bool, doNotIncrementBuildNumberOnPullRequests: bool, dotnetCsprojAssemblyVersionFormat: string, dotnetCsprojFile: string, dotnetCsprojFileVersionFormat: string, dotnetCsprojInformationalVersionFormat: string, dotnetCsprojPackageVersionFormat: string, dotnetCsprojVersionFormat: string, environmentVariables: list, environmentVariablesMatrix: list, excludeBranches: list, forceHttpsClone: bool, hostsEntries: list, hotFixScripts: list, includeBranches: list, includeNuGetReferences: bool, initScripts: list, installScripts: list, matrixAllowFailures: list, matrixExcept: list, matrixExclude: list, matrixFastFinish: bool, matrixOnly: list, maxJobs: int, msBuildInParallel: bool, msBuildProjectFileName: string, msBuildVerbosity: string, notifications: list, onBuildErrorScripts: list, onBuildFinishScripts: list, onBuildSuccessScripts: list, onlyCommitsFiles: list, operatingSystem: list, packageAspNetCoreProjects: bool, packageAzureCloudServiceProjects: bool, packageDotnetConsoleProjects: bool, packageNuGetProjects: bool, packageNuGetSymbols: bool, packageWebApplicationProjects: bool, packageWebApplicationProjectsBeanstalk: bool, packageWebApplicationProjectsOctopus: bool, packageWebApplicationProjectsXCopy: bool, patchAssemblyInfo: bool, patchDotnetCsproj: bool, platform: list, services: list, shallowClone: bool, skipBranchWithPullRequests: bool, skipCommitsFiles: list, skipNonTags: bool, skipTags: bool, stacks: list, testAssemblies: list, testCategories: list, testCategoriesMatrix: list, testCategoriesMode: string, testMode: string, testScripts: list, xamarinRegisterAndroidProduct: bool, xamarinRegisterIosProduct: bool>, customYmlName: string, ignoreAppveyorYml: bool, nextBuildNumber: int, repositoryAuthentication: string, repositoryUsername: string, scheduleCrontabExpression: string, sshPublicKey: string, statusBadgeId: string, versionFormat: string, webhookId: string, webhookUrl: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'projectSlug' must be non-empty" } }
  let full_url = (build-url $base ({account_name: (encode-path-segment $account_name), project_slug: (encode-path-segment $project_slug)} | format pattern "/projects/{account_name}/{project_slug}/settings") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update project build number
#
# PUT /projects/{accountName}/{projectSlug}/settings/build-number
# Docs: https://www.appveyor.com/docs/api/projects-builds/#update-project-build-number
# operationId: updateProjectBuildNumber
export def "update-project-build-number" [
  account_name: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  next_build_number: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'projectSlug' must be non-empty" } }
  let full_url = (build-url $base ({account_name: (encode-path-segment $account_name), project_slug: (encode-path-segment $project_slug)} | format pattern "/projects/{account_name}/{project_slug}/settings/build-number") $auth.query)
  let req_body = {"nextBuildNumber": $next_build_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get project environment variables
#
# GET /projects/{accountName}/{projectSlug}/settings/environment-variables
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-environment-variables
# operationId: getProjectEnvironmentVariables
export def "get-project-environment-variables" [
  account_name: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<table<name: string, value: record<isEncrypted: bool, value: string>>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'projectSlug' must be non-empty" } }
  let full_url = (build-url $base ({account_name: (encode-path-segment $account_name), project_slug: (encode-path-segment $project_slug)} | format pattern "/projects/{account_name}/{project_slug}/settings/environment-variables") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update project environment variables
#
# PUT /projects/{accountName}/{projectSlug}/settings/environment-variables
# Docs: https://www.appveyor.com/docs/api/projects-builds/#update-project-environment-variables
# operationId: updateProjectEnvironmentVariables
export def "update-project-environment-variables" [
  account_name: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'projectSlug' must be non-empty" } }
  let full_url = (build-url $base ({account_name: (encode-path-segment $account_name), project_slug: (encode-path-segment $project_slug)} | format pattern "/projects/{account_name}/{project_slug}/settings/environment-variables") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get project settings in YAML
#
# GET /projects/{accountName}/{projectSlug}/settings/yaml
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-settings-in-yaml
# operationId: getProjectSettingsYaml
export def "get-project-settings-yaml" [
  account_name: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'projectSlug' must be non-empty" } }
  let full_url = (build-url $base ({account_name: (encode-path-segment $account_name), project_slug: (encode-path-segment $project_slug)} | format pattern "/projects/{account_name}/{project_slug}/settings/yaml") $auth.query)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update project settings in YAML
#
# PUT /projects/{accountName}/{projectSlug}/settings/yaml
# Docs: https://www.appveyor.com/docs/api/projects-builds/#update-project-settings-in-yaml
# operationId: updateProjectSettingsYaml
export def "update-project-settings-yaml" [
  account_name: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'projectSlug' must be non-empty" } }
  let full_url = (build-url $base ({account_name: (encode-path-segment $account_name), project_slug: (encode-path-segment $project_slug)} | format pattern "/projects/{account_name}/{project_slug}/settings/yaml") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "text/plain"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get roles
#
# GET /roles
# Docs: https://www.appveyor.com/docs/api/team/#get-roles
# operationId: getRoles
export def "get-roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<table<created: string, updated: string, isSystem: bool, name: string, roleId: int>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add role
#
# POST /roles
# Docs: https://www.appveyor.com/docs/api/team/#add-role
# operationId: addRole
export def "add-role" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string
]: any -> oneof<record<created: string, updated: string, isSystem: bool, name: string, roleId: int, groups: table<name: string, permissions: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update role
#
# PUT /roles
# Docs: https://www.appveyor.com/docs/api/team/#update-role
# operationId: updateRole
export def "update-role" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string
  role_id: int
  --groups: list # item shape: {name: "Account"|"BuildEnvironment"|"Deny"|"Environments"|"Projects"|"Roles"|"User"|"Users", permissions: list}
]: any -> oneof<record<created: string, updated: string, isSystem: bool, name: string, roleId: int, groups: table<name: string, permissions: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles" $auth.query)
  let req_body = {"name": $name, "roleId": $role_id, "groups": $groups} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete role
#
# DELETE /roles/{roleId}
# Docs: https://www.appveyor.com/docs/api/team/#delete-role
# operationId: deleteRole
export def "delete-role" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({role_id: (encode-path-segment $role_id)} | format pattern "/roles/{role_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get role
#
# GET /roles/{roleId}
# Docs: https://www.appveyor.com/docs/api/team/#get-role
# operationId: getRole
export def "get-role" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<created: string, updated: string, isSystem: bool, name: string, roleId: int, groups: table<name: string, permissions: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({role_id: (encode-path-segment $role_id)} | format pattern "/roles/{role_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Join Account
#
# PUT /user/join-account
# operationId: joinAccount
export def "join-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  invitation_id: string
]: any -> oneof<record<accounts: table<created: string, updated: string, accountId: int, allowCustomBuildEnvironment: bool, blocked: bool, featureFlags: string, gitHubPlan: bool, gitHubPlanOrg: string, isCollaborator: bool, isEnterprisePlan: bool, isOwner: bool, manualPayments: bool, name: string, permissions: list, planEnd: string, planId: string, planStart: string, planStatus: string, roleId: int, roleName: string, timeZoneId: string, unpaid: bool, unverified: bool>, setupRequired: bool, twoFactorAuthRequired: bool, user: record<created: string, updated: string, bitBucketUsername: string, email: string, fullName: string, gitHubUsername: string, gitLabUserId: string, gravatarHash: string, pageSize: int, twoFactorAuthEnabled: bool, userId: int, vsoUsername: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/join-account" $auth.query)
  let req_body = {"invitationId": $invitation_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get users
#
# GET /users
# Docs: https://www.appveyor.com/docs/api/team/#get-users
# operationId: getUsers
export def "get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<table<created: string, updated: string, accountId: int, accountName: string, email: string, fullName: string, isCollaborator: bool, isOwner: bool, pageSize: int, password: string, roleId: int, roleName: string, twoFactorAuthEnabled: bool, userId: int>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update user
#
# PUT /users
# Docs: https://www.appveyor.com/docs/api/team/#update-user
# operationId: updateUser
export def "update-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  email: string # format: email
  full_name: string
  --password: string # format: password
  --role-id: int
  --two-factor-auth-enabled: oneof<nothing, bool>
  --user-id: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users" $auth.query)
  let req_body = {"email": $email, "fullName": $full_name, "password": $password, "roleId": $role_id, "twoFactorAuthEnabled": $two_factor_auth_enabled, "userId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get user invitations
#
# GET /users/invitations
# operationId: getUserInvitations
export def "get-user-invitations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<table<accountId: int, accountName: string, created: string, email: string, roleId: int, roleName: string, userInvitationId: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/invitations" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Invite user
#
# POST /users/invitations
# operationId: inviteUser
export def "invite-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  email: string # format: email
  role_id: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/invitations" $auth.query)
  let req_body = {"email": $email, "roleId": $role_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Cancel user invitation
#
# DELETE /users/invitations/{userInvitationId}
# operationId: cancelUserInvitation
export def "cancel-user-invitation" [
  user_invitation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_invitation_id | is-empty) { error make --unspanned { msg: "path parameter 'userInvitationId' must be non-empty" } }
  let full_url = (build-url $base ({user_invitation_id: (encode-path-segment $user_invitation_id)} | format pattern "/users/invitations/{user_invitation_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Delete user
#
# DELETE /users/{userId}
# Docs: https://www.appveyor.com/docs/api/team/#delete-user
# operationId: deleteUser
export def "delete-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get user
#
# GET /users/{userId}
# Docs: https://www.appveyor.com/docs/api/team/#get-user
# operationId: getUser
export def "get-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<roles: table<created: string, updated: string, isSystem: bool, name: string, roleId: int>, user: record<created: string, updated: string, accountId: int, accountName: string, email: string, fullName: string, isCollaborator: bool, isOwner: bool, pageSize: int, password: string, roleId: int, roleName: string, twoFactorAuthEnabled: bool, userId: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
