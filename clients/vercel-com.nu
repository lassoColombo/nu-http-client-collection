# Auto-generated client for Vercel API v0.0.1
# Source: https://api.apis.guru/v2/specs/vercel.com/0.0.1/openapi.json
# Auth: --token flag or $env.VERCEL_API_TOKEN

const BASE_URL = "https://api.vercel.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VERCEL_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.vercel.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def conclusion-completer [] { ["canceled" "failed" "neutral" "skipped" "succeeded"] }
def status-completer [] { ["completed" "running"] }
def type-completer [] { ["A" "AAAA" "ALIAS" "CAA" "CNAME" "MX" "NS" "SRV" "TXT"] }
def view-completer [] { ["account" "project"] }
def provider-completer [] { ["bitbucket" "github" "gitlab"] }
def deliveryFormat-completer [] { ["json" "ndjson"] }
def environment-completer [] { ["preview" "production"] }
def confirmed-completer [] { ["true"] }
def type-completer-1 [] { ["encrypted" "plain" "secret" "sensitive" "system"] }
def forceNew-completer [] { ["0" "1"] }
def skipAutoDetectionConfirmation-completer [] { ["0" "1"] }
def framework-completer [] { ["" "angular" "astro" "blitzjs" "brunch" "create-react-app" "docusaurus" "docusaurus-2" "dojo" "eleventy" "ember" "gatsby" "gridsome" "hexo" "hugo" "hydrogen" "ionic-angular" "ionic-react" "jekyll" "middleman" "nextjs" "nuxtjs" "parcel" "polymer" "preact" "redwoodjs" "remix" "saber" "sanity" "sapper" "scully" "solidstart" "stencil" "svelte" "sveltekit" "sveltekit-1" "umijs" "vite" "vitepress" "vue" "vuepress" "zola"] }
def target-completer [] { ["production" "staging"] }
def direction-completer [] { ["backward" "forward"] }
def follow-completer [] { ["0" "1"] }
def delimiter-completer [] { ["0" "1"] }
def builds-completer [] { ["0" "1"] }
def accept-completer [] { ["application/json" "application/stream+json"] }
def deliveryFormat-completer-1 [] { ["json" "ndjson" "syslog"] }
def role-completer [] { ["DEVELOPER" "MEMBER" "OWNER" "VIEWER"] }
def decrypt-completer [] { ["false" "true"] }
def type-completer-2 [] { ["oauth2-token"] }
def type-completer-3 [] { ["new" "renewal"] }
def target-completer-1 [] { ["preview" "production"] }
def gitForkProtection-completer [] { ["0" "1"] }
def nodeVersion-completer [] { ["10.x" "12.x" "14.x" "16.x" "18.x"] }
def production-completer [] { ["false" "true"] }
def redirects-completer [] { ["false" "true"] }
def verified-completer [] { ["false" "true"] }
def order-completer [] { ["ASC" "DESC"] }
def redirectStatusCode-completer [] { ["" "301" "302" "307" "308"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "edge-config list" } } | get name | first)
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

