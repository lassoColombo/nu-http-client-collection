# Auto-generated client for Snyk API vREST
# Source: https://api.snyk.io/rest/openapi/2025-01-09
# Auth: --token flag or $env.SNYK_API_TOKEN

const BASE_URL = "https://api.snyk.io/rest"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SNYK_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://api.snyk.io/rest"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-by-completer [] { ["repository" "tag" "version"] }
def sort-direction-completer [] { ["ASC" "DESC"] }
def type-completer [] { ["image" "package" "repository"] }
def sort-order-completer [] { ["ASC" "DESC"] }
def meta-count-completer [] { ["only" "with"] }
def canonical-completer [] { ["none" "only" "with"] }
def sort-completer [] { ["-issues" "-snapshot_created_at" "issues" "snapshot_created_at"] }
def scan-itemtype-completer [] { ["environment" "project"] }
def type-completer-1 [] { ["cloud" "code" "config" "custom" "license" "package_vulnerability" "secrets"] }
def sort-by-completer-1 [] { ["email" "login_method" "role_name" "user_display_name" "username"] }
def expand-completer [] { ["count"] }
def content-source-completer [] { ["cache" "source-preview"] }
def kind-completer [] { ["aws" "azure" "cli" "google" "scm" "tfc"] }
def status-completer [] { ["error" "in_progress" "null" "queued" "success"] }
def sort-completer-1 [] { ["issues" "name" "projectsCount"] }
def direction-completer [] { ["ASC" "DESC"] }
def sort-completer-2 [] { ["imported" "issues" "last_tested_at"] }
def platform-completer [] { ["aix/ppc64" "android/386" "android/amd64" "android/arm" "android/arm/v5" "android/arm/v6" "android/arm/v7" "android/arm64" "android/arm64/v8" "darwin/amd64" "darwin/arm" "darwin/arm/v5" "darwin/arm/v6" "darwin/arm/v7" "darwin/arm64" "darwin/arm64/v8" "dragonfly/amd64" "freebsd/386" "freebsd/amd64" "freebsd/arm" "freebsd/arm/v5" "freebsd/arm/v6" "freebsd/arm/v7" "illumos/amd64" "ios/arm64" "ios/arm64/v8" "js/wasm" "linux/386" "linux/amd64" "linux/arm" "linux/arm/v5" "linux/arm/v6" "linux/arm/v7" "linux/arm64" "linux/arm64/v8" "linux/loong64" "linux/mips" "linux/mips64" "linux/mips64le" "linux/mipsle" "linux/ppc64" "linux/ppc64le" "linux/riscv64" "linux/s390x" "linux/x86_64" "netbsd/386" "netbsd/amd64" "netbsd/arm" "netbsd/arm/v5" "netbsd/arm/v6" "netbsd/arm/v7" "openbsd/386" "openbsd/amd64" "openbsd/arm" "openbsd/arm/v5" "openbsd/arm/v6" "openbsd/arm/v7" "openbsd/arm64" "openbsd/arm64/v8" "plan9/386" "plan9/amd64" "plan9/arm" "plan9/arm/v5" "plan9/arm/v6" "plan9/arm/v7" "solaris/amd64" "windows/386" "windows/amd64" "windows/arm" "windows/arm/v5" "windows/arm/v6" "windows/arm/v7" "windows/arm64" "windows/arm64/v8"] }
def type-completer-2 [] { ["learning_path" "lesson"] }
def status-completer-1 [] { ["completed" "inProgress"] }
def sort-by-completer-2 [] { ["email" "login_method" "role" "user_display_name" "username"] }
def order-by-completer [] { ["created" "expires" "ignore-type" "requested-by"] }
def order-direction-completer [] { ["asc" "desc"] }
def meta-count-completer-1 [] { ["only"] }
def format-completer [] { ["cyclonedx1.4+json" "cyclonedx1.4+xml" "cyclonedx1.5+json" "cyclonedx1.5+xml" "cyclonedx1.6+json" "cyclonedx1.6+xml" "spdx2.3+json"] }
def accept-completer [] { ["application/json" "application/vnd.api+json" "application/vnd.cyclonedx+json" "application/vnd.cyclonedx+xml"] }
def accept-completer-1 [] { ["application/json" "application/vnd.api+json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "custom-base-images list" } } | get name | first)
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

# Get a custom base image collection
#
# GET /custom_base_images
# operationId: getCustomBaseImages
export def "custom-base-images list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --project-id: string # The ID of the container project that the custom base image is based off of. (format: uuid)
  --org-id: string # The organization ID of the custom base image (format: uuid)
  --group-id: string # The group ID of the custom base image (format: uuid)
  --repository: string # The image repository
  --tag: string # The image tag
  --include-in-recommendations: string@bool-completer # Whether this image should be recommended as a base image upgrade
  --sort-by: string@sort-by-completer # Which column to sort by.  If sorting by version, the versioning schema is used.
  --sort-direction: string@sort-direction-completer # Which direction to sort (default: ASC)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "org_id" $org_id "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "include_in_recommendations" $include_in_recommendations "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_base_images" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Custom Base Image from an existing container project
#
# POST /custom_base_images
# operationId: createCustomBaseImage
export def "custom-base-images createCustomBaseImage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_base_images" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete a custom base image
#
# DELETE /custom_base_images/{custombaseimage_id}
# operationId: deleteCustomBaseImage
export def "custom-base-images delete" [
  custombaseimage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_base_images/($custombaseimage_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a custom base image
#
# GET /custom_base_images/{custombaseimage_id}
# operationId: getCustomBaseImage
export def "custom-base-images get" [
  custombaseimage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_base_images/($custombaseimage_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a custom base image
#
# PATCH /custom_base_images/{custombaseimage_id}
# operationId: updateCustomBaseImage
export def "custom-base-images updateCustomBaseImage" [
  custombaseimage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_base_images/($custombaseimage_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get all groups (Early Access)
#
# GET /groups
# operationId: listGroups
export def "groups listGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Group (Early Access)
#
# GET /groups/{group_id}
# operationId: getGroup
export def "groups get" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of Snyk Apps installed for a Group
#
# GET /groups/{group_id}/apps/installs
# operationId: getAppInstallsForGroup
export def "groups-apps-installs get" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: list # Expand relationships.
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv") (serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/apps/installs" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Install a Snyk App for a Group
#
# POST /groups/{group_id}/apps/installs
# operationId: createGroupAppInstall
export def "groups-apps-installs createGroupAppInstall" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/apps/installs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Revoke app authorization for a Snyk group with install ID
#
# DELETE /groups/{group_id}/apps/installs/{install_id}
# operationId: deleteGroupAppInstallById
export def "groups-apps-installs delete" [
  group_id: string
  install_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/apps/installs/($install_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Manage client secret for non-interactive Snyk App installations
#
# POST /groups/{group_id}/apps/installs/{install_id}/secrets
# operationId: updateGroupAppInstallSecret
export def "groups-apps-installs-secrets updateGroupAppInstallSecret" [
  group_id: string
  install_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/apps/installs/($install_id)/secrets" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# List Assets with filters (Early Access)
#
# POST /groups/{group_id}/assets/search
# operationId: listAssets
# --query shape: {attributes: record}
export def "groups-assets-search listAssets" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body-query: record # shape: {attributes: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/assets/search" $qp)
  let body = {query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Asset by its ID (Early Access)
#
# GET /groups/{group_id}/assets/{asset_id}
# operationId: getAsset
export def "groups-assets get" [
  asset_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/assets/($asset_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List related assets with pagination (Early Access)
#
# GET /groups/{group_id}/assets/{asset_id}/relationships/assets
# operationId: listRelatedAssets
export def "groups-assets-relationships-assets listRelatedAssets" [
  group_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --starting-after: string # Return records after the record identified by cursor position starting_after
  --ending-before: string # Return records before the record identified by cursor position ending_before
  --limit: float # Number of records to return (default: 10)
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --type: string@type-completer # Filter by asset type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/assets/($asset_id)/relationships/assets" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List asset projects with pagination (Early Access)
#
# GET /groups/{group_id}/assets/{asset_id}/relationships/projects
# operationId: listAssetProjects
export def "groups-assets-relationships-projects listAssetProjects" [
  group_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --starting-after: string # Return records after the record identified by cursor position starting_after
  --ending-before: string # Return records before the record identified by cursor position ending_before
  --limit: float # Number of records to return (default: 10)
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/assets/($asset_id)/relationships/projects" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Group audit logs.
#
# GET /groups/{group_id}/audit_logs/search
# operationId: listGroupAuditLogs
export def "groups-audit-logs-search listGroupAuditLogs" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --cursor: string # The ID for the next page of results.
  --qp-from: string # The start date (inclusive) of the audit logs search. If not specified, the start of yesterday is used. Dates should be formatted as RFC3339, e.g. 2024-01-02T16:30:00Z.  (format: date-time)
  --qp-to: string # The end date (exclusive) of the audit logs search. Dates should be formatted as RFC3339, e.g. 2024-01-02T16:30:00Z.  (format: date-time)
  --size: int # Number of results to return per page. (format: int32, default: 100, e.g. 10)
  --sort-order: string@sort-order-completer # Order in which results are returned. (default: DESC, e.g. ASC)
  --user-id: string # Filter logs by user ID. (format: uuid, e.g. 0d3728ec-eebf-484d-9907-ba238019f10b)
  --project-id: string # Filter logs by project ID. (format: uuid, e.g. 0d3728ec-eebf-484d-9907-ba238019f10b)
  --events: list # Filter logs by event types, cannot be used in conjunction with exclude_events parameter.
  --exclude-events: list # Exclude event types from results, cannot be used in conjunctions with events parameter.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "events" $events "multi") (serialize-qp "exclude_events" $exclude_events "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/audit_logs/search" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start an export
#
# POST /groups/{group_id}/export
# operationId: createGroupExport
export def "groups-export createGroupExport" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --include-deleted: string # Optional parameter to include deleted issues in results
  --include-deactivated: string # Optional parameter to include disabled issues in results
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "include_deleted" $include_deleted "scalar") (serialize-qp "include_deactivated" $include_deactivated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/export" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get export results
#
# GET /groups/{group_id}/export/{export_id}
# operationId: getGroupExport
export def "groups-export get" [
  group_id: string
  export_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/export/($export_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or search all assets (synchronous) - Group scope (Early Access)
#
# GET /groups/{group_id}/inventory/assets
# operationId: listAssetsGroup
export def "groups-inventory-assets listAssetsGroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --filter: string # RSQL filter expression for filtering results. See schema for full documentation. (e.g. type==container_images;created_at>2024-01-01)
  --qp-sort: string # Comma-separated sort fields. Prefix with `-` for descending order. (e.g. -created_at)
  --limit: int # Number of results to return per page (default: 10)
  --starting-after: string # Cursor for fetching the next page of results
  --ending-before: string # Cursor for fetching the previous page of results
  --qp-fields: record # Sparse fieldsets allow clients to request only specific fields for a given resource type. Use the format `fields[<type>]=field1,field2` where `<type>` is the JSON:API resource type.  **Container image fields** (use with `fields[container_images]`): - `class` - Classification of the asset - `registry` - Container registry hostname - `repository` - Repository path - `config_digest` - Image config digest - `distribution_digests` - Distribution digests (manifest/index pairs) - `image_tags` - Distinct image tags across all discovery sources - `built_at` - When the image was built - `size_bytes` - Size of the image in bytes - `author` - Image author - `architecture` - CPU architecture - `os` - Operating system - `variant` - CPU architecture variant - `os_version` - Operating system version - `os_features` - OS features - `config` - Image runtime configuration (OCI config) - `root_fs` - Root filesystem information - `history` - Image build history - `inferred_base_images` - Inferred base images - `teams` - Teams associated with the asset - `labels` - Labels associated with the asset - `tags` - Key-value tags for the asset - `risk_score` - Risk score for the asset - `test_surfaces` - Test surfaces for the asset - `issues` - Issue counts by severity - `created_at` - When the asset was created - `updated_at` - When the asset was last updated - `last_scan` - When the asset was last scanned - `scan_engines` - Scan engines applied to the asset  Note: `type` and `id` are always included regardless of field selection.  (e.g. {container_images: registry,repository,config_digest})
  --meta-count: string@meta-count-completer # Provide summary count in the response meta object when requested. When `with` is provided, the count will be included in the response meta object. When `only` is provided, the count will be included in the response meta object and no data will be returned.  (e.g. with)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "fields" $qp_fields "deepObject") (serialize-qp "meta_count" $meta_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/inventory/assets" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk update asset attributes - Group scope (Early Access)
#
# PATCH /groups/{group_id}/inventory/assets
# operationId: updateAssetsBulkGroup
export def "groups-inventory-assets updateAssetsBulkGroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/inventory/assets" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get available filter fields - Group scope (Early Access)
#
# GET /groups/{group_id}/inventory/assets/filters
# operationId: getFilterFieldsGroup
export def "groups-inventory-assets-filters get" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --asset-types: string # Comma-separated list of asset types to filter the available filter fields (e.g. container_images)
  --limit: int # Number of results to return (default: 10)
  --starting-after: string # Cursor for fetching the next page of results
  --ending-before: string # Cursor for fetching the previous page of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "asset_types" $asset_types "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/inventory/assets/filters" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get filter value suggestions (autocomplete) - Group scope (Early Access)
#
# GET /groups/{group_id}/inventory/assets/filters/{filter_id}/values
# operationId: getFilterValuesGroup
export def "groups-inventory-assets-filters-values get" [
  group_id: string
  filter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --q: string # Full text search term to filter the list of values. If keys_only is true, this will filter the keys of the object filter values. If key is provided, this will filter the value for the specific key of the object filter values. (e.g. prod)
  --limit: int # Number of results to return (default: 10)
  --starting-after: string # Cursor for fetching the next page of results
  --ending-before: string # Cursor for fetching the previous page of results
  --keys-only: string@bool-completer # Return only the keys of the object filter values
  --key: string # Return only the value for a specific key of the object filter values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "keys_only" $keys_only "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/inventory/assets/filters/($filter_id)/values" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get available group fields - Group scope (Early Access)
#
# GET /groups/{group_id}/inventory/assets/groups
# operationId: getGroupFieldsGroup
export def "groups-inventory-assets-groups get" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --asset-types: string # Comma-separated list of asset types to filter group fields
  --limit: int # Maximum number of results to return (default: 10)
  --starting-after: string # Cursor for forward pagination
  --ending-before: string # Cursor for backward pagination
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "asset_types" $asset_types "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/inventory/assets/groups" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get group value aggregation - Group scope (Early Access)
#
# GET /groups/{group_id}/inventory/assets/groups/{group_field_id}/values
# operationId: getGroupValuesGroup
export def "groups-inventory-assets-groups-values get" [
  group_id: string
  group_field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --asset-types: string # Comma-separated list of asset types to filter the aggregation (e.g. container_images)
  --filter: string # RSQL filter expression for filtering which assets are included in aggregation. Supports the same syntax as the main search filter including full text search with the `q` field. See the RsqlFilterString schema for complete documentation.  (e.g. type==container_images;created_at>2024-01-01)
  --qp-sort: string # Comma-separated sort fields for group values. Prefix with `-` for descending order. Multiple sort fields are supported (e.g., `-issues,count`). Defaults to `created_at` (ascending) when not specified. Results are always tie-broken by `value` for deterministic ordering.  Available sort fields:   - `value` - Sort by the group value string (alphabetical)   - `count` - Sort by the number of assets in each group   - `created_at` - Sort by the aggregated created_at timestamp   - `last_seen_at` - Sort by the aggregated last_seen_at timestamp   - `updated_at` - Sort by the aggregated updated_at timestamp   - `risk_score` - Sort by the aggregated risk score   - `built_at` - Sort by the aggregated container image build timestamp   - `issues` - Sort by issue severity (critical → high → medium → low)  (e.g. -count)
  --limit: int # Maximum number of group values to return (default: 10)
  --starting-after: string # Cursor for forward pagination
  --ending-before: string # Cursor for backward pagination
  --meta-fields: list # Meta fields to include in the response. Multiple fields can be specified.  Available fields:   - `count` - Number of assets with this value   - `created_at` - Aggregated asset creation timestamp (default aggregation: last)   - `last_seen_at` - Aggregated last_seen_at timestamp (default aggregation: last)   - `updated_at` - Aggregated updated_at timestamp (default aggregation: last)   - `risk_score` - Aggregated risk score from discovery sources (default aggregation: last)   - `issues` - Aggregated issue counts (critical, high, medium, low, total) (default aggregation: last)   - `labels` - Labels across assets (default aggregation: last)   - `tags` - Tags across assets (default aggregation: last)   - `built_at` - Aggregated container image build timestamp (default aggregation: last)   - `all` - Include all available meta fields  All fields default to the `last` aggregation function, which returns the value from the asset with the most recent updated_at in the group. Use the `aggregate` parameter to override the aggregation function per field.  If not specified, the meta object is not included in the response.  Note: Requesting meta fields may impact response time as aggregations require additional computation.  (e.g. [count, risk_score, issues, labels])
  --aggregate: record # Per-field aggregate function override for meta fields. All fields default to `last` when not specified. `max`/`min` compute the SQL MAX/MIN across all assets in the group (scalar fields only). `first`/`last` returns the value from the single asset with the earliest/latest updated_at in the group (all field types). `sum` computes the total across all assets (numeric fields, issues, labels, tags).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "asset_types" $asset_types "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "meta_fields" $meta_fields "csv") (serialize-qp "aggregate" $aggregate "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/inventory/assets/groups/($group_field_id)/values" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an asset search (asynchronous) - Group scope (Early Access)
#
# POST /groups/{group_id}/inventory/assets/searches
# operationId: createAssetSearchGroup
export def "groups-inventory-assets-searches createAssetSearchGroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/inventory/assets/searches" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Retrieve asset search results (asynchronous) - Group scope (Early Access)
#
# GET /groups/{group_id}/inventory/assets/searches/{search_id}/results
# operationId: getAssetSearchResultsGroup
export def "groups-inventory-assets-searches-results get" [
  group_id: string
  search_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --qp-sort: string # Sort order for results (e.g., -created_at for descending)
  --limit: int # Maximum number of results to return (default: 10)
  --starting-after: string # Cursor for forward pagination
  --ending-before: string # Cursor for backward pagination
  --qp-fields: record # Sparse fieldsets allow clients to request only specific fields for a given resource type. Use the format `fields[<type>]=field1,field2` where `<type>` is the JSON:API resource type.  **Container image fields** (use with `fields[container_images]`): - `class` - Classification of the asset - `registry` - Container registry hostname - `repository` - Repository path - `config_digest` - Image config digest - `distribution_digests` - Distribution digests (manifest/index pairs) - `image_tags` - Distinct image tags across all discovery sources - `built_at` - When the image was built - `size_bytes` - Size of the image in bytes - `author` - Image author - `architecture` - CPU architecture - `os` - Operating system - `variant` - CPU architecture variant - `os_version` - Operating system version - `os_features` - OS features - `config` - Image runtime configuration (OCI config) - `root_fs` - Root filesystem information - `history` - Image build history - `inferred_base_images` - Inferred base images - `teams` - Teams associated with the asset - `labels` - Labels associated with the asset - `tags` - Key-value tags for the asset - `risk_score` - Risk score for the asset - `test_surfaces` - Test surfaces for the asset - `issues` - Issue counts by severity - `created_at` - When the asset was created - `updated_at` - When the asset was last updated - `last_scan` - When the asset was last scanned - `scan_engines` - Scan engines applied to the asset  Note: `type` and `id` are always included regardless of field selection.  (e.g. {container_images: registry,repository,config_digest})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "fields" $qp_fields "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/inventory/assets/searches/($search_id)/results" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single asset by ID - Group scope (Early Access)
#
# GET /groups/{group_id}/inventory/assets/{asset_id}
# operationId: getAssetGroup
export def "groups-inventory-assets get" [
  group_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --qp-fields: record # Sparse fieldsets allow clients to request only specific fields for a given resource type. Use the format `fields[<type>]=field1,field2` where `<type>` is the JSON:API resource type.  **Container image fields** (use with `fields[container_images]`): - `class` - Classification of the asset - `registry` - Container registry hostname - `repository` - Repository path - `config_digest` - Image config digest - `distribution_digests` - Distribution digests (manifest/index pairs) - `image_tags` - Distinct image tags across all discovery sources - `built_at` - When the image was built - `size_bytes` - Size of the image in bytes - `author` - Image author - `architecture` - CPU architecture - `os` - Operating system - `variant` - CPU architecture variant - `os_version` - Operating system version - `os_features` - OS features - `config` - Image runtime configuration (OCI config) - `root_fs` - Root filesystem information - `history` - Image build history - `inferred_base_images` - Inferred base images - `teams` - Teams associated with the asset - `labels` - Labels associated with the asset - `tags` - Key-value tags for the asset - `risk_score` - Risk score for the asset - `test_surfaces` - Test surfaces for the asset - `issues` - Issue counts by severity - `created_at` - When the asset was created - `updated_at` - When the asset was last updated - `last_scan` - When the asset was last scanned - `scan_engines` - Scan engines applied to the asset  Note: `type` and `id` are always included regardless of field selection.  (e.g. {container_images: registry,repository,config_digest})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "fields" $qp_fields "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/inventory/assets/($asset_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update asset attributes - Group scope (Early Access)
#
# PATCH /groups/{group_id}/inventory/assets/{asset_id}
# operationId: updateAssetGroup
export def "groups-inventory-assets updateAssetGroup" [
  group_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/inventory/assets/($asset_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# List projects for an asset (group scope) (Early Access)
#
# GET /groups/{group_id}/inventory/assets/{asset_id}/relationships/projects
# operationId: listAssetProjectsGroup
export def "groups-inventory-assets-relationships-projects listAssetProjectsGroup" [
  group_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --starting-after: string # Cursor for fetching the next page of results
  --ending-before: string # Cursor for fetching the previous page of results
  --limit: int # Maximum number of results to return per page (default: 10)
  --canonical: string@canonical-completer # Filter projects by canonical status. - `with`: Returns all projects (canonical attribute is populated). - `only`: Returns only canonical projects (those used for vulnerability counts). - `none`: Returns only non-canonical projects. When omitted, returns all projects without canonical filtering.
  --target-id: string # Filter projects by target ID. When provided, returns only projects that belong to the specified target. When omitted, returns projects from all targets.  (format: uuid)
  --qp-sort: string@sort-completer # Sort field with optional direction prefix. Prefix with `-` for descending order.  **Supported fields:** - `snapshot_created_at` - Snapshot creation timestamp - `issues` - Issue counts by severity (critical, high, medium, low)  When omitted, results are ordered by `snapshot_created_at` ascending.  (e.g. -snapshot_created_at)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "canonical" $canonical "scalar") (serialize-qp "target_id" $target_id "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/inventory/assets/($asset_id)/relationships/projects" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List targets for an asset (group scope) (Early Access)
#
# GET /groups/{group_id}/inventory/assets/{asset_id}/relationships/targets
# operationId: listAssetTargetsGroup
export def "groups-inventory-assets-relationships-targets listAssetTargetsGroup" [
  group_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --starting-after: string # Cursor for fetching the next page of results
  --ending-before: string # Cursor for fetching the previous page of results
  --limit: int # Maximum number of results to return per page (default: 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/inventory/assets/($asset_id)/relationships/targets" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get issues by group ID
#
# GET /groups/{group_id}/issues
# operationId: listGroupIssues
export def "groups-issues listGroupIssues" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --scan-itemid: string # A scan item id to filter issues through their scan item relationship. (format: uuid, e.g. 4a18d42f-0706-4ad0-b127-24078731fbee)
  --scan-itemtype: string@scan-itemtype-completer # A scan item types to filter issues through their scan item relationship. (e.g. project)
  --type: string@type-completer-1 # An issue type to filter issues. (e.g. cloud)
  --updated-before: string # A filter to select issues updated before this date. (format: date-time)
  --updated-after: string # A filter to select issues updated after this date. (format: date-time)
  --created-before: string # A filter to select issues created before this date. (format: date-time)
  --created-after: string # A filter to select issues created after this date. (format: date-time)
  --effective-severity-level: list # One or more effective severity levels to filter issues.
  --status: list # An issue's status
  --ignored: string@bool-completer # Whether an issue is ignored or not.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "scan_item.id" $scan_itemid "scalar") (serialize-qp "scan_item.type" $scan_itemtype "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "updated_before" $updated_before "scalar") (serialize-qp "updated_after" $updated_after "scalar") (serialize-qp "created_before" $created_before "scalar") (serialize-qp "created_after" $created_after "scalar") (serialize-qp "effective_severity_level" $effective_severity_level "csv") (serialize-qp "status" $status "csv") (serialize-qp "ignored" $ignored "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/issues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an issue
#
# GET /groups/{group_id}/issues/{issue_id}
# operationId: getGroupIssueByIssueID
export def "groups-issues get" [
  group_id: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/issues/($issue_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get export status
#
# GET /groups/{group_id}/jobs/export/{export_id}
# operationId: getGroupExportJobStatus
export def "groups-jobs-export get" [
  group_id: string
  export_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/jobs/export/($export_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all memberships of the group
#
# GET /groups/{group_id}/memberships
# operationId: listGroupMemberships
export def "groups-memberships listGroupMemberships" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --sort-by: string@sort-by-completer-1 # Which column to sort by.
  --sort-order: string@sort-order-completer # Order in which results are returned. (default: DESC, e.g. ASC)
  --email: string # Filter the response by Users that match the provided email
  --user-id: string # Filter the response by Users that match the provided user ID
  --username: string # Filter the response by Users that match the provided username
  --role-name: string # Filter the response for results only with the specified role.
  --include-group-membership-count: string@bool-completer # indicates whether the count of group memberships is included
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "role_name" $role_name "scalar") (serialize-qp "include_group_membership_count" $include_group_membership_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/memberships" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a group membership for a user with role
#
# POST /groups/{group_id}/memberships
# operationId: createGroupMembership
export def "groups-memberships createGroupMembership" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/memberships" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete a membership from a group
#
# DELETE /groups/{group_id}/memberships/{membership_id}
# operationId: deleteGroupMembership
export def "groups-memberships delete" [
  group_id: string
  membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cascade: string@bool-completer # indicates whether to delete the child org memberships of the group membership.
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cascade" $cascade "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/memberships/($membership_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a role from a group membership
#
# PATCH /groups/{group_id}/memberships/{membership_id}
# operationId: updateGroupUserMembership
export def "groups-memberships updateGroupUserMembership" [
  group_id: string
  membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/memberships/($membership_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get list of org memberships of a group user
#
# GET /groups/{group_id}/org_memberships
# operationId: listGroupUserOrgMemberships
export def "groups-org-memberships listGroupUserOrgMemberships" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-id: string # The ID of the User (format: uuid)
  --org-name: string # The Name of the org (e.g. Org name)
  --role-name: string # Filter the response for results only with the specified role.
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "org_name" $org_name "scalar") (serialize-qp "role_name" $role_name "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/org_memberships" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all organizations in group
#
# GET /groups/{group_id}/orgs
# operationId: listOrgsInGroup
export def "groups-orgs listOrgsInGroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --name: string # Only return organizations whose name contains this value. Case insensitive.
  --slug: string # Only return organizations whose slug exactly matches this value. Case sensitive.
  --expand: string@expand-completer # Expand the response with additional fields. When set to `count`, the response will include a `meta` object containing a `total_count` field with the total number of organizations in the group, ignoring any filters applied to the original query. (e.g. count)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/orgs" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get group level policies (Early Access)
#
# GET /groups/{group_id}/policies
# operationId: listGroupPolicies
export def "groups-policies listGroupPolicies" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/policies" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new group level policy (Early Access)
#
# POST /groups/{group_id}/policies
# operationId: createGroupPolicy
export def "groups-policies createGroupPolicy" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/policies" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete an group-level policy (Early Access)
#
# DELETE /groups/{group_id}/policies/{policy_id}
# operationId: deleteGroupPolicy
export def "groups-policies delete" [
  group_id: string
  policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/policies/($policy_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a group-level policy (Early Access)
#
# PATCH /groups/{group_id}/policies/{policy_id}
# operationId: updateGroupPolicy
export def "groups-policies updateGroupPolicy" [
  group_id: string
  policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/policies/($policy_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get a list of group service accounts.
#
# GET /groups/{group_id}/service_accounts
# operationId: getManyGroupServiceAccount
export def "groups-service-accounts list" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/service_accounts" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a service account for a group.
#
# POST /groups/{group_id}/service_accounts
# operationId: createGroupServiceAccount
export def "groups-service-accounts createGroupServiceAccount" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/service_accounts" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete a group service account.
#
# DELETE /groups/{group_id}/service_accounts/{serviceaccount_id}
# operationId: deleteOneGroupServiceAccount
export def "groups-service-accounts delete" [
  group_id: string
  serviceaccount_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/service_accounts/($serviceaccount_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a group service account.
#
# GET /groups/{group_id}/service_accounts/{serviceaccount_id}
# operationId: getOneGroupServiceAccount
export def "groups-service-accounts get" [
  group_id: string
  serviceaccount_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/service_accounts/($serviceaccount_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a group service account.
#
# PATCH /groups/{group_id}/service_accounts/{serviceaccount_id}
# operationId: updateGroupServiceAccount
export def "groups-service-accounts updateGroupServiceAccount" [
  group_id: string
  serviceaccount_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/service_accounts/($serviceaccount_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Manage a group service account's client secret.
#
# POST /groups/{group_id}/service_accounts/{serviceaccount_id}/secrets
# operationId: updateServiceAccountSecret
export def "groups-service-accounts-secrets updateServiceAccountSecret" [
  group_id: string
  serviceaccount_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/service_accounts/($serviceaccount_id)/secrets" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get the Infrastructure as Code Settings for a group
#
# GET /groups/{group_id}/settings/iac
# operationId: getIacSettingsForGroup
export def "groups-settings-iac get" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/settings/iac" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the Infrastructure as Code Settings for a group
#
# PATCH /groups/{group_id}/settings/iac
# operationId: updateIacSettingsForGroup
export def "groups-settings-iac updateIacSettingsForGroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/settings/iac" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete opensource broker setting for group
#
# DELETE /groups/{group_id}/settings/opensource/broker
# operationId: deleteOpensourceBrokerSettingForGroup
export def "groups-settings-opensource-broker delete" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/settings/opensource/broker" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get opensource broker setting for group
#
# GET /groups/{group_id}/settings/opensource/broker
# operationId: getOpensourceBrokerSettingForGroup
export def "groups-settings-opensource-broker get" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/settings/opensource/broker" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable opensource broker for group
#
# POST /groups/{group_id}/settings/opensource/broker
# operationId: enableOpensourceBrokerForGroup
export def "groups-settings-opensource-broker enableOpensourceBrokerForGroup" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/settings/opensource/broker" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete pull request template for group
#
# DELETE /groups/{group_id}/settings/pull_request_template
# operationId: deletePullRequestTemplate
export def "groups-settings-pull-request-template delete" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/settings/pull_request_template" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get pull request template for group
#
# GET /groups/{group_id}/settings/pull_request_template
# operationId: getPullRequestTemplate
export def "groups-settings-pull-request-template get" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/settings/pull_request_template" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update pull request template for group
#
# POST /groups/{group_id}/settings/pull_request_template
# operationId: createOrUpdatePullRequestTemplate
export def "groups-settings-pull-request-template createOrUpdatePullRequestTemplate" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/settings/pull_request_template" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get all SSO connections for a group (Early Access)
#
# GET /groups/{group_id}/sso_connections
# operationId: listGroupSsoConnections
export def "groups-sso-connections listGroupSsoConnections" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/sso_connections" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all users using a given SSO connection (Early Access)
#
# GET /groups/{group_id}/sso_connections/{sso_id}/users
# operationId: listGroupSsoConnectionUsers
export def "groups-sso-connections-users listGroupSsoConnectionUsers" [
  group_id: string
  sso_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/sso_connections/($sso_id)/users" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a user from a Group SSO connection (Early Access)
#
# DELETE /groups/{group_id}/sso_connections/{sso_id}/users/{user_id}
# operationId: deleteUser
export def "groups-sso-connections-users delete" [
  group_id: string
  sso_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/sso_connections/($sso_id)/users/($user_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user's role in a group (Early Access)
#
# PATCH /groups/{group_id}/users/{id}
# operationId: updateUser
export def "groups-users updateUser" [
  group_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/users/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# List Snyk Learn's resources (Early Access)
#
# GET /learn/catalog
# operationId: listLearnCatalog
export def "learn-catalog listLearnCatalog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (default: 2025-11-05, e.g. 2025-11-05)
  --content-source: string@content-source-completer # The source of educational resources
  --qp-source: string # Optional caller-attribution string for Snyk-internal telemetry. When the value is on Snyk's internal allowlist, it is echoed back into each returned resource URL as `?source=<value>`; otherwise the value is silently dropped. Third-party consumers can omit this parameter.
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "content_source" $content_source "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/learn/catalog" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List available versions of OpenAPI specification
#
# GET /openapi
# operationId: listAPIVersions
export def "openapi listAPIVersions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/openapi")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get OpenAPI specification effective at version.
#
# GET /openapi/{version}
# operationId: getAPIVersion
export def "openapi get" [
  version: string
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
  let full_url = (build-url $base $"/openapi/($version)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List accessible organizations
#
# GET /orgs
# operationId: listOrgs
export def "orgs listOrgs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --group-id: string # If set, only return organizations within the specified group (format: uuid)
  --is-personal: string@bool-completer # If true, only return organizations that are not part of a group.
  --slug: string # Only return orgs whose slug exactly matches this value.
  --name: string # Only return orgs whose name contains this value.
  --expand: list # Expand the specified related resources in the response to include their attributes.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "is_personal" $is_personal "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/orgs" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization
#
# GET /orgs/{org_id}
# operationId: getOrg
export def "orgs get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --expand: list # Expand the specified related resources in the response to include their attributes.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update organization
#
# PATCH /orgs/{org_id}
# operationId: updateOrg
export def "orgs updateOrg" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get an AI-BOM job status (Early Access)
#
# GET /orgs/{org_id}/ai_bom_jobs/{job_id}
# operationId: getAiBomJob
export def "orgs-ai-bom-jobs get" [
  org_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/ai_bom_jobs/($job_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new AI-BOM (Early Access)
#
# POST /orgs/{org_id}/ai_boms
# operationId: createAiBom
export def "orgs-ai-boms createAiBom" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/ai_boms" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Create and upload an AI-BOM (Early Access)
#
# POST /orgs/{org_id}/ai_boms/upload
# operationId: createAndUploadAiBom
export def "orgs-ai-boms-upload createAndUploadAiBom" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/ai_boms/upload" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get an AI-BOM. (Early Access)
#
# GET /orgs/{org_id}/ai_boms/{ai_bom_id}
# operationId: getAiBom
export def "orgs-ai-boms get" [
  org_id: string
  ai_bom_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/ai_boms/($ai_bom_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of app bots authorized to an organization.
#
# GET /orgs/{org_id}/app_bots
# DEPRECATED
# operationId: getAppBots
@deprecated
export def "orgs-app-bots get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: list # Expand relationships.
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv") (serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/app_bots" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke app bot authorization
#
# DELETE /orgs/{org_id}/app_bots/{bot_id}
# DEPRECATED
# operationId: deleteAppBot
@deprecated
export def "orgs-app-bots delete" [
  bot_id: string
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/app_bots/($bot_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of Snyk Apps created by an Organization
#
# GET /orgs/{org_id}/apps
# DEPRECATED
# operationId: getApps
@deprecated
export def "orgs-apps list" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/apps" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new app for an organization.
#
# POST /orgs/{org_id}/apps
# DEPRECATED
# operationId: createApp
@deprecated
export def "orgs-apps createApp" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/apps" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get a list of Snyk Apps created by an Organization
#
# GET /orgs/{org_id}/apps/creations
# operationId: getOrgApps
export def "orgs-apps-creations list" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/apps/creations" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Snyk App for an organization
#
# POST /orgs/{org_id}/apps/creations
# operationId: createOrgApp
export def "orgs-apps-creations createOrgApp" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/apps/creations" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete a Snyk App by app ID
#
# DELETE /orgs/{org_id}/apps/creations/{app_id}
# operationId: deleteAppByID
export def "orgs-apps-creations delete" [
  org_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/apps/creations/($app_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Snyk App by app ID
#
# GET /orgs/{org_id}/apps/creations/{app_id}
# operationId: getAppByID
export def "orgs-apps-creations get" [
  org_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/apps/creations/($app_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update app creation attributes such as name, redirect URIs, and access token time to live using the App ID
#
# PATCH /orgs/{org_id}/apps/creations/{app_id}
# operationId: updateAppCreationByID
export def "orgs-apps-creations updateAppCreationByID" [
  org_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/apps/creations/($app_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Manage client secret for a Snyk App
#
# POST /orgs/{org_id}/apps/creations/{app_id}/secrets
# operationId: manageAppCreationSecret
export def "orgs-apps-creations-secrets manageAppCreationSecret" [
  org_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/apps/creations/($app_id)/secrets" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get a list of Snyk Apps installed for an Organization
#
# GET /orgs/{org_id}/apps/installs
# operationId: getAppInstallsForOrg
export def "orgs-apps-installs get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: list # Expand relationships.
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv") (serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/apps/installs" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Install a Snyk App for an Organization
#
# POST /orgs/{org_id}/apps/installs
# operationId: createOrgAppInstall
export def "orgs-apps-installs createOrgAppInstall" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/apps/installs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Revoke app authorization for a Snyk organization with install ID
#
# DELETE /orgs/{org_id}/apps/installs/{install_id}
# operationId: deleteAppOrgInstallById
export def "orgs-apps-installs delete" [
  org_id: string
  install_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/apps/installs/($install_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Manage client secret for non-interactive Snyk App installations
#
# POST /orgs/{org_id}/apps/installs/{install_id}/secrets
# operationId: updateOrgAppInstallSecret
export def "orgs-apps-installs-secrets updateOrgAppInstallSecret" [
  org_id: string
  install_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/apps/installs/($install_id)/secrets" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete an app
#
# DELETE /orgs/{org_id}/apps/{client_id}
# DEPRECATED
# operationId: deleteApp
@deprecated
export def "orgs-apps delete" [
  org_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/apps/($client_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an app by client id
#
# GET /orgs/{org_id}/apps/{client_id}
# DEPRECATED
# operationId: getApp
@deprecated
export def "orgs-apps get" [
  org_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/apps/($client_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update app attributes that are name, redirect URIs, and access token time to live
#
# PATCH /orgs/{org_id}/apps/{client_id}
# DEPRECATED
# operationId: updateApp
@deprecated
export def "orgs-apps updateApp" [
  org_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/apps/($client_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Manage client secrets for an app.
#
# POST /orgs/{org_id}/apps/{client_id}/secrets
# DEPRECATED
# operationId: manageSecrets
@deprecated
export def "orgs-apps-secrets manageSecrets" [
  org_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/apps/($client_id)/secrets" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Search Organization audit logs.
#
# GET /orgs/{org_id}/audit_logs/search
# operationId: listOrgAuditLogs
export def "orgs-audit-logs-search listOrgAuditLogs" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --cursor: string # The ID for the next page of results.
  --qp-from: string # The start date (inclusive) of the audit logs search. If not specified, the start of yesterday is used. Dates should be formatted as RFC3339, e.g. 2024-01-02T16:30:00Z.  (format: date-time)
  --qp-to: string # The end date (exclusive) of the audit logs search. Dates should be formatted as RFC3339, e.g. 2024-01-02T16:30:00Z.  (format: date-time)
  --size: int # Number of results to return per page. (format: int32, default: 100, e.g. 10)
  --sort-order: string@sort-order-completer # Order in which results are returned. (default: DESC, e.g. ASC)
  --user-id: string # Filter logs by user ID. (format: uuid, e.g. 0d3728ec-eebf-484d-9907-ba238019f10b)
  --project-id: string # Filter logs by project ID. (format: uuid, e.g. 0d3728ec-eebf-484d-9907-ba238019f10b)
  --events: list # Filter logs by event types, cannot be used in conjunction with exclude_events parameter.
  --exclude-events: list # Exclude event types from results, cannot be used in conjunctions with events parameter.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "events" $events "multi") (serialize-qp "exclude_events" $exclude_events "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/audit_logs/search" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Broker connections for a given organization
#
# GET /orgs/{org_id}/brokers/connections
# operationId: listBrokerConnectionsForOrg
export def "orgs-brokers-connections listBrokerConnectionsForOrg" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/brokers/connections" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Environments (Early Access)
#
# GET /orgs/{org_id}/cloud/environments
# operationId: listEnvironments
export def "orgs-cloud-environments listEnvironments" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --created-after: string # Return environments created after this date (format: date-time, e.g. 2022-05-06T12:25:15-04:00)
  --created-before: string # Return environments created before this date (format: date-time, e.g. 2022-05-06T12:25:15-04:00)
  --updated-after: string # Return environments updated after this date (format: date-time, e.g. 2022-05-06T12:25:15-04:00)
  --updated-before: string # Return environments updated before this date (format: date-time, e.g. 2022-05-06T12:25:15-04:00)
  --name: string # Filter environments by name (multi-value, comma-separated) (e.g. Demo AWS Environment)
  --kind: string@kind-completer # Filter environments by kind (multi-value, comma-separated): aws (e.g. aws)
  --status: string@status-completer # Filter environments by latest scan status (multi-value, comma-separated) (e.g. error)
  --id: string # Filter environments by environment ID (multi-value, comma-separated) (format: uuid, e.g. 052781a7-17f6-494d-0000-25c8b509abcd)
  --project-id: string # Filter environments by project ID (format: uuid, e.g. 9a46d918-8764-458c-1234-0987abcd6543)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "created_after" $created_after "scalar") (serialize-qp "created_before" $created_before "scalar") (serialize-qp "updated_after" $updated_after "scalar") (serialize-qp "updated_before" $updated_before "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/cloud/environments" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create New Environment (Early Access)
#
# POST /orgs/{org_id}/cloud/environments
# operationId: createEnvironment
export def "orgs-cloud-environments createEnvironment" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/cloud/environments" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete Environment (Early Access)
#
# DELETE /orgs/{org_id}/cloud/environments/{environment_id}
# operationId: deleteEnvironment
export def "orgs-cloud-environments delete" [
  org_id: string
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/cloud/environments/($environment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Environment (Early Access)
#
# PATCH /orgs/{org_id}/cloud/environments/{environment_id}
# operationId: updateEnvironment
export def "orgs-cloud-environments updateEnvironment" [
  org_id: string
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/cloud/environments/($environment_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Generate Cloud Provider Permissions (Early Access)
#
# POST /orgs/{org_id}/cloud/permissions
# operationId: getPermissions
export def "orgs-cloud-permissions post" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/cloud/permissions" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# List Resources (Early Access)
#
# GET /orgs/{org_id}/cloud/resources
# operationId: listResources
export def "orgs-cloud-resources listResources" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environment-id: string # Filter resources by environment ID (multi-value, comma-separated) (format: uuid, e.g. 052781a7-17f6-494d-0000-25c8b509abcd)
  --resource-type: string # Filter resources by resource type (multi-value, comma-separated) (e.g. aws_s3_bucket)
  --resource-id: string # Filter resources by resource ID (multi-value, comma-separated) (e.g. example-bucket)
  --native-id: string # Filter resources by native ID (multi-value, comma-separated) (AWS ARN) (e.g. arn:aws:s3:::example-bucket)
  --id: string # Filter resources by resource UUID (multi-value, comma-separated) (e.g. 4a662442-7445-55c3-adcc-cbbbdd99999)
  --platform: string # Filter resources by platform (multi-value, comma-separated): aws (e.g. aws)
  --name: string # Filter resources by name (multi-value, comma-separated) (e.g. example-bucket)
  --kind: string # Filter resources by kind (multi-value, comma-separated): cloud (e.g. cloud - cloud - iac)
  --location: string # Filter resources by location (multi-value, comma-separated) (AWS region) (e.g. us-west-2)
  --removed: string@bool-completer # Filter resources by whether they have been removed or not. (e.g. true)
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment_id" $environment_id "scalar") (serialize-qp "resource_type" $resource_type "scalar") (serialize-qp "resource_id" $resource_id "scalar") (serialize-qp "native_id" $native_id "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "removed" $removed "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/cloud/resources" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Scans (Early Access)
#
# GET /orgs/{org_id}/cloud/scans
# operationId: listScan
export def "orgs-cloud-scans listScan" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/cloud/scans" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Scan (Early Access)
#
# POST /orgs/{org_id}/cloud/scans
# operationId: createScan
export def "orgs-cloud-scans createScan" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/cloud/scans" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get scan (Early Access)
#
# GET /orgs/{org_id}/cloud/scans/{scan_id}
# operationId: getScan
export def "orgs-cloud-scans get" [
  org_id: string
  scan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/cloud/scans/($scan_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get collections
#
# GET /orgs/{org_id}/collections
# operationId: getCollections
export def "orgs-collections list" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --qp-sort: string@sort-completer-1 # Return collections sorted by the specified attributes
  --direction: string@direction-completer # Return collections sorted in the specified direction (default: DESC)
  --name: string # Return collections which names include the provided string (allows empty value)
  --is-generated: string@bool-completer # Return collections where is_generated matches the provided boolean (allows empty value)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "is_generated" $is_generated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/collections" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a collection
#
# POST /orgs/{org_id}/collections
# operationId: createCollection
export def "orgs-collections createCollection" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/collections" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete a collection
#
# DELETE /orgs/{org_id}/collections/{collection_id}
# operationId: deleteCollection
export def "orgs-collections delete" [
  org_id: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/collections/($collection_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a collection
#
# GET /orgs/{org_id}/collections/{collection_id}
# operationId: getCollection
export def "orgs-collections get" [
  org_id: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/collections/($collection_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a collection
#
# PATCH /orgs/{org_id}/collections/{collection_id}
# operationId: updateCollection
export def "orgs-collections updateCollection" [
  org_id: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/collections/($collection_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Remove projects from a collection
#
# DELETE /orgs/{org_id}/collections/{collection_id}/relationships/projects
# operationId: deleteProjectsCollection
export def "orgs-collections-relationships-projects delete" [
  org_id: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/collections/($collection_id)/relationships/projects" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get projects from the specified collection
#
# GET /orgs/{org_id}/collections/{collection_id}/relationships/projects
# operationId: getProjectsOfCollection
export def "orgs-collections-relationships-projects get" [
  org_id: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --qp-sort: string@sort-completer-2 # Return projects sorted by the specified attributes
  --direction: string@direction-completer # Return projects sorted in the specified direction (default: DESC)
  --target-id: list # Return projects that belong to the provided targets
  --show: list # Return projects that are with or without issues
  --integration: list # Return projects that match the provided integration types
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "target_id" $target_id "multi") (serialize-qp "show" $show "multi") (serialize-qp "integration" $integration "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/collections/($collection_id)/relationships/projects" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add projects to a collection
#
# POST /orgs/{org_id}/collections/{collection_id}/relationships/projects
# operationId: updateCollectionWithProjects
export def "orgs-collections-relationships-projects updateCollectionWithProjects" [
  org_id: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/collections/($collection_id)/relationships/projects" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# List instances of container image
#
# GET /orgs/{org_id}/container_images
# operationId: listContainerImage
export def "orgs-container-images listContainerImage" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --image-ids: list # A comma-separated list of Image IDs (e.g. [sha256:b26f21f90920dba8401e30b89ad803587f81cce9bd1f92750f963556da2f930f, sha256:28984a62eb713aa5fff922ba06e8689f20e4b2f07de30f3d753b868389c0904f])
  --platform: string@platform-completer # The image Operating System and processor architecture (e.g. linux/amd64)
  --names: list # The container registry names (e.g. [gcr.io/snyk/redis:5])
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "image_ids" $image_ids "csv") (serialize-qp "platform" $platform "scalar") (serialize-qp "names" $names "csv") (serialize-qp "version" $version "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/container_images" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get instance of container image
#
# GET /orgs/{org_id}/container_images/{image_id}
# operationId: getContainerImage
export def "orgs-container-images get" [
  org_id: string
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/container_images/($image_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List instances of image target references for a container image
#
# GET /orgs/{org_id}/container_images/{image_id}/relationships/image_target_refs
# operationId: listImageTargetRefs
export def "orgs-container-images-relationships-image-target-refs listImageTargetRefs" [
  org_id: string
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/container_images/($image_id)/relationships/image_target_refs" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Dry run a container registry import policy (Early Access)
#
# POST /orgs/{org_id}/container_import/{integration_id}/policy/dry_run
# operationId: createContainerRegistryImportPolicyDryRun
export def "orgs-container-import-policy-dry-run createContainerRegistryImportPolicyDryRun" [
  org_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/container_import/($integration_id)/policy/dry_run" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get a package (Early Access)
#
# GET /orgs/{org_id}/ecosystems/{ecosystem}/packages/{package_name}
# operationId: getPackage
export def "orgs-ecosystems-packages get" [
  org_id: string
  ecosystem: string
  package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/ecosystems/($ecosystem)/packages/($package_name)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a package version (Early Access)
#
# GET /orgs/{org_id}/ecosystems/{ecosystem}/packages/{package_name}/versions/{package_version}
# operationId: getPackageVersion
export def "orgs-ecosystems-packages-versions get" [
  org_id: string
  ecosystem: string
  package_name: string
  package_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/ecosystems/($ecosystem)/packages/($package_name)/versions/($package_version)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start an export
#
# POST /orgs/{org_id}/export
# operationId: createExport
export def "orgs-export createExport" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --include-deleted: string # Optional parameter to include deleted issues in results
  --include-deactivated: string # Optional parameter to include disabled issues in results
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "include_deleted" $include_deleted "scalar") (serialize-qp "include_deactivated" $include_deactivated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/export" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get export results
#
# GET /orgs/{org_id}/export/{export_id}
# operationId: getExport
export def "orgs-export get" [
  org_id: string
  export_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/export/($export_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List or search all assets (synchronous) - Org scope (Early Access)
#
# GET /orgs/{org_id}/inventory/assets
# operationId: listAssetsOrg
export def "orgs-inventory-assets listAssetsOrg" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --filter: string # RSQL filter expression for filtering results. See schema for full documentation. (e.g. type==container_images;created_at>2024-01-01)
  --qp-sort: string # Comma-separated sort fields. Prefix with `-` for descending order. (e.g. -created_at)
  --limit: int # Number of results to return per page (default: 10)
  --starting-after: string # Cursor for fetching the next page of results
  --ending-before: string # Cursor for fetching the previous page of results
  --qp-fields: record # Sparse fieldsets allow clients to request only specific fields for a given resource type. Use the format `fields[<type>]=field1,field2` where `<type>` is the JSON:API resource type.  **Container image fields** (use with `fields[container_images]`): - `class` - Classification of the asset - `registry` - Container registry hostname - `repository` - Repository path - `config_digest` - Image config digest - `distribution_digests` - Distribution digests (manifest/index pairs) - `image_tags` - Distinct image tags across all discovery sources - `built_at` - When the image was built - `size_bytes` - Size of the image in bytes - `author` - Image author - `architecture` - CPU architecture - `os` - Operating system - `variant` - CPU architecture variant - `os_version` - Operating system version - `os_features` - OS features - `config` - Image runtime configuration (OCI config) - `root_fs` - Root filesystem information - `history` - Image build history - `inferred_base_images` - Inferred base images - `teams` - Teams associated with the asset - `labels` - Labels associated with the asset - `tags` - Key-value tags for the asset - `risk_score` - Risk score for the asset - `test_surfaces` - Test surfaces for the asset - `issues` - Issue counts by severity - `created_at` - When the asset was created - `updated_at` - When the asset was last updated - `last_scan` - When the asset was last scanned - `scan_engines` - Scan engines applied to the asset  Note: `type` and `id` are always included regardless of field selection.  (e.g. {container_images: registry,repository,config_digest})
  --meta-count: string@meta-count-completer # Provide summary count in the response meta object when requested. When `with` is provided, the count will be included in the response meta object. When `only` is provided, the count will be included in the response meta object and no data will be returned.  (e.g. with)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "fields" $qp_fields "deepObject") (serialize-qp "meta_count" $meta_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/inventory/assets" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk update asset attributes - Org scope (Early Access)
#
# PATCH /orgs/{org_id}/inventory/assets
# operationId: updateAssetsBulkOrg
export def "orgs-inventory-assets updateAssetsBulkOrg" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/inventory/assets" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get available filter fields - Org scope (Early Access)
#
# GET /orgs/{org_id}/inventory/assets/filters
# operationId: getFilterFieldsOrg
export def "orgs-inventory-assets-filters get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --asset-types: string # Comma-separated list of asset types to filter the available filter fields (e.g. container_images)
  --limit: int # Number of results to return (default: 10)
  --starting-after: string # Cursor for fetching the next page of results
  --ending-before: string # Cursor for fetching the previous page of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "asset_types" $asset_types "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/inventory/assets/filters" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get filter value suggestions (autocomplete) - Org scope (Early Access)
#
# GET /orgs/{org_id}/inventory/assets/filters/{filter_id}/values
# operationId: getFilterValuesOrg
export def "orgs-inventory-assets-filters-values get" [
  org_id: string
  filter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --q: string # Full text search term to filter the list of values. If keys_only is true, this will filter the keys of the object filter values. If key is provided, this will filter the value for the specific key of the object filter values. (e.g. prod)
  --limit: int # Number of results to return (default: 10)
  --starting-after: string # Cursor for fetching the next page of results
  --ending-before: string # Cursor for fetching the previous page of results
  --keys-only: string@bool-completer # Return only the keys of the object filter values
  --key: string # Return only the value for a specific key of the object filter values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "keys_only" $keys_only "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/inventory/assets/filters/($filter_id)/values" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get available group fields - Org scope (Early Access)
#
# GET /orgs/{org_id}/inventory/assets/groups
# operationId: getGroupFieldsOrg
export def "orgs-inventory-assets-groups get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --asset-types: string # Comma-separated list of asset types to filter group fields
  --limit: int # Maximum number of results to return (default: 10)
  --starting-after: string # Cursor for forward pagination
  --ending-before: string # Cursor for backward pagination
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "asset_types" $asset_types "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/inventory/assets/groups" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get group value aggregation - Org scope (Early Access)
#
# GET /orgs/{org_id}/inventory/assets/groups/{group_field_id}/values
# operationId: getGroupValuesOrg
export def "orgs-inventory-assets-groups-values get" [
  org_id: string
  group_field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --asset-types: string # Comma-separated list of asset types to filter the aggregation (e.g. container_images)
  --filter: string # RSQL filter expression for filtering which assets are included in aggregation. Supports the same syntax as the main search filter including full text search with the `q` field. See the RsqlFilterString schema for complete documentation.  (e.g. type==container_images;created_at>2024-01-01)
  --qp-sort: string # Comma-separated sort fields for group values. Prefix with `-` for descending order. Multiple sort fields are supported (e.g., `-issues,count`). Defaults to `created_at` (ascending) when not specified. Results are always tie-broken by `value` for deterministic ordering.  Available sort fields:   - `value` - Sort by the group value string (alphabetical)   - `count` - Sort by the number of assets in each group   - `created_at` - Sort by the aggregated created_at timestamp   - `last_seen_at` - Sort by the aggregated last_seen_at timestamp   - `updated_at` - Sort by the aggregated updated_at timestamp   - `risk_score` - Sort by the aggregated risk score   - `built_at` - Sort by the aggregated container image build timestamp   - `issues` - Sort by issue severity (critical → high → medium → low)  (e.g. -count)
  --limit: int # Maximum number of group values to return (default: 10)
  --starting-after: string # Cursor for forward pagination
  --ending-before: string # Cursor for backward pagination
  --meta-fields: list # Meta fields to include in the response. Multiple fields can be specified.  Available fields:   - `count` - Number of assets with this value   - `created_at` - Aggregated asset creation timestamp (default aggregation: last)   - `last_seen_at` - Aggregated last_seen_at timestamp (default aggregation: last)   - `updated_at` - Aggregated updated_at timestamp (default aggregation: last)   - `risk_score` - Aggregated risk score from discovery sources (default aggregation: last)   - `issues` - Aggregated issue counts (critical, high, medium, low, total) (default aggregation: last)   - `labels` - Labels across assets (default aggregation: last)   - `tags` - Tags across assets (default aggregation: last)   - `built_at` - Aggregated container image build timestamp (default aggregation: last)   - `all` - Include all available meta fields  All fields default to the `last` aggregation function, which returns the value from the asset with the most recent updated_at in the group. Use the `aggregate` parameter to override the aggregation function per field.  If not specified, the meta object is not included in the response.  Note: Requesting meta fields may impact response time as aggregations require additional computation.  (e.g. [count, risk_score, issues, labels])
  --aggregate: record # Per-field aggregate function override for meta fields. All fields default to `last` when not specified. `max`/`min` compute the SQL MAX/MIN across all assets in the group (scalar fields only). `first`/`last` returns the value from the single asset with the earliest/latest updated_at in the group (all field types). `sum` computes the total across all assets (numeric fields, issues, labels, tags).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "asset_types" $asset_types "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "meta_fields" $meta_fields "csv") (serialize-qp "aggregate" $aggregate "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/inventory/assets/groups/($group_field_id)/values" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an asset search (asynchronous) - Org scope (Early Access)
#
# POST /orgs/{org_id}/inventory/assets/searches
# operationId: createAssetSearchOrg
export def "orgs-inventory-assets-searches createAssetSearchOrg" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/inventory/assets/searches" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Retrieve asset search results (asynchronous) - Org scope (Early Access)
#
# GET /orgs/{org_id}/inventory/assets/searches/{search_id}/results
# operationId: getAssetSearchResultsOrg
export def "orgs-inventory-assets-searches-results get" [
  org_id: string
  search_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --qp-sort: string # Sort order for results (e.g., -created_at for descending)
  --limit: int # Maximum number of results to return (default: 10)
  --starting-after: string # Cursor for forward pagination
  --ending-before: string # Cursor for backward pagination
  --qp-fields: record # Sparse fieldsets allow clients to request only specific fields for a given resource type. Use the format `fields[<type>]=field1,field2` where `<type>` is the JSON:API resource type.  **Container image fields** (use with `fields[container_images]`): - `class` - Classification of the asset - `registry` - Container registry hostname - `repository` - Repository path - `config_digest` - Image config digest - `distribution_digests` - Distribution digests (manifest/index pairs) - `image_tags` - Distinct image tags across all discovery sources - `built_at` - When the image was built - `size_bytes` - Size of the image in bytes - `author` - Image author - `architecture` - CPU architecture - `os` - Operating system - `variant` - CPU architecture variant - `os_version` - Operating system version - `os_features` - OS features - `config` - Image runtime configuration (OCI config) - `root_fs` - Root filesystem information - `history` - Image build history - `inferred_base_images` - Inferred base images - `teams` - Teams associated with the asset - `labels` - Labels associated with the asset - `tags` - Key-value tags for the asset - `risk_score` - Risk score for the asset - `test_surfaces` - Test surfaces for the asset - `issues` - Issue counts by severity - `created_at` - When the asset was created - `updated_at` - When the asset was last updated - `last_scan` - When the asset was last scanned - `scan_engines` - Scan engines applied to the asset  Note: `type` and `id` are always included regardless of field selection.  (e.g. {container_images: registry,repository,config_digest})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "fields" $qp_fields "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/inventory/assets/searches/($search_id)/results" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single asset by ID - Org scope (Early Access)
#
# GET /orgs/{org_id}/inventory/assets/{asset_id}
# operationId: getAssetOrg
export def "orgs-inventory-assets get" [
  org_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --qp-fields: record # Sparse fieldsets allow clients to request only specific fields for a given resource type. Use the format `fields[<type>]=field1,field2` where `<type>` is the JSON:API resource type.  **Container image fields** (use with `fields[container_images]`): - `class` - Classification of the asset - `registry` - Container registry hostname - `repository` - Repository path - `config_digest` - Image config digest - `distribution_digests` - Distribution digests (manifest/index pairs) - `image_tags` - Distinct image tags across all discovery sources - `built_at` - When the image was built - `size_bytes` - Size of the image in bytes - `author` - Image author - `architecture` - CPU architecture - `os` - Operating system - `variant` - CPU architecture variant - `os_version` - Operating system version - `os_features` - OS features - `config` - Image runtime configuration (OCI config) - `root_fs` - Root filesystem information - `history` - Image build history - `inferred_base_images` - Inferred base images - `teams` - Teams associated with the asset - `labels` - Labels associated with the asset - `tags` - Key-value tags for the asset - `risk_score` - Risk score for the asset - `test_surfaces` - Test surfaces for the asset - `issues` - Issue counts by severity - `created_at` - When the asset was created - `updated_at` - When the asset was last updated - `last_scan` - When the asset was last scanned - `scan_engines` - Scan engines applied to the asset  Note: `type` and `id` are always included regardless of field selection.  (e.g. {container_images: registry,repository,config_digest})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "fields" $qp_fields "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/inventory/assets/($asset_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update asset attributes - Org scope (Early Access)
#
# PATCH /orgs/{org_id}/inventory/assets/{asset_id}
# operationId: updateAssetOrg
export def "orgs-inventory-assets updateAssetOrg" [
  org_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/inventory/assets/($asset_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# List projects for an asset (org scope) (Early Access)
#
# GET /orgs/{org_id}/inventory/assets/{asset_id}/relationships/projects
# operationId: listAssetProjectsOrg
export def "orgs-inventory-assets-relationships-projects listAssetProjectsOrg" [
  org_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --starting-after: string # Cursor for fetching the next page of results
  --ending-before: string # Cursor for fetching the previous page of results
  --limit: int # Maximum number of results to return per page (default: 10)
  --canonical: string@canonical-completer # Filter projects by canonical status. - `with`: Returns all projects (canonical attribute is populated). - `only`: Returns only canonical projects (those used for vulnerability counts). - `none`: Returns only non-canonical projects. When omitted, returns all projects without canonical filtering.
  --target-id: string # Filter projects by target ID. When provided, returns only projects that belong to the specified target. When omitted, returns projects from all targets.  (format: uuid)
  --qp-sort: string@sort-completer # Sort field with optional direction prefix. Prefix with `-` for descending order.  **Supported fields:** - `snapshot_created_at` - Snapshot creation timestamp - `issues` - Issue counts by severity (critical, high, medium, low)  When omitted, results are ordered by `snapshot_created_at` ascending.  (e.g. -snapshot_created_at)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "canonical" $canonical "scalar") (serialize-qp "target_id" $target_id "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/inventory/assets/($asset_id)/relationships/projects" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List targets for an asset (org scope) (Early Access)
#
# GET /orgs/{org_id}/inventory/assets/{asset_id}/relationships/targets
# operationId: listAssetTargetsOrg
export def "orgs-inventory-assets-relationships-targets listAssetTargetsOrg" [
  org_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --starting-after: string # Cursor for fetching the next page of results
  --ending-before: string # Cursor for fetching the previous page of results
  --limit: int # Maximum number of results to return per page (default: 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/inventory/assets/($asset_id)/relationships/targets" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List pending user invitations to an organization.
#
# GET /orgs/{org_id}/invites
# operationId: listOrgInvitation
export def "orgs-invites listOrgInvitation" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/invites" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invite a user to an organization
#
# POST /orgs/{org_id}/invites
# operationId: createOrgInvitation
export def "orgs-invites createOrgInvitation" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/invites" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Cancel a pending user invitations to an organization.
#
# DELETE /orgs/{org_id}/invites/{invite_id}
# operationId: deleteOrgInvitation
export def "orgs-invites delete" [
  org_id: string
  invite_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/invites/($invite_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get issues by org ID
#
# GET /orgs/{org_id}/issues
# operationId: listOrgIssues
export def "orgs-issues listOrgIssues" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --scan-itemid: string # A scan item id to filter issues through their scan item relationship. (format: uuid, e.g. 4a18d42f-0706-4ad0-b127-24078731fbee)
  --scan-itemtype: string@scan-itemtype-completer # A scan item types to filter issues through their scan item relationship. (e.g. project)
  --type: string@type-completer-1 # An issue type to filter issues. (e.g. cloud)
  --updated-before: string # A filter to select issues updated before this date. (format: date-time)
  --updated-after: string # A filter to select issues updated after this date. (format: date-time)
  --created-before: string # A filter to select issues created before this date. (format: date-time)
  --created-after: string # A filter to select issues created after this date. (format: date-time)
  --effective-severity-level: list # One or more effective severity levels to filter issues.
  --status: list # An issue's status
  --ignored: string@bool-completer # Whether an issue is ignored or not.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "scan_item.id" $scan_itemid "scalar") (serialize-qp "scan_item.type" $scan_itemtype "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "updated_before" $updated_before "scalar") (serialize-qp "updated_after" $updated_after "scalar") (serialize-qp "created_before" $created_before "scalar") (serialize-qp "created_after" $created_after "scalar") (serialize-qp "effective_severity_level" $effective_severity_level "csv") (serialize-qp "status" $status "csv") (serialize-qp "ignored" $ignored "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/issues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an issue
#
# GET /orgs/{org_id}/issues/{issue_id}
# operationId: getOrgIssueByIssueID
export def "orgs-issues get" [
  org_id: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/issues/($issue_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get export status
#
# GET /orgs/{org_id}/jobs/export/{export_id}
# operationId: getExportJobStatus
export def "orgs-jobs-export get" [
  org_id: string
  export_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/jobs/export/($export_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk deletion of assignments in an organization (Early Access)
#
# DELETE /orgs/{org_id}/learn/assignments
# DEPRECATED
# operationId: deleteOrgAssignments
@deprecated
export def "orgs-learn-assignments delete" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (default: 2025-11-05, e.g. 2025-11-05)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/learn/assignments" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Retrieve a list of assignments for an organization (Early Access)
#
# GET /orgs/{org_id}/learn/assignments
# operationId: listOrgAssignments
export def "orgs-learn-assignments listOrgAssignments" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (default: 2025-11-05, e.g. 2025-11-05)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/learn/assignments" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update due date for assignments in an organization. (Early Access)
#
# PATCH /orgs/{org_id}/learn/assignments
# operationId: updateOrgAssignments
export def "orgs-learn-assignments updateOrgAssignments" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (default: 2025-11-05, e.g. 2025-11-05)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/learn/assignments" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Bulk creation of assignments for users in an organization. (Early Access)
#
# POST /orgs/{org_id}/learn/assignments
# operationId: createOrgAssignments
export def "orgs-learn-assignments createOrgAssignments" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (default: 2025-11-05, e.g. 2025-11-05)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/learn/assignments" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Bulk deletion of assignments in an organization (Early Access)
#
# POST /orgs/{org_id}/learn/assignments/bulk_delete
# operationId: deleteOrgAssignmentsBulk
export def "orgs-learn-assignments-bulk-delete post" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (default: 2025-11-05, e.g. 2025-11-05)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/learn/assignments/bulk_delete" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get collective learning progress (Early Access)
#
# GET /orgs/{org_id}/learn/progress/catalog
# operationId: getCatalogProgress
@deprecated --flag title
export def "orgs-learn-progress-catalog get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (default: 2025-11-05, e.g. 2025-11-05)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --type: string@type-completer-2 # Filter by the learn catalog resource type (default: lesson)
  --title: string # This is deprecated, use Titles instead (DEPRECATED)
  --cwes: list # Filter by CWE rules
  --cves: list # Filter by CVE rules
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "cwes" $cwes "multi") (serialize-qp "cves" $cves "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/learn/progress/catalog" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get individual user learning progress (Early Access)
#
# GET /orgs/{org_id}/learn/progress/users
# operationId: getUsersProgress
@deprecated --flag title
export def "orgs-learn-progress-users get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (default: 2025-11-05, e.g. 2025-11-05)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --type: string@type-completer-2 # Filter by the learn catalog resource type (default: lesson)
  --title: string # This is deprecated, use Titles instead (DEPRECATED)
  --titles: list # Filter by the title of the learning path or lesson resource
  --status: string@status-completer-1 # Filter by progress status of the resources
  --emails: list # Filter by user email addresses (e.g. [john.doe@example.com, jane.smith@example.com])
  --completion-interval: string # Filter by date interval in ISO 8601 format (e.g. 2024-01-01/2024-02-01)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "titles" $titles "multi") (serialize-qp "status" $status "scalar") (serialize-qp "emails" $emails "csv") (serialize-qp "completion_interval" $completion_interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/learn/progress/users" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all memberships of the org
#
# GET /orgs/{org_id}/memberships
# operationId: listOrgMemberships
export def "orgs-memberships listOrgMemberships" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --sort-by: string@sort-by-completer-2 # Which column to sort by.
  --sort-order: string@sort-order-completer # Order in which results are returned. (default: ASC, e.g. ASC)
  --email: string # Filter the response by Users that match the provided email
  --user-id: string # Filter the response by Users that match the provided user ID
  --username: string # Filter the response by Users that match the provided username
  --role-name: string # Filter the response for results only with the specified role.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "role_name" $role_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/memberships" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a org membership for a user with role
#
# POST /orgs/{org_id}/memberships
# operationId: createOrgMembership
export def "orgs-memberships createOrgMembership" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/memberships" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Remove user's org membership
#
# DELETE /orgs/{org_id}/memberships/{membership_id}
# operationId: deleteOrgMembership
export def "orgs-memberships delete" [
  org_id: string
  membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/memberships/($membership_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a org membership for a user with role
#
# PATCH /orgs/{org_id}/memberships/{membership_id}
# operationId: updateOrgMembership
export def "orgs-memberships updateOrgMembership" [
  org_id: string
  membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/memberships/($membership_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# List issues for a given set of packages  (Currently not available to all customers)
#
# POST /orgs/{org_id}/packages/issues
# operationId: listIssuesForManyPurls
export def "orgs-packages-issues listIssuesForManyPurls" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/packages/issues" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# List issues for a package
#
# GET /orgs/{org_id}/packages/{purl}/issues
# operationId: fetchIssuesPerPurl
export def "orgs-packages-issues fetchIssuesPerPurl" [
  purl: string
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --offset: float # Specify the number of results to skip before returning results. Must be greater than or equal to 0. Default is 0.
  --limit: float # Specify the number of results to return. Must be greater than 0 and less than 1000. Default is 1000.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/packages/($purl)/issues" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get org-level policies
#
# GET /orgs/{org_id}/policies
# operationId: getOrgPolicies
export def "orgs-policies list" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --search: string # Search keyword for searching fields ignored_by.name, ignored_by.email, ignore_type in policy_rules
  --order-by: string@order-by-completer # The column name to sort on
  --order-direction: string@order-direction-completer # Sorting direction ASC/DESC
  --review: list # Policy rule review state e.g. approved
  --expires-before: string # Select only policies with an expiry strictly before the given time. (format: date-time, e.g. 2024-03-16T00:00:00Z)
  --expires-after: string # Select only policies with an expiry strictly past the given time. (format: date-time, e.g. 2024-03-16T00:00:00Z)
  --expires-never: string@bool-completer # Select only policies that never expire. (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "order_direction" $order_direction "scalar") (serialize-qp "review" $review "csv") (serialize-qp "expires_before" $expires_before "scalar") (serialize-qp "expires_after" $expires_after "scalar") (serialize-qp "expires_never" $expires_never "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/policies" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new org-level policy
#
# POST /orgs/{org_id}/policies
# operationId: createOrgPolicy
export def "orgs-policies createOrgPolicy" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/policies" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete an org-level policy
#
# DELETE /orgs/{org_id}/policies/{policy_id}
# operationId: deleteOrgPolicy
export def "orgs-policies delete" [
  org_id: string
  policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/policies/($policy_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an org-level policy
#
# GET /orgs/{org_id}/policies/{policy_id}
# operationId: getOrgPolicy
export def "orgs-policies get" [
  org_id: string
  policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/policies/($policy_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an org-level policy
#
# PATCH /orgs/{org_id}/policies/{policy_id}
# operationId: updateOrgPolicy
export def "orgs-policies updateOrgPolicy" [
  org_id: string
  policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/policies/($policy_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# List org policy events (Early Access)
#
# GET /orgs/{org_id}/policies/{policy_id}/events
# operationId: getOrgPolicyEvents
export def "orgs-policies-events get" [
  org_id: string
  policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/policies/($policy_id)/events" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all Projects for an Org with the given Org ID.
#
# GET /orgs/{org_id}/projects
# operationId: listOrgProjects
export def "orgs-projects listOrgProjects" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --target-id: list # Return projects that belong to the provided targets
  --target-reference: string # Return projects that match the provided target reference
  --target-file: string # Return projects that match the provided target file
  --target-runtime: string # Return projects that match the provided target runtime
  --meta-count: string@meta-count-completer-1 # The collection count.
  --ids: list # Return projects that match the provided IDs.
  --names: list # Return projects that match the provided names.
  --names-start-with: list # Return projects with names starting with the specified prefix.
  --origins: list # Return projects that match the provided origins.
  --types: list # Return projects that match the provided types.
  --expand: list # Expand relationships.
  --metalatest-issue-counts: string@bool-completer # Include a summary count for the issues found in the most recent scan of this project
  --metalatest-dependency-total: string@bool-completer # Include the total number of dependencies found in the most recent scan of this project
  --cli-monitored-before: string # Filter projects uploaded and monitored before this date (encoded value) (format: date-time, e.g. 2021-05-29T09:50:54.014Z)
  --cli-monitored-after: string # Filter projects uploaded and monitored after this date (encoded value) (format: date-time, e.g. 2021-05-29T09:50:54.014Z)
  --importing-user-public-id: list # Return projects that match the provided importing user public ids.
  --tags: list # Return projects that match all the provided tags (e.g. [key1:value1, key2:value2])
  --business-criticality: list # Return projects that match all the provided business_criticality value
  --environment: list # Return projects that match all the provided environment values
  --lifecycle: list # Return projects that match all the provided lifecycle values
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "target_id" $target_id "multi") (serialize-qp "target_reference" $target_reference "scalar") (serialize-qp "target_file" $target_file "scalar") (serialize-qp "target_runtime" $target_runtime "scalar") (serialize-qp "meta_count" $meta_count "scalar") (serialize-qp "ids" $ids "csv") (serialize-qp "names" $names "csv") (serialize-qp "names_start_with" $names_start_with "csv") (serialize-qp "origins" $origins "csv") (serialize-qp "types" $types "csv") (serialize-qp "expand" $expand "csv") (serialize-qp "meta.latest_issue_counts" $metalatest_issue_counts "scalar") (serialize-qp "meta.latest_dependency_total" $metalatest_dependency_total "scalar") (serialize-qp "cli_monitored_before" $cli_monitored_before "scalar") (serialize-qp "cli_monitored_after" $cli_monitored_after "scalar") (serialize-qp "importing_user_public_id" $importing_user_public_id "csv") (serialize-qp "tags" $tags "csv") (serialize-qp "business_criticality" $business_criticality "csv") (serialize-qp "environment" $environment "csv") (serialize-qp "lifecycle" $lifecycle "csv") (serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/projects" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete project by project ID.
#
# DELETE /orgs/{org_id}/projects/{project_id}
# operationId: deleteOrgProject
export def "orgs-projects delete" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/projects/($project_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project by project ID.
#
# GET /orgs/{org_id}/projects/{project_id}
# operationId: getOrgProject
export def "orgs-projects get" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: list # Expand relationships.
  --metalatest-issue-counts: string@bool-completer # Include a summary count for the issues found in the most recent scan of this project
  --metalatest-dependency-total: string@bool-completer # Include the total number of dependencies found in the most recent scan of this project
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv") (serialize-qp "meta.latest_issue_counts" $metalatest_issue_counts "scalar") (serialize-qp "meta.latest_dependency_total" $metalatest_dependency_total "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/projects/($project_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates project by project ID.
#
# PATCH /orgs/{org_id}/projects/{project_id}
# operationId: updateOrgProject
export def "orgs-projects updateOrgProject" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --expand: list # Expand relationships.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/projects/($project_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get a project’s SBOM document
#
# GET /orgs/{org_id}/projects/{project_id}/sbom
# operationId: getSbom
export def "orgs-projects-sbom get" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --format: string@format-completer # The desired SBOM format of the response. (e.g. cyclonedx1.6+json)
  --exclude: list # An array of features to be excluded from the generated SBOM.
  --go-module-level: string@bool-completer # When true, consolidate Go package-level dependencies into module-level components in the SBOM. Only applies to gomodules graphs; default is false. (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "exclude" $exclude "multi") (serialize-qp "go_module_level" $go_module_level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/projects/($project_id)/sbom" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an SBOM test run (Early Access)
#
# POST /orgs/{org_id}/sbom_tests
# operationId: createSbomTestRun
export def "orgs-sbom-tests createSbomTestRun" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/sbom_tests" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Gets an SBOM test run status (Early Access)
#
# GET /orgs/{org_id}/sbom_tests/{job_id}
# operationId: getSbomTestStatus
export def "orgs-sbom-tests get" [
  org_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/sbom_tests/($job_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets an SBOM test run result (Early Access)
#
# GET /orgs/{org_id}/sbom_tests/{job_id}/results
# operationId: getSbomTestResult
export def "orgs-sbom-tests-results get" [
  org_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --Accept: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/sbom_tests/($job_id)/results" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of organization service accounts.
#
# GET /orgs/{org_id}/service_accounts
# operationId: getManyOrgServiceAccounts
export def "orgs-service-accounts list" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/service_accounts" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a service account for an organization.
#
# POST /orgs/{org_id}/service_accounts
# operationId: createOrgServiceAccount
export def "orgs-service-accounts createOrgServiceAccount" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/service_accounts" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete a service account in an organization.
#
# DELETE /orgs/{org_id}/service_accounts/{serviceaccount_id}
# operationId: deleteServiceAccount
export def "orgs-service-accounts delete" [
  org_id: string
  serviceaccount_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/service_accounts/($serviceaccount_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an organization service account.
#
# GET /orgs/{org_id}/service_accounts/{serviceaccount_id}
# operationId: getOneOrgServiceAccount
export def "orgs-service-accounts get" [
  org_id: string
  serviceaccount_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/service_accounts/($serviceaccount_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an organization service account.
#
# PATCH /orgs/{org_id}/service_accounts/{serviceaccount_id}
# operationId: updateOrgServiceAccount
export def "orgs-service-accounts updateOrgServiceAccount" [
  org_id: string
  serviceaccount_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/service_accounts/($serviceaccount_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Manage an organization service account's client secret.
#
# POST /orgs/{org_id}/service_accounts/{serviceaccount_id}/secrets
# operationId: updateOrgServiceAccountSecret
export def "orgs-service-accounts-secrets updateOrgServiceAccountSecret" [
  org_id: string
  serviceaccount_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/service_accounts/($serviceaccount_id)/secrets" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get the Infrastructure as Code Settings for an org.
#
# GET /orgs/{org_id}/settings/iac
# operationId: getIacSettingsForOrg
export def "orgs-settings-iac get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/settings/iac" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the Infrastructure as Code Settings for an org
#
# PATCH /orgs/{org_id}/settings/iac
# operationId: updateIacSettingsForOrg
export def "orgs-settings-iac updateIacSettingsForOrg" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/settings/iac" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get language settings for an organization (Early Access)
#
# GET /orgs/{org_id}/settings/open_source/languages
# operationId: getOrgLanguagesSettings
export def "orgs-settings-open-source-languages get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/settings/open_source/languages" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update language settings for an organization (Early Access)
#
# PATCH /orgs/{org_id}/settings/open_source/languages/{language}
# operationId: updateOrgLanguagesSettings
export def "orgs-settings-open-source-languages updateOrgLanguagesSettings" [
  org_id: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/settings/open_source/languages/($language)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get the Open Source Settings for an Org. (Early Access)
#
# GET /orgs/{org_id}/settings/opensource
# operationId: getOpenSourceSettingsForOrg
export def "orgs-settings-opensource get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/settings/opensource" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete opensource broker setting for organization
#
# DELETE /orgs/{org_id}/settings/opensource/broker
# operationId: deleteOpensourceBrokerSettingForOrg
export def "orgs-settings-opensource-broker delete" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/settings/opensource/broker" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get opensource broker setting for organization
#
# GET /orgs/{org_id}/settings/opensource/broker
# operationId: getOpensourceBrokerSetting
export def "orgs-settings-opensource-broker list" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/settings/opensource/broker" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable opensource broker for organization
#
# POST /orgs/{org_id}/settings/opensource/broker
# operationId: enableOpensourceBrokerForOrg
export def "orgs-settings-opensource-broker enableOpensourceBrokerForOrg" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/settings/opensource/broker" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get opensource broker settings of ecosystem for organization
#
# GET /orgs/{org_id}/settings/opensource/{ecosystem}/broker
# operationId: getOpensourceBrokerEcosystemSettingsForOrg
export def "orgs-settings-opensource-broker get" [
  org_id: string
  ecosystem: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/settings/opensource/($ecosystem)/broker" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update opensource broker settings of ecosystem for organization
#
# PATCH /orgs/{org_id}/settings/opensource/{ecosystem}/broker
# operationId: updateOpensourceBrokerEcosystemSettingsForOrg
export def "orgs-settings-opensource-broker updateOpensourceBrokerEcosystemSettingsForOrg" [
  org_id: string
  ecosystem: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/settings/opensource/($ecosystem)/broker" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get opensource private registry settings of ecosystem for organization
#
# GET /orgs/{org_id}/settings/opensource/{ecosystem}/private-registries
# operationId: getOpensourcePrivateRegistryEcosystemSettingsForOrg
export def "orgs-settings-opensource-private-registries get" [
  org_id: string
  ecosystem: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/settings/opensource/($ecosystem)/private-registries" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update opensource private registry settings of ecosystem for organization
#
# PATCH /orgs/{org_id}/settings/opensource/{ecosystem}/private-registries
# operationId: updateOpensourcePrivateRegistryEcosystemSettingsForOrg
export def "orgs-settings-opensource-private-registries updateOpensourcePrivateRegistryEcosystemSettingsForOrg" [
  org_id: string
  ecosystem: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/settings/opensource/($ecosystem)/private-registries" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Retrieves the SAST settings for an org
#
# GET /orgs/{org_id}/settings/sast
# operationId: getSastSettings
export def "orgs-settings-sast get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/settings/sast" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable/Disable the Snyk Code settings for an org
#
# PATCH /orgs/{org_id}/settings/sast
# operationId: updateOrgSastSettings
export def "orgs-settings-sast updateOrgSastSettings" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/settings/sast" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Retrieves the Secrets settings for an org (Early Access)
#
# GET /orgs/{org_id}/settings/secrets
# operationId: getSecretsSettings
export def "orgs-settings-secrets get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/settings/secrets" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the Secrets settings for an org (Early Access)
#
# PATCH /orgs/{org_id}/settings/secrets
# operationId: updateOrgSecretsSettings
export def "orgs-settings-secrets updateOrgSecretsSettings" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/settings/secrets" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Remove the given Slack App integration
#
# DELETE /orgs/{org_id}/slack_app/{bot_id}
# operationId: deleteSlackDefaultNotificationSettings
export def "orgs-slack-app delete" [
  org_id: string
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/slack_app/($bot_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Slack integration default notification settings.
#
# GET /orgs/{org_id}/slack_app/{bot_id}
# operationId: getSlackDefaultNotificationSettings
export def "orgs-slack-app get" [
  org_id: string
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/slack_app/($bot_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new Slack notification default settings.
#
# POST /orgs/{org_id}/slack_app/{bot_id}
# operationId: createSlackDefaultNotificationSettings
export def "orgs-slack-app createSlackDefaultNotificationSettings" [
  org_id: string
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/slack_app/($bot_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Slack notification settings overrides for projects
#
# GET /orgs/{org_id}/slack_app/{bot_id}/projects
# operationId: getSlackProjectNotificationSettingsCollection
export def "orgs-slack-app-projects get" [
  org_id: string
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/slack_app/($bot_id)/projects" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove Slack settings override for a project.
#
# DELETE /orgs/{org_id}/slack_app/{bot_id}/projects/{project_id}
# operationId: deleteSlackProjectNotificationSettings
export def "orgs-slack-app-projects delete" [
  org_id: string
  project_id: string
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/slack_app/($bot_id)/projects/($project_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Slack notification settings for a project.
#
# PATCH /orgs/{org_id}/slack_app/{bot_id}/projects/{project_id}
# operationId: updateSlackProjectNotificationSettings
export def "orgs-slack-app-projects updateSlackProjectNotificationSettings" [
  org_id: string
  bot_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/slack_app/($bot_id)/projects/($project_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Create a new Slack settings override for a given project.
#
# POST /orgs/{org_id}/slack_app/{bot_id}/projects/{project_id}
# operationId: createSlackProjectNotificationSettings
export def "orgs-slack-app-projects createSlackProjectNotificationSettings" [
  org_id: string
  project_id: string
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/slack_app/($bot_id)/projects/($project_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get a list of Slack channels
#
# GET /orgs/{org_id}/slack_app/{tenant_id}/channels
# operationId: listChannels
export def "orgs-slack-app-channels listChannels" [
  org_id: string
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 1000, e.g. 100)
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/slack_app/($tenant_id)/channels" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Slack Channel name by Slack Channel ID.
#
# GET /orgs/{org_id}/slack_app/{tenant_id}/channels/{channel_id}
# operationId: getChannelNameById
export def "orgs-slack-app-channels get" [
  org_id: string
  channel_id: string
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/slack_app/($tenant_id)/channels/($channel_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get targets by org ID
#
# GET /orgs/{org_id}/targets
# operationId: getOrgsTargets
export def "orgs-targets list" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --count: string@bool-completer # Calculate total amount of filtered results
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --is-private: string@bool-completer # Return targets that match the provided value of is_private
  --exclude-empty: string@bool-completer # Return only the targets that has projects (default: true)
  --qp-url: string # Return targets that match the provided remote_url.
  --source-types: list # Return targets that match the provided source_types
  --display-name: string # Return targets with display names starting with the provided string
  --created-gte: string # Return only targets which have been created at or after the specified date.  (format: date-time, e.g. 2022-01-01T16:00:00Z)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "is_private" $is_private "scalar") (serialize-qp "exclude_empty" $exclude_empty "scalar") (serialize-qp "url" $qp_url "scalar") (serialize-qp "source_types" $source_types "csv") (serialize-qp "display_name" $display_name "scalar") (serialize-qp "created_gte" $created_gte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/targets" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete target by target ID
#
# DELETE /orgs/{org_id}/targets/{target_id}
# operationId: deleteOrgsTarget
export def "orgs-targets delete" [
  org_id: string
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/targets/($target_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get target by target ID
#
# GET /orgs/{org_id}/targets/{target_id}
# operationId: getOrgsTarget
export def "orgs-targets get" [
  org_id: string
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/targets/($target_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a test job. (Early Access)
#
# GET /orgs/{org_id}/test_jobs/{job_id}
# operationId: getJob
export def "orgs-test-jobs get" [
  org_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The API version requested.
  --snyk-request-id: string # A unique ID assigned to each API request, for tracing and troubleshooting.  Snyk clients can optionally provide this ID.
  --snyk-interaction-id: string # Identifies the Snyk client interaction in which this API request occurs.  The identifier is an opaque string. though at the time of writing it may either be a uuid or a urn containing a uuid and some metadata.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/test_jobs/($job_id)" $qp)
  let extra_headers = {"snyk-request-id": $snyk_request_id, "snyk-interaction-id": $snyk_interaction_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new test. (Early Access)
#
# POST /orgs/{org_id}/tests
# operationId: createTest
export def "orgs-tests createTest" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The API version requested.
  --snyk-request-id: string # A unique ID assigned to each API request, for tracing and troubleshooting.  Snyk clients can optionally provide this ID.
  --snyk-interaction-id: string # Identifies the Snyk client interaction in which this API request occurs.  The identifier is an opaque string. though at the time of writing it may either be a uuid or a urn containing a uuid and some metadata.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/tests" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"snyk-request-id": $snyk_request_id, "snyk-interaction-id": $snyk_interaction_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get a test. (Early Access)
#
# GET /orgs/{org_id}/tests/{test_id}
# operationId: getTest
export def "orgs-tests get" [
  org_id: string
  test_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The API version requested.
  --snyk-request-id: string # A unique ID assigned to each API request, for tracing and troubleshooting.  Snyk clients can optionally provide this ID.
  --snyk-interaction-id: string # Identifies the Snyk client interaction in which this API request occurs.  The identifier is an opaque string. though at the time of writing it may either be a uuid or a urn containing a uuid and some metadata.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/tests/($test_id)" $qp)
  let extra_headers = {"snyk-request-id": $snyk_request_id, "snyk-interaction-id": $snyk_interaction_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List findings for a test. (Early Access)
#
# GET /orgs/{org_id}/tests/{test_id}/findings
# operationId: listFindings
export def "orgs-tests-findings listFindings" [
  org_id: string
  test_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The API version requested.
  --starting-after: string # Opaque pagination cursor for forward traversal.
  --ending-before: string # Opaque pagination cursor for reverse traversal.
  --limit: int # The number of items to return. (format: int8, default: 10)
  --snyk-request-id: string # A unique ID assigned to each API request, for tracing and troubleshooting.  Snyk clients can optionally provide this ID.
  --snyk-interaction-id: string # Identifies the Snyk client interaction in which this API request occurs.  The identifier is an opaque string. though at the time of writing it may either be a uuid or a urn containing a uuid and some metadata.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/tests/($test_id)/findings" $qp)
  let extra_headers = {"snyk-request-id": $snyk_request_id, "snyk-interaction-id": $snyk_interaction_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user by ID (Early Access)
#
# GET /orgs/{org_id}/users/{id}
# operationId: getUser
export def "orgs-users get" [
  org_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_id)/users/($id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# My User Details
#
# GET /self
# operationId: getSelf
export def "self get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get access requests (Early Access)
#
# GET /self/access_requests
# operationId: getAccessRequests
export def "self-access-requests get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --org-id: list # The IDs of the org to filter by
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "org_id" $org_id "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/self/access_requests" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of Snyk Apps that can act on your behalf
#
# GET /self/apps
# operationId: getUserInstalledApps
export def "self-apps get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self/apps" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of Snyk Apps installed for a user
#
# GET /self/apps/installs
# operationId: getAppInstallsForUser
export def "self-apps-installs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: list # Expand relationships.
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "csv") (serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self/apps/installs" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke a Snyk App by install ID
#
# DELETE /self/apps/installs/{install_id}
# operationId: deleteUserAppInstallById
export def "self-apps-installs delete" [
  install_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/self/apps/installs/($install_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke a Snyk App by app ID
#
# DELETE /self/apps/{app_id}
# operationId: revokeUserInstalledApp
export def "self-apps revokeUserInstalledApp" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/self/apps/($app_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of active OAuth sessions by app ID
#
# GET /self/apps/{app_id}/sessions
# operationId: getUserAppSessions
export def "self-apps-sessions get" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/self/apps/($app_id)/sessions" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke the Snyk App session of an active user
#
# DELETE /self/apps/{app_id}/sessions/{session_id}
# operationId: revokeUserAppSession
export def "self-apps-sessions revokeUserAppSession" [
  app_id: string
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/self/apps/($app_id)/sessions/($session_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List personal access tokens
#
# GET /self/personal_access_tokens
# operationId: listPersonalAccessToken
export def "self-personal-access-tokens listPersonalAccessToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self/personal_access_tokens" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a personal access token
#
# DELETE /self/personal_access_tokens/{personal_access_token_id}
# operationId: deletePersonalAccessToken
export def "self-personal-access-tokens delete" [
  personal_access_token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/self/personal_access_tokens/($personal_access_token_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all accessible Tenants
#
# GET /tenants
# operationId: listTenants
export def "tenants listTenants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --name: string # Only return tenants whose name contains this value.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tenants" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single Tenant by ID
#
# GET /tenants/{tenant_id}
# operationId: getTenant
export def "tenants get" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update tenant
#
# PATCH /tenants/{tenant_id}
# operationId: updateTenant
export def "tenants updateTenant" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Integrations using the current Broker connection
#
# GET /tenants/{tenant_id}/brokers/connections/{connection_id}/integrations
# operationId: getBrokerConnectionIntegrations
export def "tenants-brokers-connections-integrations get" [
  tenant_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/connections/($connection_id)/integrations" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates Broker connection Integration Configuration
#
# POST /tenants/{tenant_id}/brokers/connections/{connection_id}/orgs/{org_id}/integration
# operationId: createBrokerConnectionIntegration
export def "tenants-brokers-connections-orgs-integration createBrokerConnectionIntegration" [
  tenant_id: string
  connection_id: string
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/connections/($connection_id)/orgs/($org_id)/integration" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Deletes an Integration for a Broker connection
#
# DELETE /tenants/{tenant_id}/brokers/connections/{connection_id}/orgs/{org_id}/integrations/{integration_id}
# operationId: deleteBrokerConnectionIntegration
export def "tenants-brokers-connections-orgs-integrations delete" [
  tenant_id: string
  connection_id: string
  org_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/connections/($connection_id)/orgs/($org_id)/integrations/($integration_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Broker deployments for tenant
#
# GET /tenants/{tenant_id}/brokers/deployments
# operationId: listBrokerDeploymentsForTenant
export def "tenants-brokers-deployments listBrokerDeploymentsForTenant" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/deployments" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Connection contexts
#
# GET /tenants/{tenant_id}/brokers/installs/{install_id}/connections/{connection_id}/contexts
# operationId: listConnectionContexts
export def "tenants-brokers-installs-connections-contexts listConnectionContexts" [
  tenant_id: string
  install_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/connections/($connection_id)/contexts" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes broker context
#
# DELETE /tenants/{tenant_id}/brokers/installs/{install_id}/contexts/{context_id}
# operationId: deleteBrokerContext
export def "tenants-brokers-installs-contexts delete" [
  tenant_id: string
  install_id: string
  context_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/contexts/($context_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Connection context
#
# GET /tenants/{tenant_id}/brokers/installs/{install_id}/contexts/{context_id}
# operationId: getConnectionContext
export def "tenants-brokers-installs-contexts get" [
  tenant_id: string
  install_id: string
  context_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/contexts/($context_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates Broker Context
#
# PATCH /tenants/{tenant_id}/brokers/installs/{install_id}/contexts/{context_id}
# operationId: updateBrokerContext
export def "tenants-brokers-installs-contexts updateBrokerContext" [
  tenant_id: string
  install_id: string
  context_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/contexts/($context_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Updates an integration to be associated with a Broker context
#
# PATCH /tenants/{tenant_id}/brokers/installs/{install_id}/contexts/{context_id}/integration
# operationId: updateBrokerContextIntegration
export def "tenants-brokers-installs-contexts-integration updateBrokerContextIntegration" [
  tenant_id: string
  install_id: string
  context_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/contexts/($context_id)/integration" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Deletes the Broker context association with an Integration
#
# DELETE /tenants/{tenant_id}/brokers/installs/{install_id}/contexts/{context_id}/integrations/{integration_id}
# operationId: deleteBrokerContextIntegration
export def "tenants-brokers-installs-contexts-integrations delete" [
  tenant_id: string
  install_id: string
  context_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/contexts/($context_id)/integrations/($integration_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Broker deployments
#
# GET /tenants/{tenant_id}/brokers/installs/{install_id}/deployments
# operationId: listBrokerDeployments
export def "tenants-brokers-installs-deployments listBrokerDeployments" [
  tenant_id: string
  install_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/deployments" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates Broker Deployment
#
# POST /tenants/{tenant_id}/brokers/installs/{install_id}/deployments
# operationId: createBrokerDeployment
export def "tenants-brokers-installs-deployments createBrokerDeployment" [
  tenant_id: string
  install_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/deployments" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Deletes Broker deployment
#
# DELETE /tenants/{tenant_id}/brokers/installs/{install_id}/deployments/{deployment_id}
# operationId: deleteBrokerDeployment
export def "tenants-brokers-installs-deployments delete" [
  tenant_id: string
  install_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/deployments/($deployment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates Broker deployment
#
# PATCH /tenants/{tenant_id}/brokers/installs/{install_id}/deployments/{deployment_id}
# operationId: updateBrokerDeployment
export def "tenants-brokers-installs-deployments updateBrokerDeployment" [
  tenant_id: string
  install_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/deployments/($deployment_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Deletes Broker connections
#
# DELETE /tenants/{tenant_id}/brokers/installs/{install_id}/deployments/{deployment_id}/connections
# operationId: deleteBrokerConnections
export def "tenants-brokers-installs-deployments-connections delete-by-tenant_id-install_id-deployment_id" [
  tenant_id: string
  install_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/deployments/($deployment_id)/connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Broker connections
#
# GET /tenants/{tenant_id}/brokers/installs/{install_id}/deployments/{deployment_id}/connections
# operationId: listBrokerConnections
export def "tenants-brokers-installs-deployments-connections listBrokerConnections" [
  tenant_id: string
  install_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/deployments/($deployment_id)/connections" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates Broker connection
#
# POST /tenants/{tenant_id}/brokers/installs/{install_id}/deployments/{deployment_id}/connections
# operationId: createBrokerConnection
export def "tenants-brokers-installs-deployments-connections createBrokerConnection" [
  tenant_id: string
  install_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/deployments/($deployment_id)/connections" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Deletes Broker connection
#
# DELETE /tenants/{tenant_id}/brokers/installs/{install_id}/deployments/{deployment_id}/connections/{connection_id}
# operationId: deleteBrokerConnection
export def "tenants-brokers-installs-deployments-connections delete-by-tenant_id-install_id-deployment_id-connection_id" [
  tenant_id: string
  install_id: string
  deployment_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/deployments/($deployment_id)/connections/($connection_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Broker connection
#
# GET /tenants/{tenant_id}/brokers/installs/{install_id}/deployments/{deployment_id}/connections/{connection_id}
# operationId: getBrokerConnection
export def "tenants-brokers-installs-deployments-connections get" [
  tenant_id: string
  install_id: string
  deployment_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/deployments/($deployment_id)/connections/($connection_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates Broker connection
#
# PATCH /tenants/{tenant_id}/brokers/installs/{install_id}/deployments/{deployment_id}/connections/{connection_id}
# operationId: updateBrokerConnection
export def "tenants-brokers-installs-deployments-connections updateBrokerConnection" [
  tenant_id: string
  install_id: string
  deployment_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/deployments/($deployment_id)/connections/($connection_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# List organizations for bulk migration
#
# GET /tenants/{tenant_id}/brokers/installs/{install_id}/deployments/{deployment_id}/connections/{connection_id}/bulk_migration
# operationId: listBrokerOrgsForBulkMigration
export def "tenants-brokers-installs-deployments-connections-bulk-migration listBrokerOrgsForBulkMigration" [
  connection_id: string
  deployment_id: string
  install_id: string
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/deployments/($deployment_id)/connections/($connection_id)/bulk_migration" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Performs bulk migration integrations to universal broker
#
# POST /tenants/{tenant_id}/brokers/installs/{install_id}/deployments/{deployment_id}/connections/{connection_id}/bulk_migration
# operationId: createBrokerOrgsForBulkMigration
export def "tenants-brokers-installs-deployments-connections-bulk-migration createBrokerOrgsForBulkMigration" [
  connection_id: string
  deployment_id: string
  install_id: string
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/deployments/($deployment_id)/connections/($connection_id)/bulk_migration" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# List Deployment contexts
#
# GET /tenants/{tenant_id}/brokers/installs/{install_id}/deployments/{deployment_id}/contexts
# operationId: listDeploymentContexts
export def "tenants-brokers-installs-deployments-contexts listDeploymentContexts" [
  tenant_id: string
  install_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/deployments/($deployment_id)/contexts" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create broker Context
#
# POST /tenants/{tenant_id}/brokers/installs/{install_id}/deployments/{deployment_id}/contexts
# operationId: createBrokerContext
export def "tenants-brokers-installs-deployments-contexts createBrokerContext" [
  tenant_id: string
  install_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/deployments/($deployment_id)/contexts" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# List Deployment credentials
#
# GET /tenants/{tenant_id}/brokers/installs/{install_id}/deployments/{deployment_id}/credentials
# operationId: listDeploymentCredentials
export def "tenants-brokers-installs-deployments-credentials listDeploymentCredentials" [
  tenant_id: string
  install_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/deployments/($deployment_id)/credentials" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create deployment credential
#
# POST /tenants/{tenant_id}/brokers/installs/{install_id}/deployments/{deployment_id}/credentials
# operationId: createDeploymentCredential
export def "tenants-brokers-installs-deployments-credentials createDeploymentCredential" [
  tenant_id: string
  install_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/deployments/($deployment_id)/credentials" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Deletes Deployment credential
#
# DELETE /tenants/{tenant_id}/brokers/installs/{install_id}/deployments/{deployment_id}/credentials/{credential_id}
# operationId: deleteDeploymentCredential
export def "tenants-brokers-installs-deployments-credentials delete" [
  tenant_id: string
  install_id: string
  deployment_id: string
  credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/deployments/($deployment_id)/credentials/($credential_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Deployment credential
#
# GET /tenants/{tenant_id}/brokers/installs/{install_id}/deployments/{deployment_id}/credentials/{credential_id}
# operationId: getDeploymentCredential
export def "tenants-brokers-installs-deployments-credentials get" [
  tenant_id: string
  install_id: string
  deployment_id: string
  credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/deployments/($deployment_id)/credentials/($credential_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates Deployment credential
#
# PATCH /tenants/{tenant_id}/brokers/installs/{install_id}/deployments/{deployment_id}/credentials/{credential_id}
# operationId: updateDeploymentCredential
export def "tenants-brokers-installs-deployments-credentials updateDeploymentCredential" [
  tenant_id: string
  install_id: string
  deployment_id: string
  credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2021-06-04)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/brokers/installs/($install_id)/deployments/($deployment_id)/credentials/($credential_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# List or search all assets (synchronous) (Early Access)
#
# GET /tenants/{tenant_id}/inventory/assets
# operationId: listAssetsTenant
export def "tenants-inventory-assets listAssetsTenant" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --filter: string # RSQL filter expression for filtering results. See schema for full documentation. (e.g. type==container_images;created_at>2024-01-01)
  --qp-sort: string # Comma-separated sort fields. Prefix with `-` for descending order.  **Supported fields:** - `created_at` - Asset creation timestamp - `updated_at` - Asset last update timestamp - `type` - Asset type (container_images) - `class` - Asset class - `risk_score` - Asset risk score (max across project sources) - `issues` - Issue counts by severity (critical, high, medium, low) - `built_at` - Image build timestamp (container images only) - `last_scan` - Last scan timestamp  (e.g. -created_at)
  --limit: int # Number of results to return per page (default: 10)
  --starting-after: string # Cursor for fetching the next page of results (e.g. v1.MTIzNDU2Nzg5MHxhYmNkZWY=)
  --ending-before: string # Cursor for fetching the previous page of results (e.g. v1.MTIzNDU2Nzg5MHxhYmNkZWY=)
  --qp-fields: record # Sparse fieldsets allow clients to request only specific fields for a given resource type. Use the format `fields[<type>]=field1,field2` where `<type>` is the JSON:API resource type.  **Container image fields** (use with `fields[container_images]`): - `class` - Classification of the asset - `registry` - Container registry hostname - `repository` - Repository path - `config_digest` - Image config digest - `distribution_digests` - Distribution digests (manifest/index pairs) - `image_tags` - Distinct image tags across all discovery sources - `built_at` - When the image was built - `size_bytes` - Size of the image in bytes - `author` - Image author - `architecture` - CPU architecture - `os` - Operating system - `variant` - CPU architecture variant - `os_version` - Operating system version - `os_features` - OS features - `config` - Image runtime configuration (OCI config) - `root_fs` - Root filesystem information - `history` - Image build history - `inferred_base_images` - Inferred base images - `teams` - Teams associated with the asset - `labels` - Labels associated with the asset - `tags` - Key-value tags for the asset - `risk_score` - Risk score for the asset - `test_surfaces` - Test surfaces for the asset - `issues` - Issue counts by severity - `created_at` - When the asset was created - `updated_at` - When the asset was last updated - `last_scan` - When the asset was last scanned - `scan_engines` - Scan engines applied to the asset  Note: `type` and `id` are always included regardless of field selection.  (e.g. {container_images: registry,repository,config_digest})
  --meta-count: string@meta-count-completer # Provide summary count in the response meta object when requested. When `with` is provided, the count will be included in the response meta object. When `only` is provided, the count will be included in the response meta object and no data will be returned.  (e.g. with)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "fields" $qp_fields "deepObject") (serialize-qp "meta_count" $meta_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/inventory/assets" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk update asset attributes (Early Access)
#
# PATCH /tenants/{tenant_id}/inventory/assets
# operationId: updateAssetsBulkTenant
export def "tenants-inventory-assets updateAssetsBulkTenant" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/inventory/assets" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Get available filter fields (Early Access)
#
# GET /tenants/{tenant_id}/inventory/assets/filters
# operationId: getFilterFieldsTenant
export def "tenants-inventory-assets-filters get" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --asset-types: string # Comma-separated list of asset types to filter the available filter fields (e.g. container_images)
  --limit: int # Number of results to return (default: 10)
  --starting-after: string # Cursor for fetching the next page of results
  --ending-before: string # Cursor for fetching the previous page of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "asset_types" $asset_types "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/inventory/assets/filters" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get filter value suggestions (autocomplete) (Early Access)
#
# GET /tenants/{tenant_id}/inventory/assets/filters/{filter_id}/values
# operationId: getFilterValuesTenant
export def "tenants-inventory-assets-filters-values get" [
  tenant_id: string
  filter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --q: string # Full text search term to filter the list of values. If keys_only is true, this will filter the keys of the object filter values. If key is provided, this will filter the value for the specific key of the object filter values. (e.g. prod)
  --limit: int # Number of results to return (default: 10)
  --starting-after: string # Cursor for fetching the next page of results
  --ending-before: string # Cursor for fetching the previous page of results
  --keys-only: string@bool-completer # Return only the keys of the object filter values
  --key: string # Return only the value for a specific key of the object filter values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "keys_only" $keys_only "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/inventory/assets/filters/($filter_id)/values" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get available group fields (Early Access)
#
# GET /tenants/{tenant_id}/inventory/assets/groups
# operationId: getGroupFieldsTenant
export def "tenants-inventory-assets-groups get" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --asset-types: string # Comma-separated list of asset types to filter the available group fields (e.g. container_images)
  --limit: int # Number of results to return (default: 10)
  --starting-after: string # Cursor for fetching the next page of results
  --ending-before: string # Cursor for fetching the previous page of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "asset_types" $asset_types "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/inventory/assets/groups" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get group value aggregation (Early Access)
#
# GET /tenants/{tenant_id}/inventory/assets/groups/{group_field_id}/values
# operationId: getGroupValuesTenant
export def "tenants-inventory-assets-groups-values get" [
  tenant_id: string
  group_field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --asset-types: string # Comma-separated list of asset types to filter the aggregation (e.g. container_images)
  --filter: string # RSQL filter expression for filtering which assets are included in aggregation. Supports the same syntax as the main search filter including full text search with the `q` field. See the RsqlFilterString schema for complete documentation.  (e.g. type==container_images;created_at>2024-01-01)
  --qp-sort: string # Comma-separated sort fields for group values. Prefix with `-` for descending order. Multiple sort fields are supported (e.g., `-issues,count`). Defaults to `created_at` (ascending) when not specified. Results are always tie-broken by `value` for deterministic ordering.  Available sort fields:   - `value` - Sort by the group value string (alphabetical)   - `count` - Sort by the number of assets in each group   - `created_at` - Sort by the aggregated created_at timestamp   - `last_seen_at` - Sort by the aggregated last_seen_at timestamp   - `updated_at` - Sort by the aggregated updated_at timestamp   - `risk_score` - Sort by the aggregated risk score   - `built_at` - Sort by the aggregated container image build timestamp   - `issues` - Sort by issue severity (critical → high → medium → low)  (e.g. -count)
  --limit: int # Number of results to return (default: 10)
  --starting-after: string # Cursor for fetching the next page of results
  --ending-before: string # Cursor for fetching the previous page of results
  --meta-fields: list # Meta fields to include in the response. Multiple fields can be specified.  Available fields:   - `count` - Number of assets with this value   - `created_at` - Aggregated asset creation timestamp (default aggregation: last)   - `last_seen_at` - Aggregated last_seen_at timestamp (default aggregation: last)   - `updated_at` - Aggregated updated_at timestamp (default aggregation: last)   - `risk_score` - Aggregated risk score from discovery sources (default aggregation: last)   - `issues` - Aggregated issue counts (critical, high, medium, low, total) (default aggregation: last)   - `labels` - Labels across assets (default aggregation: last)   - `tags` - Tags across assets (default aggregation: last)   - `built_at` - Aggregated container image build timestamp (default aggregation: last)   - `all` - Include all available meta fields  All fields default to the `last` aggregation function, which returns the value from the asset with the most recent updated_at in the group. Use the `aggregate` parameter to override the aggregation function per field.  If not specified, the meta object is not included in the response.  Note: Requesting meta fields may impact response time as aggregations require additional computation.  (e.g. [count, risk_score, issues, labels])
  --aggregate: record # Per-field aggregate function override for meta fields. All fields default to `last` when not specified. `max`/`min` compute the SQL MAX/MIN across all assets in the group (scalar fields only). `first`/`last` returns the value from the single asset with the earliest/latest updated_at in the group (all field types). `sum` computes the total across all assets (numeric fields, issues, labels, tags).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "asset_types" $asset_types "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "meta_fields" $meta_fields "csv") (serialize-qp "aggregate" $aggregate "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/inventory/assets/groups/($group_field_id)/values" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an asset search (asynchronous) (Early Access)
#
# POST /tenants/{tenant_id}/inventory/assets/searches
# operationId: createAssetSearchTenant
export def "tenants-inventory-assets-searches createAssetSearchTenant" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/inventory/assets/searches" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Retrieve asset search results (asynchronous) (Early Access)
#
# GET /tenants/{tenant_id}/inventory/assets/searches/{search_id}/results
# operationId: getAssetSearchResultsTenant
export def "tenants-inventory-assets-searches-results get" [
  tenant_id: string
  search_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --qp-sort: string # Comma-separated sort fields. Prefix with `-` for descending order.  **Supported fields:** - `created_at` - Asset creation timestamp - `updated_at` - Asset last update timestamp - `type` - Asset type (container_images) - `class` - Asset class - `risk_score` - Asset risk score (max across project sources) - `issues` - Issue counts by severity (critical, high, medium, low) - `built_at` - Image build timestamp (container images only) - `last_scan` - Last scan timestamp  (e.g. -created_at)
  --limit: int # Number of results to return (default: 10)
  --starting-after: string # Cursor for next page
  --ending-before: string # Cursor for previous page
  --qp-fields: record # Sparse fieldsets allow clients to request only specific fields for a given resource type. Use the format `fields[<type>]=field1,field2` where `<type>` is the JSON:API resource type.  **Container image fields** (use with `fields[container_images]`): - `class` - Classification of the asset - `registry` - Container registry hostname - `repository` - Repository path - `config_digest` - Image config digest - `distribution_digests` - Distribution digests (manifest/index pairs) - `image_tags` - Distinct image tags across all discovery sources - `built_at` - When the image was built - `size_bytes` - Size of the image in bytes - `author` - Image author - `architecture` - CPU architecture - `os` - Operating system - `variant` - CPU architecture variant - `os_version` - Operating system version - `os_features` - OS features - `config` - Image runtime configuration (OCI config) - `root_fs` - Root filesystem information - `history` - Image build history - `inferred_base_images` - Inferred base images - `teams` - Teams associated with the asset - `labels` - Labels associated with the asset - `tags` - Key-value tags for the asset - `risk_score` - Risk score for the asset - `test_surfaces` - Test surfaces for the asset - `issues` - Issue counts by severity - `created_at` - When the asset was created - `updated_at` - When the asset was last updated - `last_scan` - When the asset was last scanned - `scan_engines` - Scan engines applied to the asset  Note: `type` and `id` are always included regardless of field selection.  (e.g. {container_images: registry,repository,config_digest})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "fields" $qp_fields "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/inventory/assets/searches/($search_id)/results" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single asset by ID (Early Access)
#
# GET /tenants/{tenant_id}/inventory/assets/{asset_id}
# operationId: getAssetTenant
export def "tenants-inventory-assets get" [
  tenant_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --qp-fields: record # Sparse fieldsets allow clients to request only specific fields for a given resource type. Use the format `fields[<type>]=field1,field2` where `<type>` is the JSON:API resource type.  **Container image fields** (use with `fields[container_images]`): - `class` - Classification of the asset - `registry` - Container registry hostname - `repository` - Repository path - `config_digest` - Image config digest - `distribution_digests` - Distribution digests (manifest/index pairs) - `image_tags` - Distinct image tags across all discovery sources - `built_at` - When the image was built - `size_bytes` - Size of the image in bytes - `author` - Image author - `architecture` - CPU architecture - `os` - Operating system - `variant` - CPU architecture variant - `os_version` - Operating system version - `os_features` - OS features - `config` - Image runtime configuration (OCI config) - `root_fs` - Root filesystem information - `history` - Image build history - `inferred_base_images` - Inferred base images - `teams` - Teams associated with the asset - `labels` - Labels associated with the asset - `tags` - Key-value tags for the asset - `risk_score` - Risk score for the asset - `test_surfaces` - Test surfaces for the asset - `issues` - Issue counts by severity - `created_at` - When the asset was created - `updated_at` - When the asset was last updated - `last_scan` - When the asset was last scanned - `scan_engines` - Scan engines applied to the asset  Note: `type` and `id` are always included regardless of field selection.  (e.g. {container_images: registry,repository,config_digest})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "fields" $qp_fields "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/inventory/assets/($asset_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update asset attributes (Early Access)
#
# PATCH /tenants/{tenant_id}/inventory/assets/{asset_id}
# operationId: updateAssetTenant
export def "tenants-inventory-assets updateAssetTenant" [
  tenant_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/inventory/assets/($asset_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# List projects for an asset (Early Access)
#
# GET /tenants/{tenant_id}/inventory/assets/{asset_id}/relationships/projects
# operationId: listAssetProjectsTenant
export def "tenants-inventory-assets-relationships-projects listAssetProjectsTenant" [
  tenant_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --starting-after: string # Cursor for fetching the next page of results
  --ending-before: string # Cursor for fetching the previous page of results
  --limit: int # Maximum number of results to return per page (default: 10)
  --canonical: string@canonical-completer # Filter projects by canonical status. - `with`: Returns all projects (canonical attribute is populated). - `only`: Returns only canonical projects (those used for vulnerability counts). - `none`: Returns only non-canonical projects. When omitted, returns all projects without canonical filtering.
  --target-id: string # Filter projects by target ID. When provided, returns only projects that belong to the specified target. When omitted, returns projects from all targets.  (format: uuid)
  --qp-sort: string@sort-completer # Sort field with optional direction prefix. Prefix with `-` for descending order.  **Supported fields:** - `snapshot_created_at` - Snapshot creation timestamp - `issues` - Issue counts by severity (critical, high, medium, low)  When omitted, results are ordered by `snapshot_created_at` ascending.  (e.g. -snapshot_created_at)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "canonical" $canonical "scalar") (serialize-qp "target_id" $target_id "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/inventory/assets/($asset_id)/relationships/projects" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List targets for an asset (Early Access)
#
# GET /tenants/{tenant_id}/inventory/assets/{asset_id}/relationships/targets
# operationId: listAssetTargetsTenant
export def "tenants-inventory-assets-relationships-targets listAssetTargetsTenant" [
  tenant_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested API version (e.g. 2024-10-15)
  --starting-after: string # Cursor for fetching the next page of results
  --ending-before: string # Cursor for fetching the previous page of results
  --limit: int # Maximum number of results to return per page (default: 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/inventory/assets/($asset_id)/relationships/targets" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all memberships of the tenant (Early Access)
#
# GET /tenants/{tenant_id}/memberships
# operationId: getTenantMemberships
export def "tenants-memberships get" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
  --sort-by: string@sort-by-completer-1 # Which column to sort by.
  --sort-order: string@sort-order-completer # Order in which results are returned. (default: ASC, e.g. ASC)
  --email: string # Filter the response by Users that match the provided email
  --user-id: string # Filter the response by Users that match the provided user ID (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --name: string # Filter the response by Users that match the provided name
  --username: string # Filter the response by Users that match the provided username
  --connection-type: string # Filter the response by Users that match the provided connection type
  --role-name: string # Filter the response for results only with the specified role.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "connection_type" $connection_type "scalar") (serialize-qp "role_name" $role_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/memberships" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an individual tenant membership for a single user. (Early Access)
#
# DELETE /tenants/{tenant_id}/memberships/{membership_id}
# operationId: deleteTenantMembership
export def "tenants-memberships delete" [
  membership_id: string
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/memberships/($membership_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update tenant membership (Early Access)
#
# PATCH /tenants/{tenant_id}/memberships/{membership_id}
# operationId: updateTenantMembership
export def "tenants-memberships updateTenantMembership" [
  tenant_id: string
  membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/memberships/($membership_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# List all available roles for a given tenant (Early Access)
#
# GET /tenants/{tenant_id}/roles
# operationId: listTenantRoles
export def "tenants-roles listTenantRoles" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --name: string # Role name filter. (e.g. examplename)
  --custom: string@bool-completer # Whether role is custom or not. (e.g. false)
  --assignable-by-me: string@bool-completer # When true, only return roles that the current user can assign to others in the tenant. (e.g. false)
  --expand-permissions: string@bool-completer # option to show all permission types (default: false)
  --starting-after: string # Return the page of results immediately after this cursor (e.g. v1.eyJpZCI6IjEwMDAifQo=)
  --ending-before: string # Return the page of results immediately before this cursor (e.g. v1.eyJpZCI6IjExMDAifQo=)
  --limit: int # Number of results to return per page (format: int32, default: 10, e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "custom" $custom "scalar") (serialize-qp "assignable_by_me" $assignable_by_me "scalar") (serialize-qp "expand_permissions" $expand_permissions "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/roles" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a custom tenant role for a given tenant (Early Access)
#
# POST /tenants/{tenant_id}/roles
# operationId: createTenantRole
export def "tenants-roles createTenantRole" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/roles" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete a specific tenant role by its id and its tenant id. (Early Access)
#
# DELETE /tenants/{tenant_id}/roles/{role_id}
# operationId: deleteTenantRole
export def "tenants-roles delete" [
  tenant_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/roles/($role_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a specific role by its id and its tenant id. (Early Access)
#
# GET /tenants/{tenant_id}/roles/{role_id}
# operationId: getTenantRole
export def "tenants-roles get" [
  tenant_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --has-users-assigned: string@bool-completer # returns current memberships of the role in the meta relationships section (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "has_users_assigned" $has_users_assigned "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/roles/($role_id)" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a specific tenant role by its id and its tenant id. (Early Access)
#
# PATCH /tenants/{tenant_id}/roles/{role_id}
# operationId: updateTenantRole
export def "tenants-roles updateTenantRole" [
  tenant_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # The requested version of the endpoint to process the request (e.g. 2024-10-15)
  --force: string@bool-completer # flag to force the update of a role, required if users are assigned to the role (e.g. false)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tenants/($tenant_id)/roles/($role_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.api+json" $body
}