# Get Edge Configs
#
# GET /edge-config
# operationId: getEdgeConfigs
export def "edge-config list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<createdAt: float, creator: string, domain: string, id: string, itemCount: float, name: string, recordType: string, sizeInBytes: float, ttl: float, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/edge-config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an Edge Config
#
# POST /edge-config
# operationId: createEdgeConfig
export def "edge-config createEdgeConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --items: record
  slug: string
]: any -> record<blocking: bool, completedAt: float, conclusion: string, createdAt: float, deploymentId: string, detailsUrl: string, externalId: string, id: string, integrationId: string, itemCount: float, name: string, output: record<metrics: record<CLS: record, FCP: record, LCP: record, TBT: record, virtualExperienceScore: record>>, path: string, rerequestable: bool, sizeInBytes: float, startedAt: float, status: string, updatedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/edge-config" $qp)
  let body = {items: $items, slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an Edge Config
#
# DELETE /edge-config/{edgeConfigId}
# operationId: deleteEdgeConfig
export def "edge-config delete" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/edge-config/($edgeConfigId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an Edge Config
#
# GET /edge-config/{edgeConfigId}
# operationId: getEdgeConfig
export def "edge-config get" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<createdAt: float, creator: string, domain: string, id: string, itemCount: float, name: string, recordType: string, sizeInBytes: float, ttl: float, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/edge-config/($edgeConfigId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Edge Config
#
# PUT /edge-config/{edgeConfigId}
# operationId: updateEdgeConfig
export def "edge-config updateEdgeConfig" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  slug: string
]: any -> record<blocking: bool, completedAt: float, conclusion: string, createdAt: float, deploymentId: string, detailsUrl: string, externalId: string, id: string, integrationId: string, itemCount: float, name: string, output: record<metrics: record<CLS: record, FCP: record, LCP: record, TBT: record, virtualExperienceScore: record>>, path: string, rerequestable: bool, sizeInBytes: float, startedAt: float, status: string, updatedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/edge-config/($edgeConfigId)" $qp)
  let body = {slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an Edge Config item
#
# GET /edge-config/{edgeConfigId}/item/{edgeConfigItemKey}
# operationId: getEdgeConfigItem
export def "edge-config-item get" [
  edgeConfigId: string
  edgeConfigItemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<createdAt: float, edgeConfigId: string, key: string, updatedAt: float, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/edge-config/($edgeConfigId)/item/($edgeConfigItemKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Edge Config items
#
# GET /edge-config/{edgeConfigId}/items
# operationId: getEdgeConfigItems
export def "edge-config-items get" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<createdAt: float, edgeConfigId: string, key: string, updatedAt: float, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/edge-config/($edgeConfigId)/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Edge Config items in batch
#
# PATCH /edge-config/{edgeConfigId}/items
# operationId: patchtEdgeConfigItems
export def "edge-config-items patchtEdgeConfigItems" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  items: list
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/edge-config/($edgeConfigId)/items" $qp)
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create an Edge Config token
#
# POST /edge-config/{edgeConfigId}/token
# operationId: createEdgeConfigToken
export def "edge-config-token createEdgeConfigToken" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  label: string
]: any -> record<id: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/edge-config/($edgeConfigId)/token" $qp)
  let body = {label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Edge Config token meta data
#
# GET /edge-config/{edgeConfigId}/token/{token}
# operationId: getEdgeConfigToken
export def "edge-config-token get" [
  edgeConfigId: string
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<createdAt: float, edgeConfigId: string, id: string, label: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/edge-config/($edgeConfigId)/token/($token)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete one or more Edge Config tokens
#
# DELETE /edge-config/{edgeConfigId}/tokens
# operationId: deleteEdgeConfigTokens
export def "edge-config-tokens delete" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  tokens: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/edge-config/($edgeConfigId)/tokens" $qp)
  let body = {tokens: $tokens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all tokens of an Edge Config
#
# GET /edge-config/{edgeConfigId}/tokens
# operationId: getEdgeConfigTokens
export def "edge-config-tokens get" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<createdAt: float, edgeConfigId: string, id: string, label: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/edge-config/($edgeConfigId)/tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Login with email
#
# POST /registration
# operationId: emailLogin
export def "registration emailLogin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The user email.
  --tokenName: string # The desired name for the token. It will be displayed on the user account details.
]: any -> record<securityCode: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/registration")
  let body = {email: $email, tokenName: $tokenName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Verify a login request to get an authentication token
#
# GET /registration/verify
# operationId: verifyToken
export def "registration-verify verifyToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email to verify the login.
  --qp-token: string # The token returned when the login was requested.
  --tokenName: string # The desired name for the token. It will be displayed on the user account details.
  --ssoUserId: string # The SAML Profile ID, when connecting a SAML Profile to a Team member for the first time.
]: nothing -> record<email: string, teamId: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "tokenName" $tokenName "scalar") (serialize-qp "ssoUserId" $ssoUserId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/registration/verify" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of all checks
#
# GET /v1/deployments/{deploymentId}/checks
# operationId: getAllChecks
export def "deployments-checks list" [
  deploymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<checks: table<completedAt: float, conclusion: string, createdAt: float, detailsUrl: string, id: string, integrationId: string, name: string, output: record, path: string, rerequestable: bool, startedAt: float, status: string, updatedAt: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/deployments/($deploymentId)/checks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Check
#
# POST /v1/deployments/{deploymentId}/checks
# operationId: createCheck
export def "deployments-checks createCheck" [
  deploymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --blocking: oneof<nothing, bool> # Whether the check should block a deployment from succeeding
  --detailsUrl: string # URL to display for further details
  --externalId: string # An identifier that can be used as an external reference
  name: string # The name of the check being created
  --path: string # Path of the page that is being checked
  --rerequestable: oneof<nothing, bool> # Whether a user should be able to request for the check to be rerun if it fails
]: any -> record<blocking: bool, completedAt: float, conclusion: string, createdAt: float, deploymentId: string, detailsUrl: string, externalId: string, id: string, integrationId: string, name: string, output: record<metrics: record<CLS: record, FCP: record, LCP: record, TBT: record, virtualExperienceScore: record>>, path: string, rerequestable: bool, startedAt: float, status: string, updatedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/deployments/($deploymentId)/checks" $qp)
  let body = {blocking: $blocking, detailsUrl: $detailsUrl, externalId: $externalId, name: $name, path: $path, rerequestable: $rerequestable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a single check
#
# GET /v1/deployments/{deploymentId}/checks/{checkId}
# operationId: getCheck
export def "deployments-checks get" [
  deploymentId: string
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<createdAt: float, creator: string, domain: string, id: string, name: string, recordType: string, ttl: float, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/deployments/($deploymentId)/checks/($checkId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a check
#
# PATCH /v1/deployments/{deploymentId}/checks/{checkId}
# operationId: updateCheck
# --output shape: {metrics?: record}
export def "deployments-checks updateCheck" [
  deploymentId: string
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --conclusion: any@conclusion-completer # The result of the check being run
  --detailsUrl: string # A URL a user may visit to see more information about the check
  --externalId: string # An identifier that can be used as an external reference
  --name: string # The name of the check being created
  --output: record # The results of the check Run — shape: {metrics?: record}
  --path: string # Path of the page that is being checked
  --status: any@status-completer # The current status of the check
]: any -> record<blocking: bool, completedAt: float, conclusion: string, createdAt: float, deploymentId: string, detailsUrl: string, externalId: string, id: string, integrationId: string, name: string, output: record<metrics: record<CLS: record, FCP: record, LCP: record, TBT: record, virtualExperienceScore: record>>, path: string, rerequestable: bool, startedAt: float, status: string, updatedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/deployments/($deploymentId)/checks/($checkId)" $qp)
  let body = {conclusion: $conclusion, detailsUrl: $detailsUrl, externalId: $externalId, name: $name, output: $output, path: $path, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Rerequest a check
#
# POST /v1/deployments/{deploymentId}/checks/{checkId}/rerequest
# operationId: rerequestCheck
export def "deployments-checks-rerequest rerequestCheck" [
  deploymentId: string
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/deployments/($deploymentId)/checks/($checkId)/rerequest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing DNS record
#
# PATCH /v1/domains/records/{recordId}
# operationId: updateRecord
# --srv shape: {port: int, priority: int, target: string, weight: int}
export def "domains-records updateRecord" [
  recordId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --mxPriority: int # The MX priority value of the DNS record (nullable)
  --name: string # The name of the DNS record (nullable)
  --srv: record # nullable — shape: {port: int, priority: int, target: string, weight: int}
  --ttl: int # The Time to live (TTL) value of the DNS record (nullable)
  --type: string@type-completer # The type of the DNS record (nullable)
  --value: string # The value of the DNS record (nullable)
]: any -> record<createdAt: float, creator: string, domain: string, id: string, name: string, recordType: string, ttl: float, type: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/domains/records/($recordId)" $qp)
  let body = {mxPriority: $mxPriority, name: $name, srv: $srv, ttl: $ttl, type: $type, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an integration configuration
#
# DELETE /v1/integrations/configuration/{id}
# operationId: deleteConfiguration
export def "integrations-configuration delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/integrations/configuration/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an integration configuration
#
# GET /v1/integrations/configuration/{id}
# operationId: getConfiguration
export def "integrations-configuration get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/integrations/configuration/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get configurations for the authenticated user or team
#
# GET /v1/integrations/configurations
# operationId: getConfigurations
export def "integrations-configurations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --view: string@view-completer
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "view" $view "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/integrations/configurations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List git namespaces by provider
#
# GET /v1/integrations/git-namespaces
# operationId: gitNamespaces
export def "integrations-git-namespaces gitNamespaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --provider: string@provider-completer
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> table<id: any, name: string, ownerType: string, provider: string, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "provider" $provider "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/integrations/git-namespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the Integration log drain with the provided `id`
#
# DELETE /v1/integrations/log-drains/{id}
# operationId: deleteIntegrationLogDrain
export def "integrations-log-drains delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/integrations/log-drains/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List git repositories linked to namespace by provider
#
# GET /v1/integrations/search-repo
export def "integrations-search-repo get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string
  --namespaceId: string
  --provider: string@provider-completer
  --installationId: string
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<gitAccount: record<namespaceId: any, provider: string>, repos: table<defaultBranch: string, id: any, name: string, namespace: string, ownerType: string, private: bool, slug: string, updatedAt: float, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "namespaceId" $namespaceId "scalar") (serialize-qp "provider" $provider "scalar") (serialize-qp "installationId" $installationId "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/integrations/search-repo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of Configurable Log Drains
#
# GET /v1/log-drains
# operationId: getConfigurableLogDrains
export def "log-drains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --projectId: string
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> table<branch: string, configurationId: string, createdAt: float, deliveryFormat: string, environment: string, headers: record, id: string, ownerId: string, projectIds: list<string>, sources: list<string>, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/log-drains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Configurable Log Drain
#
# POST /v1/log-drains
# operationId: createConfigurableLogDrain
export def "log-drains createConfigurableLogDrain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --branch: string # The branch regexp of log drain
  deliveryFormat: any@deliveryFormat-completer # The delivery log format
  --environment: any@environment-completer # The environment of log drain
  --headers: record # Headers to be sent together with the request
  --projectIds: list
  sources: list
  --body-url: string # The log drain url (format: uri)
]: any -> record<branch: string, configurationId: string, createdAt: float, deliveryFormat: string, environment: string, headers: record, id: string, ownerId: string, projectIds: list<string>, secret: string, sources: list<string>, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/log-drains" $qp)
  let body = {branch: $branch, deliveryFormat: $deliveryFormat, environment: $environment, headers: $headers, projectIds: $projectIds, sources: $sources, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a Configurable Log Drain
#
# DELETE /v1/log-drains/{id}
# operationId: deleteConfigurableLogDrain
export def "log-drains delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/log-drains/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a Configurable Log Drain
#
# GET /v1/log-drains/{id}
# operationId: getConfigurableLogDrain
export def "log-drains get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<branch: string, configurationId: string, createdAt: float, deliveryFormat: string, environment: string, headers: record, id: string, ownerId: string, projectIds: list<string>, sources: list<string>, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/log-drains/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the decrypted value of an environment variable of a project by id
#
# GET /v1/projects/{idOrName}/env/{id}
# operationId: getProjectEnv
export def "projects-env get" [
  idOrName: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($idOrName)/env/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Team
#
# POST /v1/teams
# operationId: createTeam
export def "teams createTeam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The desired name for the Team. It will be generated from the provided slug if nothing is provided
  slug: string # The desired slug for the Team
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/teams")
  let body = {name: $name, slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Team
#
# DELETE /v1/teams/{teamId}
# operationId: deleteTeam
# --reasons item shape: {description: string, slug: string}
export def "teams delete" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reasons: list # Optional array of objects that describe the reason why the team is being deleted. — item shape: {description: string, slug: string}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($teamId)")
  let body = {reasons: $reasons} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Team invite code
#
# DELETE /v1/teams/{teamId}/invites/{inviteId}
# operationId: deleteTeamInviteCode
export def "teams-invites delete" [
  inviteId: string
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($teamId)/invites/($inviteId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invite a user
#
# POST /v1/teams/{teamId}/members
# operationId: inviteUserToTeam
export def "teams-members inviteUserToTeam" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address of the user to invite (format: email)
  --role: any
  --uid: string # The id of the user to invite
]: any -> record<email: string, role: string, uid: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($teamId)/members")
  let body = {email: $email, role: $role, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Join a team
#
# POST /v1/teams/{teamId}/members/teams/join
# operationId: joinTeam
export def "teams-members-teams-join joinTeam" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --inviteCode: string # The invite code to join the team.
  --body-teamId: string # The team ID.
]: any -> record<from: string, name: string, slug: string, teamId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($teamId)/members/teams/join")
  let body = {inviteCode: $inviteCode, teamId: $body_teamId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a Team Member
#
# DELETE /v1/teams/{teamId}/members/{uid}
# operationId: removeTeamMember
export def "teams-members removeTeamMember" [
  uid: string
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($teamId)/members/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Team Member
#
# PATCH /v1/teams/{teamId}/members/{uid}
# operationId: updateTeamMember
# --joinedFrom shape: {ssoUserId?: any}
export def "teams-members updateTeamMember" [
  uid: string
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --confirmed: oneof<nothing, bool> # Accept a user who requested access to the team.
  --joinedFrom: record # shape: {ssoUserId?: any}
  --role: string # The role in the team of the member. (default: [MEMBER, VIEWER])
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($teamId)/members/($uid)")
  let body = {confirmed: $confirmed, joinedFrom: $joinedFrom, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request access to a team
#
# POST /v1/teams/{teamId}/request
# operationId: requestAccessToTeam
# --joinedFrom shape: {commitId?: string, gitUserId?: any, gitUserLogin?: string, origin: "import"|"teams"|"github"|"gitlab"|"bitbucket"|"feedback", repoId?: string, repoPath?: string}
export def "teams-request requestAccessToTeam" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  joinedFrom: record # shape: {commitId?: string, gitUserId?: any, gitUserLogin?: string, origin: "import"|"teams"|"github"|"gitlab"|"bitbucket"|"feedback", repoId?: string, repoPath?: string}
]: any -> record<accessRequestedAt: float, bitbucket: record<login: string>, confirmed: bool, github: record<login: string>, gitlab: record<login: string>, joinedFrom: record<commitId: string, dsyncConnectedAt: float, dsyncUserId: string, gitUserId: any, gitUserLogin: string, idpUserId: string, origin: string, repoId: string, repoPath: string, ssoConnectedAt: float, ssoUserId: string>, teamName: string, teamSlug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($teamId)/request")
  let body = {joinedFrom: $joinedFrom} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get access request status
#
# GET /v1/teams/{teamId}/request/{userId}
# operationId: getTeamAccessRequest
export def "teams-request get" [
  userId: string
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accessRequestedAt: float, bitbucket: record<login: string>, confirmed: bool, github: record<login: string>, gitlab: record<login: string>, joinedFrom: record<commitId: string, dsyncConnectedAt: float, dsyncUserId: string, gitUserId: any, gitUserLogin: string, idpUserId: string, origin: string, repoId: string, repoPath: string, ssoConnectedAt: float, ssoUserId: string>, teamName: string, teamSlug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($teamId)/request/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete User Account
#
# DELETE /v1/user
# operationId: requestDelete
# --reasons item shape: {description: string, slug: string}
export def "user requestDelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reasons: list # Optional array of objects that describe the reason why the User account is being deleted. — item shape: {description: string, slug: string}
]: any -> record<email: string, id: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/user")
  let body = {reasons: $reasons} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of webhooks
#
# GET /v1/webhooks
# operationId: getWebhooks
export def "webhooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --projectId: string
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a webhook
#
# POST /v1/webhooks
# operationId: createWebhook
export def "webhooks createWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  events: list
  --projectIds: list
  --body-url: string # format: uri
]: any -> record<createdAt: float, events: list<string>, id: string, ownerId: string, projectIds: list<string>, secret: string, updatedAt: float, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/webhooks" $qp)
  let body = {events: $events, projectIds: $projectIds, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a webhook
#
# DELETE /v1/webhooks/{id}
# operationId: deleteWebhook
export def "webhooks delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/webhooks/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a webhook
#
# GET /v1/webhooks/{id}
# operationId: getWebhook
export def "webhooks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<createdAt: float, events: list<string>, id: string, ownerId: string, projectIds: list<string>, updatedAt: float, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/webhooks/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create one or more environment variables
#
# POST /v10/projects/{idOrName}/env
# operationId: createProjectEnv
export def "projects-env createProjectEnv" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --gitBranch: string # The git branch of the environment variable (nullable)
  --key: string # The name of the environment variable
  --target: list # The target environment of the environment variable
  --type: string@type-completer-1 # The type of environment variable
  --value: string # The value of the environment variable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v10/projects/($idOrName)/env" $qp)
  let body = {gitBranch: $gitBranch, key: $key, target: $target, type: $type, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Deployment Builds
#
# GET /v11/deployments/{deploymentId}/builds
# operationId: listDeploymentBuilds
export def "deployments-builds listDeploymentBuilds" [
  deploymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<builds: table<config: record, copiedFrom: string, createdAt: float, createdIn: string, deployedAt: float, deploymentId: string, entrypoint: string, fingerprint: string, id: string, output: list, readyState: string, readyStateAt: float, scheduledAt: float, use: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v11/deployments/($deploymentId)/builds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel a deployment
#
# PATCH /v12/deployments/{id}/cancel
# operationId: cancelDeployment
export def "deployments-cancel cancelDeployment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<alias: list<string>, aliasAssigned: bool, aliasAssignedAt: any, aliasError: record<code: string, message: string>, aliasFinal: string, aliasWarning: record<action: string, code: string, link: string, message: string>, automaticAliases: list<string>, bootedAt: float, build: record<env: list<string>>, buildErrorAt: float, buildingAt: float, builds: table<config: record, src: string, use: string>, canceledAt: float, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record<uid: string, username: string>, env: list<string>, errorCode: string, errorLink: string, errorMessage: string, errorStep: string, functions: record, gitRepo: any, gitSource: any, id: string, inspectorUrl: string, isInConcurrentBuildsQueue: bool, lambdas: table<createdAt: float, entrypoint: string, id: string, output: list, readyState: string, readyStateAt: float>, meta: record, monorepoManager: string, name: string, ownerId: string, plan: string, previewCommentsEnabled: bool, projectId: string, public: bool, readyState: string, regions: list<string>, routes: list<any>, source: string, target: string, team: record<id: string, name: string, slug: string>, type: string, url: string, userAliases: list<string>, version: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v12/deployments/($id)/cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new deployment
#
# POST /v13/deployments
# operationId: createDeployment
# --build shape: {env?: record}
# --builds item shape: {config?: record, src?: string, use: string}
# --crons item shape: {path: string, schedule: string}
# --git shape: {deploymentEnabled?: any}
# --gitMetadata shape: {commitAuthorName?: string, commitMessage?: string, commitRef?: string, commitSha?: string, dirty?: bool, remoteUrl: string}
# --headers item shape: {has?: list, headers: list, missing?: list, source: string}
# --projectSettings shape: {buildCommand?: string, commandForIgnoringBuildStep?: string, devCommand?: string, framework?: ""|"blitzjs"|"nextjs"|"gatsby"|"remix"|"astro"|"hexo"|"eleventy"|"docusaurus-2"|"docusaurus"|"preact"|"solidstart"|"dojo"|"ember"|"vue"|"scully"|"ionic-angular"|"angular"|"polymer"|"svelte"|"sveltekit"|"sveltekit-1"|"ionic-react"|"create-react-app"|"gridsome"|"umijs"|"sapper"|"saber"|"stencil"|"nuxtjs"|"redwoodjs"|"hugo"|"jekyll"|"brunch"|"middleman"|"zola"|"hydrogen"|"vite"|"vitepress"|"vuepress"|"parcel"|"sanity", installCommand?: string, outputDirectory?: string, rootDirectory?: string, serverlessFunctionRegion?: string, skipGitConnectDuringLink?: bool, sourceFilesOutsideRootDirectory?: bool}
# --redirects item shape: {destination: string, has?: list, missing?: list, permanent?: bool, source: string}
# --rewrites item shape: {destination: string, has?: list, missing?: list, source: string}
@deprecated --flag build
@deprecated --flag builds
@deprecated --flag env
@deprecated --flag routes
export def "deployments createDeployment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forceNew: string@forceNew-completer # Forces a new deployment even if there is a previous similar deployment
  --skipAutoDetectionConfirmation: string@skipAutoDetectionConfirmation-completer # Allows to skip framework detection so the API would not fail to ask for confirmation
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --schema: string # Ignored. Can be set to get completions, validations and documentation in some editors.
  --alias: list # Aliases that will get assigned when the deployment is `READY` and the target is `production`. The client needs to make a `GET` request to its API to ensure the assignment
  --build: record # An object containing another object with information to be passed to the Build Process (DEPRECATED) — shape: {env?: record}
  --buildCommand: string # The build command for this project. When `null` is used this value will be automatically detected (nullable)
  --builds: list # A list of build descriptions whose src references valid source files. (DEPRECATED) — item shape: {config?: record, src?: string, use: string}
  --cleanUrls: oneof<nothing, bool> # When set to `true`, all HTML files and Serverless Functions will have their extension removed. When visiting a path that ends with the extension, a 308 response will redirect the client to the extensionless path.
  --crons: list # An array of cron jobs that should be created for production Deployments. — item shape: {path: string, schedule: string}
  --deploymentId: string # An deployment id for an existing deployment to redeploy
  --devCommand: string # The dev command for this project. When `null` is used this value will be automatically detected (nullable)
  --env: record # An object containing the deployment's environment variable names and values. Secrets can be referenced by prefixing the value with `@` (DEPRECATED)
  --files: list # A list of objects with the files to be deployed
  --framework: string@framework-completer # The framework that is being used for this project. When `null` is used no framework is selected (nullable)
  --functions: record # An object describing custom options for your Serverless Functions. Each key must be glob pattern that matches the paths of the Serverless Functions you would like to customize (like `api/*.js` or `api/test.js`).
  --git: record # shape: {deploymentEnabled?: any}
  --gitMetadata: record # Populates initial git metadata for different git providers. — shape: {commitAuthorName?: string, commitMessage?: string, commitRef?: string, commitSha?: string, dirty?: bool, remoteUrl: string}
  --gitSource: any # Defines the Git Repository source to be deployed. This property can not be used in combination with `files`.
  --headers: list # A list of header definitions. — item shape: {has?: list, headers: list, missing?: list, source: string}
  --ignoreCommand: string # nullable
  --installCommand: string # The install command for this project. When `null` is used this value will be automatically detected (nullable)
  --meta: record # An object containing the deployment's metadata. Multiple key-value pairs can be attached to a deployment
  --monorepoManager: string # The monorepo manager that is being used for this deployment. When `null` is used no monorepo manager is selected (nullable)
  name: string # A string with the project name used in the deployment URL
  --outputDirectory: string # The output directory of the project. When `null` is used this value will be automatically detected (nullable)
  --project: string # The target project identifier in which the deployment will be created. When defined, this parameter overrides name
  --projectSettings: record # Project settings that will be applied to the deployment. It is required for the first deployment of a project and will be saved for any following deployments — shape: {buildCommand?: string, commandForIgnoringBuildStep?: string, devCommand?: string, framework?: ""|"blitzjs"|"nextjs"|"gatsby"|"remix"|"astro"|"hexo"|"eleventy"|"docusaurus-2"|"docusaurus"|"preact"|"solidstart"|"dojo"|"ember"|"vue"|"scully"|"ionic-angular"|"angular"|"polymer"|"svelte"|"sveltekit"|"sveltekit-1"|"ionic-react"|"create-react-app"|"gridsome"|"umijs"|"sapper"|"saber"|"stencil"|"nuxtjs"|"redwoodjs"|"hugo"|"jekyll"|"brunch"|"middleman"|"zola"|"hydrogen"|"vite"|"vitepress"|"vuepress"|"parcel"|"sanity", installCommand?: string, outputDirectory?: string, rootDirectory?: string, serverlessFunctionRegion?: string, skipGitConnectDuringLink?: bool, sourceFilesOutsideRootDirectory?: bool}
  --public: oneof<nothing, bool> # Whether a deployment's source and logs are available publicly
  --redirects: list # A list of redirect definitions. — item shape: {destination: string, has?: list, missing?: list, permanent?: bool, source: string}
  --regions: list # An array of the regions the deployment's Serverless Functions should be deployed to
  --rewrites: list # A list of rewrite definitions. — item shape: {destination: string, has?: list, missing?: list, source: string}
  --routes: list # A list of routes objects used to rewrite paths to point towards other internal or external paths (DEPRECATED)
  --target: string@target-completer # Either not defined, `staging`, or `production`. If `staging`, a staging alias in the format `<project>.<team>.now.sh` will be assigned. If `production`, any aliases defined in `alias` will be assigned
  --trailingSlash: oneof<nothing, bool> # When `false`, visiting a path that ends with a forward slash will respond with a `308` status code and redirect to the path without the trailing slash.
  --withLatestCommit: oneof<nothing, bool> # When `true` and `deploymentId` is passed in, the sha from the previous deployment's `gitSource` is removed forcing the latest commit to be used.
]: any -> record<alias: list<string>, aliasAssigned: bool, aliasAssignedAt: any, aliasError: record<code: string, message: string>, aliasFinal: string, aliasWarning: record<action: string, code: string, link: string, message: string>, automaticAliases: list<string>, bootedAt: float, build: record<env: list<string>>, buildErrorAt: float, buildingAt: float, builds: list<record>, canceledAt: float, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record<uid: string, username: string>, env: list<string>, errorCode: string, errorLink: string, errorMessage: string, errorStep: string, functions: record, gitRepo: any, gitSource: any, id: string, inspectorUrl: string, isInConcurrentBuildsQueue: bool, lambdas: table<createdAt: float, entrypoint: string, id: string, output: list, readyState: string, readyStateAt: float>, meta: record, monorepoManager: string, name: string, ownerId: string, plan: string, previewCommentsEnabled: bool, projectId: string, public: bool, readyState: string, regions: list<string>, routes: list<any>, source: string, target: string, team: record<id: string, name: string, slug: string>, type: string, url: string, userAliases: list<string>, version: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceNew" $forceNew "scalar") (serialize-qp "skipAutoDetectionConfirmation" $skipAutoDetectionConfirmation "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v13/deployments" $qp)
  let body = {$schema: $schema, alias: $alias, build: $build, buildCommand: $buildCommand, builds: $builds, cleanUrls: $cleanUrls, crons: $crons, deploymentId: $deploymentId, devCommand: $devCommand, env: $env, files: $files, framework: $framework, functions: $functions, git: $git, gitMetadata: $gitMetadata, gitSource: $gitSource, headers: $headers, ignoreCommand: $ignoreCommand, installCommand: $installCommand, meta: $meta, monorepoManager: $monorepoManager, name: $name, outputDirectory: $outputDirectory, project: $project, projectSettings: $projectSettings, public: $public, redirects: $redirects, regions: $regions, rewrites: $rewrites, routes: $routes, target: $target, trailingSlash: $trailingSlash, withLatestCommit: $withLatestCommit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a deployment by ID or URL
#
# GET /v13/deployments/{idOrUrl}
# operationId: getDeployment
export def "deployments get" [
  idOrUrl: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --withGitRepoInfo: string # Whether to add in gitRepo information.
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withGitRepoInfo" $withGitRepoInfo "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v13/deployments/($idOrUrl)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Deployment
#
# DELETE /v13/deployments/{id}
# operationId: deleteDeployment
export def "deployments delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-url: string # A Deployment or Alias URL. In case it is passed, the ID will be ignored
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<state: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $qp_url "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v13/deployments/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Alias
#
# DELETE /v2/aliases/{aliasId}
# operationId: deleteAlias
export def "aliases delete" [
  aliasId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/aliases/($aliasId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get deployment events
#
# GET /v2/deployments/{idOrUrl}/events
# operationId: getDeploymentEvents
export def "deployments-events get" [
  idOrUrl: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --direction: string@direction-completer # Order of the returned events based on the timestamp. (default: forward)
  --follow: float@follow-completer # When enabled, this endpoint will return live events as they happen.
  --limit: float # Maximum number of events to return. Provide `-1` to return all available logs.
  --name: string # Deployment build ID.
  --since: float # Timestamp for when build logs should be pulled from.
  --until: float # Timestamp for when the build logs should be pulled up until.
  --statusCode: string # HTTP status code range to filter events by.
  --delimiter: float@delimiter-completer
  --builds: float@builds-completer
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "follow" $follow "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "statusCode" $statusCode "scalar") (serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "builds" $builds "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/deployments/($idOrUrl)/events" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Deployment Aliases
#
# GET /v2/deployments/{id}/aliases
# operationId: listDeploymentAliases
export def "deployments-aliases listDeploymentAliases" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<aliases: table<alias: string, created: string, protectionBypass: record, redirect: string, uid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/deployments/($id)/aliases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign an Alias
#
# POST /v2/deployments/{id}/aliases
# operationId: assignAlias
export def "deployments-aliases assignAlias" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --alias: string # The alias we want to assign to the deployment defined in the URL
  --redirect: string # The redirect property will take precedence over the deployment id from the URL and consists of a hostname (like test.com) to which the alias should redirect using status code 307 (nullable)
]: any -> record<alias: string, created: string, oldDeploymentId: string, uid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/deployments/($id)/aliases" $qp)
  let body = {alias: $alias, redirect: $redirect} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a DNS record
#
# POST /v2/domains/{domain}/records
# operationId: createRecord
# --srv shape: {port: any, priority: any, target?: string, weight: any}
export def "domains-records createRecord" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  type: string@type-completer # The type of record, it could be one of the valid DNS records.
  --name: string # A subdomain name or an empty string for the root domain.
  --ttl: float # The TTL value. Must be a number between 60 and 2147483647. Default value is 60.
  --value: string # The record value must be a valid IPv4 address. (format: ipv4)
  --mxPriority: float
  --srv: record # shape: {port: any, priority: any, target?: string, weight: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/domains/($domain)/records" $qp)
  let body = {type: $type, name: $name, ttl: $ttl, value: $value, mxPriority: $mxPriority, srv: $srv} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a DNS record
#
# DELETE /v2/domains/{domain}/records/{recordId}
# operationId: removeRecord
export def "domains-records removeRecord" [
  domain: string
  recordId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/domains/($domain)/records/($recordId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload Deployment Files
#
# POST /v2/files
# operationId: uploadFile
export def "files uploadFile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --Content-Length: float # The file size in bytes
  --x-vercel-digest: string # The file SHA1 used to check the integrity
  --x-now-digest: string # The file SHA1 used to check the integrity
  --x-now-size: float # The file size as an alternative to `Content-Length`
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/files" $qp)
  let extra_headers = {"Content-Length": $Content_Length, "x-vercel-digest": $x_vercel_digest, "x-now-digest": $x_now_digest, "x-now-size": $x_now_size} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of Integration log drains
#
# GET /v2/integrations/log-drains
# operationId: getIntegrationLogDrains
export def "integrations-log-drains get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> table<branch: string, clientId: string, configurationId: string, createdAt: float, createdFrom: string, deliveryFormat: string, environment: string, headers: record, id: string, name: string, ownerId: string, projectId: string, projectIds: list<string>, sources: list<string>, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/integrations/log-drains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Integration Log Drain
#
# POST /v2/integrations/log-drains
# operationId: createLogDrain
export def "integrations-log-drains createLogDrain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --branch: string # The branch regexp of log drain
  --deliveryFormat: any@deliveryFormat-completer-1 # The delivery log format
  --environment: any@environment-completer # The environment of log drain
  --headers: record # Headers to be sent together with the request
  name: string # The name of the log drain
  --projectIds: list
  --secret: string # A secret to sign log drain notification headers so a consumer can verify their authenticity
  --sources: list
  --body-url: string # The url where you will receive logs. The protocol must be `https://` or `http://` when type is `json` and `ndjson`, and `syslog+tls:` or `syslog:` when the type is `syslog`. (format: uri)
]: any -> record<branch: string, clientId: string, configurationId: string, createdAt: float, createdFrom: string, deliveryFormat: string, environment: string, headers: record, id: string, name: string, ownerId: string, projectId: string, projectIds: list<string>, sources: list<string>, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/integrations/log-drains" $qp)
  let body = {branch: $branch, deliveryFormat: $deliveryFormat, environment: $environment, headers: $headers, name: $name, projectIds: $projectIds, secret: $secret, sources: $sources, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a secret
#
# DELETE /v2/secrets/{idOrName}
# operationId: deleteSecret
export def "secrets delete" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<created: float, name: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/secrets/($idOrName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change secret name
#
# PATCH /v2/secrets/{name}
# operationId: renameSecret
export def "secrets renameSecret" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --body-name: string # The name of the new secret.
]: any -> record<created: string, name: string, oldName: string, uid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/secrets/($name)" $qp)
  let body = {name: $body_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new secret
#
# POST /v2/secrets/{name}
# operationId: createSecret
@deprecated --flag projectId
export def "secrets createSecret" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --decryptable: oneof<nothing, bool> # Whether the secret value can be decrypted after it has been created.
  --body-name: string # The name of the secret (max 100 characters).
  --projectId: string # Associate a secret to a project. (DEPRECATED)
  value: string # The value of the new secret.
]: any -> record<created: string, createdAt: float, decryptable: bool, name: string, projectId: string, teamId: string, uid: string, userId: string, value: record<data: list<float>, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/secrets/($name)" $qp)
  let body = {decryptable: $decryptable, name: $body_name, projectId: $projectId, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all teams
#
# GET /v2/teams
# operationId: getTeams
export def "teams list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # Maximum number of Teams which may be returned.
  --since: float # Timestamp (in milliseconds) to only include Teams created since then.
  --until: float # Timestamp (in milliseconds) to only include Teams created until then.
]: nothing -> record<pagination: record<count: float, next: float, prev: float>, teams: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Team
#
# GET /v2/teams/{teamId}
# operationId: getTeam
export def "teams get" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --slug: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($teamId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Team
#
# PATCH /v2/teams/{teamId}
# operationId: patchTeam
# --remoteCaching shape: {enabled?: bool}
# --saml shape: {enforced?: bool, roles?: record}
export def "teams patch" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatar: string # The hash value of an uploaded image. (format: regex)
  --description: string # A short text that describes the team.
  --emailDomain: string # nullable, format: regex
  --enablePreviewFeedback: string # Enable preview comments: one of on, off or default.
  --migrateExistingEnvVariablesToSensitive: oneof<nothing, bool> # Runs a task that migrates all existing environment variables to sensitive environment variables.
  --name: string # The name of the team.
  --previewDeploymentSuffix: string # Suffix that will be used for all preview deployments. (nullable, format: hostname)
  --regenerateInviteCode: oneof<nothing, bool> # Create a new invite code and replace the current one.
  --remoteCaching: record # Whether or not remote caching is enabled for the team — shape: {enabled?: bool}
  --saml: record # shape: {enforced?: bool, roles?: record}
  --sensitiveEnvironmentVariablePolicy: string # Sensitive environment variable policy: one of on, off or default.
  --slug: string # A new slug for the team.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/teams/($teamId)")
  let body = {avatar: $avatar, description: $description, emailDomain: $emailDomain, enablePreviewFeedback: $enablePreviewFeedback, migrateExistingEnvVariablesToSensitive: $migrateExistingEnvVariablesToSensitive, name: $name, previewDeploymentSuffix: $previewDeploymentSuffix, regenerateInviteCode: $regenerateInviteCode, remoteCaching: $remoteCaching, saml: $saml, sensitiveEnvironmentVariablePolicy: $sensitiveEnvironmentVariablePolicy, slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List team members
#
# GET /v2/teams/{teamId}/members
# operationId: getTeamMembers
export def "teams-members get" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # Limit how many teams should be returned
  --since: float # Timestamp in milliseconds to only include members added since then.
  --until: float # Timestamp in milliseconds to only include members added until then.
  --search: string # Search team members by their name, username, and email.
  --role: string@role-completer # Only return members with the specified team role.
  --excludeProject: string # Exclude members who belong to the specified project.
]: nothing -> record<emailInviteCodes: table<createdAt: float, email: string, id: string, isDSyncUser: bool, role: string>, members: table<accessRequestedAt: float, avatar: string, bitbucket: record, confirmed: bool, createdAt: float, email: string, github: record, gitlab: record, joinedFrom: record, name: string, role: string, uid: string, username: string>, pagination: record<count: float, hasNext: bool, next: float, prev: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "excludeProject" $excludeProject "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($teamId)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the User
#
# GET /v2/user
# operationId: getAuthUser
export def "user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<user: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List User Events
#
# GET /v3/events
# operationId: listUserEvents
export def "events listUserEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # Maximum number of items which may be returned.
  --since: string # Timestamp to only include items created since then.
  --until: string # Timestamp to only include items created until then.
  --types: string # Comma-delimited list of event \"types\" to filter the results by.
  --userId: string # When retrieving events for a Team, the `userId` parameter may be specified to filter events generated by a specific member of the Team.
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<events: table<createdAt: float, entities: list, id: string, text: string, user: record, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List secrets
#
# GET /v3/secrets
# operationId: getSecrets
export def "secrets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Filter out secrets based on comma separated secret ids.
  --projectId: string # Filter out secrets that belong to a project.
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<pagination: record<count: float, next: float, prev: float>, secrets: table<created: string, createdAt: float, decryptable: bool, name: string, projectId: string, teamId: string, uid: string, userId: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single secret
#
# GET /v3/secrets/{idOrName}
# operationId: getSecret
export def "secrets get" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --decrypt: string@decrypt-completer # Whether to try to decrypt the value of the secret. Only works if `decryptable` has been set to `true` when the secret was created.
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<created: string, createdAt: float, decryptable: bool, name: string, projectId: string, teamId: string, uid: string, userId: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "decrypt" $decrypt "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/secrets/($idOrName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an Auth Token
#
# POST /v3/user/tokens
# operationId: createAuthToken
export def "user-tokens createAuthToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --expiresAt: float
  --name: string
  --clientId: string
  --installationId: string
  --type: any@type-completer-2
]: any -> record<bearerToken: string, token: record<activeAt: float, createdAt: float, expiresAt: float, id: string, name: string, origin: string, scopes: list<any>, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/user/tokens" $qp)
  let body = {expiresAt: $expiresAt, name: $name, clientId: $clientId, installationId: $installationId, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an authentication token
#
# DELETE /v3/user/tokens/{tokenId}
# operationId: deleteAuthToken
export def "user-tokens delete" [
  tokenId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tokenId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/user/tokens/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List aliases
#
# GET /v4/aliases
# operationId: listAliases
export def "aliases listAliases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # Get only aliases of the given domain name
  --qp-from: float # Get only aliases created after the provided timestamp
  --limit: float # Maximum number of aliases to list from a request
  --projectId: string # Filter aliases from the given `projectId`
  --since: float # Get aliases created after this JavaScript timestamp
  --until: float # Get aliases created before this JavaScript timestamp
  --rollbackDeploymentId: string # Get aliases that would be rolled back for the given deployment
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<aliases: table<alias: string, created: string, createdAt: float, creator: record, deletedAt: float, deployment: record, deploymentId: string, projectId: string, protectionBypass: record, redirect: string, redirectStatusCode: float, uid: string, updatedAt: float>, pagination: record<count: float, next: float, prev: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "rollbackDeploymentId" $rollbackDeploymentId "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/aliases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an Alias
#
# GET /v4/aliases/{idOrAlias}
# operationId: getAlias
export def "aliases get" [
  idOrAlias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: float # Get the alias only if it was created after the provided timestamp
  --projectId: string # Get the alias only if it is assigned to the provided project ID
  --since: float # Get the alias only if it was created after this JavaScript timestamp
  --until: float # Get the alias only if it was created before this JavaScript timestamp
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<alias: string, created: string, createdAt: float, creator: record<email: string, uid: string, username: string>, deletedAt: float, deployment: record<id: string, meta: string, url: string>, deploymentId: string, projectId: string, protectionBypass: record, redirect: string, redirectStatusCode: float, uid: string, updatedAt: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/aliases/($idOrAlias)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register or transfer-in a new Domain
#
# POST /v4/domains
# operationId: createOrTransferDomain
export def "domains createOrTransferDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --method: string # The domain operation to perform. It can be either `add` or `transfer-in`.
  --name: string # The domain name you want to add.
  --body-token: string # The move-in token from Move Requested email.
  --authCode: string # The authorization code assigned to the domain.
  --expectedPrice: float # The price you expect to be charged for the required 1 year renewal.
  --cdnEnabled: oneof<nothing, bool> # Whether the domain has the Vercel Edge Network enabled or not.
]: any -> record<domain: record<boughtAt: float, createdAt: float, creator: record<customerId: string, email: string, id: string, isDomainReseller: bool, username: string>, customNameservers: list<string>, expiresAt: float, id: string, intendedNameservers: list<string>, name: string, nameservers: list<string>, orderedAt: float, renew: bool, serviceType: string, transferStartedAt: float, transferredAt: float, verified: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/domains" $qp)
  let body = {method: $method, name: $name, token: $body_token, authCode: $authCode, expectedPrice: $expectedPrice, cdnEnabled: $cdnEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Purchase a domain
#
# POST /v4/domains/buy
# operationId: buyDomain
export def "domains-buy buyDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --expectedPrice: float # The price you expect to be charged for the purchase.
  name: string # The domain name to purchase.
  --renew: oneof<nothing, bool> # Indicates whether the domain should be automatically renewed.
]: any -> record<domain: record<created: float, ns: list<string>, pending: bool, uid: string, verified: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/domains/buy" $qp)
  let body = {expectedPrice: $expectedPrice, name: $name, renew: $renew} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Check the price for a domain
#
# GET /v4/domains/price
# operationId: checkDomainPrice
export def "domains-price checkDomainPrice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the domain for which the price needs to be checked.
  --type: string@type-completer-3 # In which status of the domain the price needs to be checked.
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<period: float, price: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/domains/price" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check a Domain Availability
#
# GET /v4/domains/status
# operationId: checkDomainStatus
export def "domains-status checkDomainStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the domain for which we would like to check the status.
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<available: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/domains/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List existing DNS records
#
# GET /v4/domains/{domain}/records
# operationId: getRecords
export def "domains-records get" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Maximum number of records to list from a request.
  --since: string # Get records created after this JavaScript timestamp.
  --until: string # Get records created before this JavaScript timestamp.
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/domains/($domain)/records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the domains
#
# GET /v5/domains
# operationId: getDomains
export def "domains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # Maximum number of domains to list from a request.
  --since: float # Get domains created after this JavaScript timestamp.
  --until: float # Get domains created before this JavaScript timestamp.
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<domains: table<boughtAt: float, createdAt: float, creator: record, customNameservers: list, expiresAt: float, id: string, intendedNameservers: list, name: string, nameservers: list, orderedAt: float, renew: bool, serviceType: string, transferStartedAt: float, transferredAt: float, verified: bool>, pagination: record<count: float, next: float, prev: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v5/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Information for a Single Domain
#
# GET /v5/domains/{domain}
# operationId: getDomain
export def "domains get" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<domain: record<boughtAt: float, createdAt: float, creator: record<customerId: string, email: string, id: string, isDomainReseller: bool, username: string>, customNameservers: list<string>, expiresAt: float, id: string, intendedNameservers: list<string>, name: string, nameservers: list<string>, orderedAt: float, renew: bool, serviceType: string, suffix: bool, transferStartedAt: float, transferredAt: float, verified: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v5/domains/($domain)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Auth Tokens
#
# GET /v5/user/tokens
# operationId: listAuthTokens
export def "user-tokens listAuthTokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<pagination: record<count: float, next: float, prev: float>, testingToken: record<activeAt: float, createdAt: float, expiresAt: float, id: string, name: string, origin: string, scopes: list<any>, type: string>, tokens: table<activeAt: float, createdAt: float, expiresAt: float, id: string, name: string, origin: string, scopes: list, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v5/user/tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Auth Token Metadata
#
# GET /v5/user/tokens/{tokenId}
# operationId: getAuthToken
export def "user-tokens get" [
  tokenId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<token: record<activeAt: float, createdAt: float, expiresAt: float, id: string, name: string, origin: string, scopes: list<any>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v5/user/tokens/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List deployments
#
# GET /v6/deployments
# operationId: getDeployments
export def "deployments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app: string # Name of the deployment.
  --qp-from: float # Gets the deployment created after this Date timestamp. (default: current time)
  --limit: float # Maximum number of deployments to list from a request.
  --projectId: string # Filter deployments from the given `projectId`.
  --target: string@target-completer-1 # Filter deployments based on the environment.
  --qp-to: float # Gets the deployment created before this Date timestamp. (default: current time)
  --users: string # Filter out deployments based on users who have created the deployment.
  --since: float # Get Deployments created after this JavaScript timestamp.
  --until: float # Get Deployments created before this JavaScript timestamp.
  --state: string # Filter deployments based on their state (`BUILDING`, `ERROR`, `INITIALIZING`, `QUEUED`, `READY`, `CANCELED`)
  --rollbackCandidate: oneof<nothing, bool> # Filter deployments based on their rollback candidacy
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<deployments: table<aliasAssigned: any, aliasError: record, buildingAt: float, checksConclusion: string, checksState: string, created: float, createdAt: float, creator: record, inspectorUrl: string, isRollbackCandidate: bool, meta: record, name: string, ready: float, source: string, state: string, target: string, type: string, uid: string, url: string>, pagination: record<count: float, next: float, prev: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app" $app "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "target" $target "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "users" $users "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "rollbackCandidate" $rollbackCandidate "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v6/deployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Deployment Files
#
# GET /v6/deployments/{id}/files
# operationId: listDeploymentFiles
export def "deployments-files listDeploymentFiles" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> table<children: list<any>, contentType: string, mode: float, name: string, symlink: string, type: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v6/deployments/($id)/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Deployment File Contents
#
# GET /v6/deployments/{id}/files/{fileId}
# operationId: getDeploymentFileContents
export def "deployments-files get" [
  id: string
  fileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v6/deployments/($id)/files/($fileId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a domain by name
#
# DELETE /v6/domains/{domain}
# operationId: deleteDomain
export def "domains delete" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v6/domains/($domain)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Domain's configuration
#
# GET /v6/domains/{domain}/config
# operationId: getDomainConfig
export def "domains-config get" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<acceptedChallenges: list<string>, configuredBy: string, misconfigured: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v6/domains/($domain)/config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Issue a new cert
#
# POST /v7/certs
# operationId: issueCert
export def "certs issueCert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --cns: list # The common names the cert should be issued for
]: any -> record<autoRenew: bool, cns: list<string>, createdAt: float, expiresAt: float, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v7/certs" $qp)
  let body = {cns: $cns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upload a cert
#
# PUT /v7/certs
# operationId: uploadCert
export def "certs uploadCert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  ca: string # The certificate authority
  cert: string # The certificate
  key: string # The certificate key
  --skipValidation: oneof<nothing, bool> # Skip validation of the certificate
]: any -> record<autoRenew: bool, cns: list<string>, createdAt: float, expiresAt: float, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v7/certs" $qp)
  let body = {ca: $ca, cert: $cert, key: $key, skipValidation: $skipValidation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove cert
#
# DELETE /v7/certs/{id}
# operationId: removeCert
export def "certs removeCert" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v7/certs/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get cert by id
#
# GET /v7/certs/{id}
# operationId: getCertById
export def "certs get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<autoRenew: bool, cns: list<string>, createdAt: float, expiresAt: float, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v7/certs/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Query information about an artifact
#
# POST /v8/artifacts
# operationId: artifactQuery
export def "artifacts artifactQuery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  hashes: list # artifact hashes
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v8/artifacts" $qp)
  let body = {hashes: $hashes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Record an artifacts cache usage event
#
# POST /v8/artifacts/events
# operationId: recordEvents
export def "artifacts-events recordEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --x-artifact-client-ci: string # The continuous integration or delivery environment where this artifact is downloaded.
  --x-artifact-client-interactive: int # 1 if the client is an interactive shell. Otherwise 0
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v8/artifacts/events" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-artifact-client-ci": $x_artifact_client_ci, "x-artifact-client-interactive": $x_artifact_client_interactive} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get status of Remote Caching for this principal
#
# GET /v8/artifacts/status
# operationId: status
export def "artifacts-status status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v8/artifacts/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download a cache artifact
#
# GET /v8/artifacts/{hash}
# operationId: downloadArtifact
export def "artifacts downloadArtifact" [
  hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --x-artifact-client-ci: string # The continuous integration or delivery environment where this artifact is downloaded.
  --x-artifact-client-interactive: int # 1 if the client is an interactive shell. Otherwise 0
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v8/artifacts/($hash)" $qp)
  let extra_headers = {"x-artifact-client-ci": $x_artifact_client_ci, "x-artifact-client-interactive": $x_artifact_client_interactive} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if a cache artifact exists
#
# HEAD /v8/artifacts/{hash}
# operationId: artifactExists
export def "artifacts artifactExists" [
  hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v8/artifacts/($hash)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a cache artifact
#
# PUT /v8/artifacts/{hash}
# operationId: uploadArtifact
export def "artifacts uploadArtifact" [
  hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --Content-Length: float # The artifact size in bytes
  --x-artifact-duration: float # The time taken to generate the uploaded artifact in milliseconds.
  --x-artifact-client-ci: string # The continuous integration or delivery environment where this artifact was generated.
  --x-artifact-client-interactive: int # 1 if the client is an interactive shell. Otherwise 0
  --x-artifact-tag: string # The base64 encoded tag for this artifact. The value is sent back to clients when the artifact is downloaded as the header `x-artifact-tag`
  --body: record
]: any -> record<urls: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v8/artifacts/($hash)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Length": $Content_Length, "x-artifact-duration": $x_artifact_duration, "x-artifact-client-ci": $x_artifact_client_ci, "x-artifact-client-interactive": $x_artifact_client_interactive, "x-artifact-tag": $x_artifact_tag} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Retrieve a list of projects
#
# GET /v9/projects
# operationId: getProjects
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # Query only projects updated after the given timestamp
  --gitForkProtection: string@gitForkProtection-completer # Specifies whether PRs from Git forks should require a team member's authorization before it can be deployed
  --limit: string # Limit the number of projects returned
  --search: string # Search projects by the name field
  --repo: string # Filter results by repo. Also used for project count
  --repoId: string # Filter results by Repository ID.
  --repoUrl: string # Filter results by Repository URL.
  --excludeRepos: string # Filter results by excluding those projects that belong to a repo
  --edgeConfigId: string # Filter results by connected Edge Config ID
  --edgeConfigTokenId: string # Filter results by connected Edge Config Token ID
  --connectConfigurationId: string # Filter results by linked Connect configuration ID
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<pagination: record<count: float, next: float, prev: float>, projects: table<accountId: string, analytics: record, autoExposeSystemEnvs: bool, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurationId: string, createdAt: float, devCommand: string, directoryListing: bool, enablePreviewFeedback: bool, env: list, framework: string, gitForkProtection: bool, hasFloatingAliases: bool, id: string, installCommand: string, lastRollbackTarget: record, latestDeployments: list, link: any, live: bool, name: string, nodeVersion: string, outputDirectory: string, passwordProtection: record, permissions: record, protectionBypass: record, publicSource: bool, rootDirectory: string, serverlessFunctionRegion: string, skipGitConnectDuringLink: bool, sourceFilesOutsideRootDirectory: bool, ssoProtection: record, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "gitForkProtection" $gitForkProtection "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "repo" $repo "scalar") (serialize-qp "repoId" $repoId "scalar") (serialize-qp "repoUrl" $repoUrl "scalar") (serialize-qp "excludeRepos" $excludeRepos "scalar") (serialize-qp "edgeConfigId" $edgeConfigId "scalar") (serialize-qp "edgeConfigTokenId" $edgeConfigTokenId "scalar") (serialize-qp "connectConfigurationId" $connectConfigurationId "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v9/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new project
#
# POST /v9/projects
# operationId: createProject
# --environmentVariables item shape: {gitBranch?: string, key: string, target: any, type?: "system"|"secret"|"encrypted"|"plain", value: string}
# --gitRepository shape: {repo: string, type: "github"|"gitlab"|"bitbucket"}
@deprecated --flag skipGitConnectDuringLink
export def "projects createProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --buildCommand: string # The build command for this project. When `null` is used this value will be automatically detected (nullable)
  --commandForIgnoringBuildStep: string # nullable
  --devCommand: string # The dev command for this project. When `null` is used this value will be automatically detected (nullable)
  --environmentVariables: list # Collection of ENV Variables the Project will use — item shape: {gitBranch?: string, key: string, target: any, type?: "system"|"secret"|"encrypted"|"plain", value: string}
  --framework: any@framework-completer # The framework that is being used for this project. When `null` is used no framework is selected
  --gitRepository: record # The Git Repository that will be connected to the project. When this is defined, any pushes to the specified connected Git Repository will be automatically deployed — shape: {repo: string, type: "github"|"gitlab"|"bitbucket"}
  --installCommand: string # The install command for this project. When `null` is used this value will be automatically detected (nullable)
  name: string # The desired name for the project
  --outputDirectory: string # The output directory of the project. When `null` is used this value will be automatically detected (nullable)
  --publicSource: oneof<nothing, bool> # Specifies whether the source code and logs of the deployments for this project should be public or not (nullable)
  --rootDirectory: string # The name of a directory or relative path to the source code of your project. When `null` is used it will default to the project root (nullable)
  --serverlessFunctionRegion: string # The region to deploy Serverless Functions in this project (nullable)
  --skipGitConnectDuringLink: oneof<nothing, bool> # Opts-out of the message prompting a CLI user to connect a Git repository in `vercel link`. (DEPRECATED)
]: any -> record<accountId: string, analytics: record<canceledAt: float, disabledAt: float, enabledAt: float, id: string, paidAt: float, sampleRatePercent: float, spendLimitInDollars: float>, autoExposeSystemEnvs: bool, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurationId: string, createdAt: float, devCommand: string, directoryListing: bool, enablePreviewFeedback: bool, env: table<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string>, framework: string, gitForkProtection: bool, hasFloatingAliases: bool, id: string, installCommand: string, lastRollbackTarget: record<fromDeploymentId: string, jobStatus: string, requestedAt: float, toDeploymentId: string>, latestDeployments: table<alias: list, aliasAssigned: any, aliasError: record, aliasFinal: string, automaticAliases: list, buildingAt: float, builds: list, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record, deploymentHostname: string, forced: bool, id: string, meta: record, monorepoManager: string, name: string, plan: string, previewCommentsEnabled: bool, private: bool, readyAt: float, readyState: string, requestedAt: float, target: string, teamId: string, type: string, url: string, userId: string, withCache: bool>, link: any, live: bool, name: string, nodeVersion: string, outputDirectory: string, passwordProtection: record<deploymentType: string>, permissions: record<Monitoring: list<string>, aliasGlobal: list<string>, aliasProject: list<string>, aliasProtectionBypass: list<string>, analytics: list<string>, analyticsSampling: list<string>, analyticsUsage: list<string>, auditLog: list<string>, awsBillingIntegration: list<string>, billingAddress: list<string>, billingInformation: list<string>, billingInvoice: list<string>, billingInvoiceEmailRecipient: list<string>, billingInvoiceLanguage: list<string>, billingPlan: list<string>, billingPurchaseOrder: list<string>, billingTaxId: list<string>, cacheArtifact: list<string>, cacheArtifactUsageEvent: list<string>, concurrentBuilds: list<string>, connect: list<string>, connectConfiguration: list<string>, connectConfigurationLink: list<string>, deployment: list<string>, deploymentCheck: list<string>, deploymentCheckPreview: list<string>, deploymentPreview: list<string>, deploymentPrivate: list<string>, deploymentProductionGit: list<string>, deploymentRollback: list<string>, domain: list<string>, domainAcceptDelegation: list<string>, domainAuthCodes: list<string>, domainCertificate: list<string>, domainCheckConfig: list<string>, domainMove: list<string>, domainPurchase: list<string>, domainRecord: list<string>, domainTransferIn: list<string>, edgeConfig: list<string>, edgeConfigItem: list<string>, edgeConfigToken: list<string>, endpointVerification: list<string>, event: list<string>, fileUpload: list<string>, gitRepository: list<string>, integration: list<string>, integrationConfiguration: list<string>, integrationConfigurationProjects: list<string>, integrationConfigurationTransfer: list<string>, integrationVercelConfigurationOverride: list<string>, job: list<string>, logDrain: list<string>, monitoringChart: list<string>, monitoringQuery: list<string>, notificationDomainConfiguration: list<string>, notificationDomainExpire: list<string>, notificationDomainMoved: list<string>, notificationDomainPurchase: list<string>, notificationDomainRenewal: list<string>, notificationDomainTransfer: list<string>, notificationDomainUnverified: list<string>, notificationPaymentFailed: list<string>, notificationSpendCap: list<string>, notificationUsageAlert: list<string>, openTelemetryEndpoint: list<string>, passwordProtection: list<string>, paymentMethod: list<string>, permissions: list<string>, previewDeploymentSuffix: list<string>, proTrialOnboarding: list<string>, project: list<string>, projectDeploymentHook: list<string>, projectDomain: list<string>, projectDomainMove: list<string>, projectEnvVars: list<string>, projectEnvVarsProduction: list<string>, projectEnvVarsUnownedByIntegration: list<string>, projectIntegrationConfiguration: list<string>, projectLink: list<string>, projectMember: list<string>, projectProductionBranch: list<string>, projectProtectionBypass: list<string>, projectTransfer: list<string>, rateLimit: list<string>, redis: list<string>, remoteCaching: list<string>, samlConfig: list<string>, secret: list<string>, sensitiveEnvironmentVariablePolicy: list<string>, sharedEnvVars: list<string>, sharedEnvVarsProduction: list<string>, spendCapConfiguration: list<string>, spendCapState: list<string>, supportCase: list<string>, supportCaseComment: list<string>, team: list<string>, teamAccessRequest: list<string>, teamFellowMembership: list<string>, teamInvite: list<string>, teamInviteCode: list<string>, teamJoin: list<string>, teamOwnMembership: list<string>, teamOwnMembershipDisconnectSAML: list<string>, token: list<string>, usage: list<string>, user: list<string>, userConnection: list<string>, webAnalytics: list<string>, webhook: list<string>, webhook_event: list<string>>, protectionBypass: record, publicSource: bool, rootDirectory: string, serverlessFunctionRegion: string, skipGitConnectDuringLink: bool, sourceFilesOutsideRootDirectory: bool, ssoProtection: record<deploymentType: string>, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v9/projects" $qp)
  let body = {buildCommand: $buildCommand, commandForIgnoringBuildStep: $commandForIgnoringBuildStep, devCommand: $devCommand, environmentVariables: $environmentVariables, framework: $framework, gitRepository: $gitRepository, installCommand: $installCommand, name: $name, outputDirectory: $outputDirectory, publicSource: $publicSource, rootDirectory: $rootDirectory, serverlessFunctionRegion: $serverlessFunctionRegion, skipGitConnectDuringLink: $skipGitConnectDuringLink} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Project
#
# DELETE /v9/projects/{idOrName}
# operationId: deleteProject
export def "projects delete" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find a project by id or name
#
# GET /v9/projects/{idOrName}
# operationId: getProject
export def "projects get" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<accountId: string, analytics: record<canceledAt: float, disabledAt: float, enabledAt: float, id: string, paidAt: float, sampleRatePercent: float, spendLimitInDollars: float>, autoExposeSystemEnvs: bool, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurationId: string, createdAt: float, devCommand: string, directoryListing: bool, enablePreviewFeedback: bool, env: table<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string>, framework: string, gitForkProtection: bool, hasFloatingAliases: bool, id: string, installCommand: string, lastRollbackTarget: record<fromDeploymentId: string, jobStatus: string, requestedAt: float, toDeploymentId: string>, latestDeployments: table<alias: list, aliasAssigned: any, aliasError: record, aliasFinal: string, automaticAliases: list, buildingAt: float, builds: list, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record, deploymentHostname: string, forced: bool, id: string, meta: record, monorepoManager: string, name: string, plan: string, previewCommentsEnabled: bool, private: bool, readyAt: float, readyState: string, requestedAt: float, target: string, teamId: string, type: string, url: string, userId: string, withCache: bool>, link: any, live: bool, name: string, nodeVersion: string, outputDirectory: string, passwordProtection: record<deploymentType: string>, permissions: record<Monitoring: list<string>, aliasGlobal: list<string>, aliasProject: list<string>, aliasProtectionBypass: list<string>, analytics: list<string>, analyticsSampling: list<string>, analyticsUsage: list<string>, auditLog: list<string>, awsBillingIntegration: list<string>, billingAddress: list<string>, billingInformation: list<string>, billingInvoice: list<string>, billingInvoiceEmailRecipient: list<string>, billingInvoiceLanguage: list<string>, billingPlan: list<string>, billingPurchaseOrder: list<string>, billingTaxId: list<string>, cacheArtifact: list<string>, cacheArtifactUsageEvent: list<string>, concurrentBuilds: list<string>, connect: list<string>, connectConfiguration: list<string>, connectConfigurationLink: list<string>, deployment: list<string>, deploymentCheck: list<string>, deploymentCheckPreview: list<string>, deploymentPreview: list<string>, deploymentPrivate: list<string>, deploymentProductionGit: list<string>, deploymentRollback: list<string>, domain: list<string>, domainAcceptDelegation: list<string>, domainAuthCodes: list<string>, domainCertificate: list<string>, domainCheckConfig: list<string>, domainMove: list<string>, domainPurchase: list<string>, domainRecord: list<string>, domainTransferIn: list<string>, edgeConfig: list<string>, edgeConfigItem: list<string>, edgeConfigToken: list<string>, endpointVerification: list<string>, event: list<string>, fileUpload: list<string>, gitRepository: list<string>, integration: list<string>, integrationConfiguration: list<string>, integrationConfigurationProjects: list<string>, integrationConfigurationTransfer: list<string>, integrationVercelConfigurationOverride: list<string>, job: list<string>, logDrain: list<string>, monitoringChart: list<string>, monitoringQuery: list<string>, notificationDomainConfiguration: list<string>, notificationDomainExpire: list<string>, notificationDomainMoved: list<string>, notificationDomainPurchase: list<string>, notificationDomainRenewal: list<string>, notificationDomainTransfer: list<string>, notificationDomainUnverified: list<string>, notificationPaymentFailed: list<string>, notificationSpendCap: list<string>, notificationUsageAlert: list<string>, openTelemetryEndpoint: list<string>, passwordProtection: list<string>, paymentMethod: list<string>, permissions: list<string>, previewDeploymentSuffix: list<string>, proTrialOnboarding: list<string>, project: list<string>, projectDeploymentHook: list<string>, projectDomain: list<string>, projectDomainMove: list<string>, projectEnvVars: list<string>, projectEnvVarsProduction: list<string>, projectEnvVarsUnownedByIntegration: list<string>, projectIntegrationConfiguration: list<string>, projectLink: list<string>, projectMember: list<string>, projectProductionBranch: list<string>, projectProtectionBypass: list<string>, projectTransfer: list<string>, rateLimit: list<string>, redis: list<string>, remoteCaching: list<string>, samlConfig: list<string>, secret: list<string>, sensitiveEnvironmentVariablePolicy: list<string>, sharedEnvVars: list<string>, sharedEnvVarsProduction: list<string>, spendCapConfiguration: list<string>, spendCapState: list<string>, supportCase: list<string>, supportCaseComment: list<string>, team: list<string>, teamAccessRequest: list<string>, teamFellowMembership: list<string>, teamInvite: list<string>, teamInviteCode: list<string>, teamJoin: list<string>, teamOwnMembership: list<string>, teamOwnMembershipDisconnectSAML: list<string>, token: list<string>, usage: list<string>, user: list<string>, userConnection: list<string>, webAnalytics: list<string>, webhook: list<string>, webhook_event: list<string>>, protectionBypass: record, publicSource: bool, rootDirectory: string, serverlessFunctionRegion: string, skipGitConnectDuringLink: bool, sourceFilesOutsideRootDirectory: bool, ssoProtection: record<deploymentType: string>, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing project
#
# PATCH /v9/projects/{idOrName}
# operationId: updateProject
# --passwordProtection shape: {deploymentType: "all"|"preview", password?: string}
# --ssoProtection shape: {deploymentType: "all"|"preview"}
@deprecated --flag skipGitConnectDuringLink
export def "projects updateProject" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --autoExposeSystemEnvs: oneof<nothing, bool>
  --buildCommand: string # The build command for this project. When `null` is used this value will be automatically detected (nullable)
  --commandForIgnoringBuildStep: string # nullable
  --devCommand: string # The dev command for this project. When `null` is used this value will be automatically detected (nullable)
  --directoryListing: oneof<nothing, bool>
  --enablePreviewFeedback: oneof<nothing, bool> # Opt-in to Preview comments on the project level (nullable)
  --framework: string@framework-completer # The framework that is being used for this project. When `null` is used no framework is selected (nullable)
  --gitForkProtection: oneof<nothing, bool> # Specifies whether PRs from Git forks should require a team member's authorization before it can be deployed
  --installCommand: string # The install command for this project. When `null` is used this value will be automatically detected (nullable)
  --name: string # The desired name for the project
  --nodeVersion: string@nodeVersion-completer
  --outputDirectory: string # The output directory of the project. When `null` is used this value will be automatically detected (nullable)
  --passwordProtection: record # Allows to protect project deployments with a password (nullable) — shape: {deploymentType: "all"|"preview", password?: string}
  --publicSource: oneof<nothing, bool> # Specifies whether the source code and logs of the deployments for this project should be public or not (nullable)
  --rootDirectory: string # The name of a directory or relative path to the source code of your project. When `null` is used it will default to the project root (nullable)
  --serverlessFunctionRegion: string # The region to deploy Serverless Functions in this project (nullable)
  --skipGitConnectDuringLink: oneof<nothing, bool> # Opts-out of the message prompting a CLI user to connect a Git repository in `vercel link`. (DEPRECATED)
  --sourceFilesOutsideRootDirectory: oneof<nothing, bool> # Indicates if there are source files outside of the root directory
  --ssoProtection: record # Ensures visitors to your Preview Deployments are logged into Vercel and have a minimum of Viewer access on your team (nullable) — shape: {deploymentType: "all"|"preview"}
]: any -> record<accountId: string, analytics: record<canceledAt: float, disabledAt: float, enabledAt: float, id: string, paidAt: float, sampleRatePercent: float, spendLimitInDollars: float>, autoExposeSystemEnvs: bool, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurationId: string, createdAt: float, devCommand: string, directoryListing: bool, enablePreviewFeedback: bool, env: table<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string>, framework: string, gitForkProtection: bool, hasFloatingAliases: bool, id: string, installCommand: string, lastRollbackTarget: record<fromDeploymentId: string, jobStatus: string, requestedAt: float, toDeploymentId: string>, latestDeployments: table<alias: list, aliasAssigned: any, aliasError: record, aliasFinal: string, automaticAliases: list, buildingAt: float, builds: list, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record, deploymentHostname: string, forced: bool, id: string, meta: record, monorepoManager: string, name: string, plan: string, previewCommentsEnabled: bool, private: bool, readyAt: float, readyState: string, requestedAt: float, target: string, teamId: string, type: string, url: string, userId: string, withCache: bool>, link: any, live: bool, name: string, nodeVersion: string, outputDirectory: string, passwordProtection: record<deploymentType: string>, permissions: record<Monitoring: list<string>, aliasGlobal: list<string>, aliasProject: list<string>, aliasProtectionBypass: list<string>, analytics: list<string>, analyticsSampling: list<string>, analyticsUsage: list<string>, auditLog: list<string>, awsBillingIntegration: list<string>, billingAddress: list<string>, billingInformation: list<string>, billingInvoice: list<string>, billingInvoiceEmailRecipient: list<string>, billingInvoiceLanguage: list<string>, billingPlan: list<string>, billingPurchaseOrder: list<string>, billingTaxId: list<string>, cacheArtifact: list<string>, cacheArtifactUsageEvent: list<string>, concurrentBuilds: list<string>, connect: list<string>, connectConfiguration: list<string>, connectConfigurationLink: list<string>, deployment: list<string>, deploymentCheck: list<string>, deploymentCheckPreview: list<string>, deploymentPreview: list<string>, deploymentPrivate: list<string>, deploymentProductionGit: list<string>, deploymentRollback: list<string>, domain: list<string>, domainAcceptDelegation: list<string>, domainAuthCodes: list<string>, domainCertificate: list<string>, domainCheckConfig: list<string>, domainMove: list<string>, domainPurchase: list<string>, domainRecord: list<string>, domainTransferIn: list<string>, edgeConfig: list<string>, edgeConfigItem: list<string>, edgeConfigToken: list<string>, endpointVerification: list<string>, event: list<string>, fileUpload: list<string>, gitRepository: list<string>, integration: list<string>, integrationConfiguration: list<string>, integrationConfigurationProjects: list<string>, integrationConfigurationTransfer: list<string>, integrationVercelConfigurationOverride: list<string>, job: list<string>, logDrain: list<string>, monitoringChart: list<string>, monitoringQuery: list<string>, notificationDomainConfiguration: list<string>, notificationDomainExpire: list<string>, notificationDomainMoved: list<string>, notificationDomainPurchase: list<string>, notificationDomainRenewal: list<string>, notificationDomainTransfer: list<string>, notificationDomainUnverified: list<string>, notificationPaymentFailed: list<string>, notificationSpendCap: list<string>, notificationUsageAlert: list<string>, openTelemetryEndpoint: list<string>, passwordProtection: list<string>, paymentMethod: list<string>, permissions: list<string>, previewDeploymentSuffix: list<string>, proTrialOnboarding: list<string>, project: list<string>, projectDeploymentHook: list<string>, projectDomain: list<string>, projectDomainMove: list<string>, projectEnvVars: list<string>, projectEnvVarsProduction: list<string>, projectEnvVarsUnownedByIntegration: list<string>, projectIntegrationConfiguration: list<string>, projectLink: list<string>, projectMember: list<string>, projectProductionBranch: list<string>, projectProtectionBypass: list<string>, projectTransfer: list<string>, rateLimit: list<string>, redis: list<string>, remoteCaching: list<string>, samlConfig: list<string>, secret: list<string>, sensitiveEnvironmentVariablePolicy: list<string>, sharedEnvVars: list<string>, sharedEnvVarsProduction: list<string>, spendCapConfiguration: list<string>, spendCapState: list<string>, supportCase: list<string>, supportCaseComment: list<string>, team: list<string>, teamAccessRequest: list<string>, teamFellowMembership: list<string>, teamInvite: list<string>, teamInviteCode: list<string>, teamJoin: list<string>, teamOwnMembership: list<string>, teamOwnMembershipDisconnectSAML: list<string>, token: list<string>, usage: list<string>, user: list<string>, userConnection: list<string>, webAnalytics: list<string>, webhook: list<string>, webhook_event: list<string>>, protectionBypass: record, publicSource: bool, rootDirectory: string, serverlessFunctionRegion: string, skipGitConnectDuringLink: bool, sourceFilesOutsideRootDirectory: bool, ssoProtection: record<deploymentType: string>, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)" $qp)
  let body = {autoExposeSystemEnvs: $autoExposeSystemEnvs, buildCommand: $buildCommand, commandForIgnoringBuildStep: $commandForIgnoringBuildStep, devCommand: $devCommand, directoryListing: $directoryListing, enablePreviewFeedback: $enablePreviewFeedback, framework: $framework, gitForkProtection: $gitForkProtection, installCommand: $installCommand, name: $name, nodeVersion: $nodeVersion, outputDirectory: $outputDirectory, passwordProtection: $passwordProtection, publicSource: $publicSource, rootDirectory: $rootDirectory, serverlessFunctionRegion: $serverlessFunctionRegion, skipGitConnectDuringLink: $skipGitConnectDuringLink, sourceFilesOutsideRootDirectory: $sourceFilesOutsideRootDirectory, ssoProtection: $ssoProtection} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve project domains by project by id or name
#
# GET /v9/projects/{idOrName}/domains
# operationId: getProjectDomains
export def "projects-domains list" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --production: string@production-completer # Filters only production domains when set to `true`. (default: false)
  --gitBranch: string # Filters domains based on specific branch.
  --redirects: string@redirects-completer # Excludes redirect project domains when \"false\". Includes redirect project domains when \"true\" (default). (default: true)
  --redirect: string # Filters domains based on their redirect target.
  --verified: string@verified-completer # Filters domains based on their verification status.
  --limit: float # Maximum number of domains to list from a request (max 100).
  --since: float # Get domains created after this JavaScript timestamp.
  --until: float # Get domains created before this JavaScript timestamp.
  --order: string@order-completer # Domains sort order by createdAt (default: DESC)
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<domains: table<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: list, verified: bool>, pagination: record<count: float, next: float, prev: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "production" $production "scalar") (serialize-qp "gitBranch" $gitBranch "scalar") (serialize-qp "redirects" $redirects "scalar") (serialize-qp "redirect" $redirect "scalar") (serialize-qp "verified" $verified "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a domain to a project
#
# POST /v9/projects/{idOrName}/domains
# operationId: addProjectDomain
export def "projects-domains addProjectDomain" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --gitBranch: string # Git branch to link the project domain (nullable)
  name: string # The project domain name
  --redirect: string # Target destination domain for redirect (nullable)
  --redirectStatusCode: int@redirectStatusCode-completer # Status code for domain redirect (nullable)
]: any -> record<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: table<domain: string, reason: string, type: string, value: string>, verified: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/domains" $qp)
  let body = {gitBranch: $gitBranch, name: $name, redirect: $redirect, redirectStatusCode: $redirectStatusCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a domain from a project
#
# DELETE /v9/projects/{idOrName}/domains/{domain}
# operationId: removeProjectDomain
export def "projects-domains removeProjectDomain" [
  idOrName: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/domains/($domain)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a project domain
#
# GET /v9/projects/{idOrName}/domains/{domain}
# operationId: getProjectDomain
export def "projects-domains get" [
  idOrName: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: table<domain: string, reason: string, type: string, value: string>, verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/domains/($domain)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a project domain
#
# PATCH /v9/projects/{idOrName}/domains/{domain}
# operationId: updateProjectDomain
export def "projects-domains updateProjectDomain" [
  idOrName: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --gitBranch: string # Git branch to link the project domain (nullable)
  --redirect: string # Target destination domain for redirect (nullable)
  --redirectStatusCode: int@redirectStatusCode-completer # Status code for domain redirect (nullable)
]: any -> record<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: table<domain: string, reason: string, type: string, value: string>, verified: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/domains/($domain)" $qp)
  let body = {gitBranch: $gitBranch, redirect: $redirect, redirectStatusCode: $redirectStatusCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Verify project domain
#
# POST /v9/projects/{idOrName}/domains/{domain}/verify
# operationId: verifyProjectDomain
export def "projects-domains-verify verifyProjectDomain" [
  idOrName: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: table<domain: string, reason: string, type: string, value: string>, verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/domains/($domain)/verify" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the environment variables of a project by id or name
#
# GET /v9/projects/{idOrName}/env
# operationId: filterProjectEnvs
export def "projects-env filterProjectEnvs" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --gitBranch: string # If defined, the git branch of the environment variable to filter the results
  --decrypt: string@decrypt-completer # If true, the environment variable value will be decrypted
  --qp-source: string # The source that is calling the endpoint.
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gitBranch" $gitBranch "scalar") (serialize-qp "decrypt" $decrypt "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/env" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove an environment variable
#
# DELETE /v9/projects/{idOrName}/env/{id}
# operationId: removeProjectEnv
export def "projects-env removeProjectEnv" [
  idOrName: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/env/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit an environment variable
#
# PATCH /v9/projects/{idOrName}/env/{id}
# operationId: editProjectEnv
export def "projects-env editProjectEnv" [
  idOrName: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string # The Team identifier or slug to perform the request on behalf of.
  --gitBranch: string # The git branch of the environment variable (nullable)
  --key: string # The name of the environment variable
  --target: list # The target environment of the environment variable
  --type: string@type-completer-1 # The type of environment variable
  --value: string # The value of the environment variable
]: any -> record<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/env/($id)" $qp)
  let body = {gitBranch: $gitBranch, key: $key, target: $target, type: $type, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
