# Auto-generated client for Vercel API v0.0.1
# Source: https://api.apis.guru/v2/specs/vercel.com/0.0.1/openapi.json
# Auth: --token flag or $env.VERCEL_API_TOKEN

const BASE_URL = "https://api.vercel.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VERCEL_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://api.vercel.com"] }
def auth-scheme-completer [] { ["bearer" "none"] }

# Completers for enum parameters
def conclusion-completer [] { ["canceled" "failed" "neutral" "skipped" "succeeded"] }
def status-completer [] { ["completed" "running"] }
def type-completer [] { ["A" "AAAA" "ALIAS" "CAA" "CNAME" "MX" "NS" "SRV" "TXT"] }
def view-completer [] { ["account" "project"] }
def provider-completer [] { ["bitbucket" "github" "gitlab"] }
def delivery-format-completer [] { ["json" "ndjson"] }
def environment-completer [] { ["preview" "production"] }
def confirmed-completer [] { ["true"] }
def type-completer-1 [] { ["encrypted" "plain" "secret" "sensitive" "system"] }
def force-new-completer [] { ["0" "1"] }
def skip-auto-detection-confirmation-completer [] { ["0" "1"] }
def framework-completer [] { ["" "angular" "astro" "blitzjs" "brunch" "create-react-app" "docusaurus" "docusaurus-2" "dojo" "eleventy" "ember" "gatsby" "gridsome" "hexo" "hugo" "hydrogen" "ionic-angular" "ionic-react" "jekyll" "middleman" "nextjs" "nuxtjs" "parcel" "polymer" "preact" "redwoodjs" "remix" "saber" "sanity" "sapper" "scully" "solidstart" "stencil" "svelte" "sveltekit" "sveltekit-1" "umijs" "vite" "vitepress" "vue" "vuepress" "zola"] }
def target-completer [] { ["production" "staging"] }
def direction-completer [] { ["backward" "forward"] }
def follow-completer [] { ["0" "1"] }
def delimiter-completer [] { ["0" "1"] }
def builds-completer [] { ["0" "1"] }
def accept-completer [] { ["application/json" "application/stream+json"] }
def delivery-format-completer-1 [] { ["json" "ndjson" "syslog"] }
def role-completer [] { ["DEVELOPER" "MEMBER" "OWNER" "VIEWER"] }
def decrypt-completer [] { ["false" "true"] }
def type-completer-2 [] { ["oauth2-token"] }
def type-completer-3 [] { ["new" "renewal"] }
def target-completer-1 [] { ["preview" "production"] }
def git-fork-protection-completer [] { ["0" "1"] }
def node-version-completer [] { ["10.x" "12.x" "14.x" "16.x" "18.x"] }
def production-completer [] { ["false" "true"] }
def redirects-completer [] { ["false" "true"] }
def verified-completer [] { ["false" "true"] }
def order-completer [] { ["ASC" "DESC"] }
def redirect-status-code-completer [] { ["" "301" "302" "307" "308"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<createdAt: float, creator: string, domain: string, id: string, itemCount: float, name: string, recordType: string, sizeInBytes: float, ttl: float, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/edge-config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Create an Edge Config
#
# POST /edge-config
# operationId: createEdgeConfig
export def "edge-config create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --items: record
  slug: string
]: any -> record<blocking: bool, completedAt: float, conclusion: string, createdAt: float, deploymentId: string, detailsUrl: string, externalId: string, id: string, integrationId: string, itemCount: float, name: string, output: record<metrics: record<CLS: record, FCP: record, LCP: record, TBT: record, virtualExperienceScore: record>>, path: string, rerequestable: bool, sizeInBytes: float, startedAt: float, status: string, updatedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/edge-config" $qp)
  let req_body = {"items": $items, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Delete an Edge Config
#
# DELETE /edge-config/{edgeConfigId}
# operationId: deleteEdgeConfig
export def "edge-config delete" [
  edge_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($edge_config_id | is-empty) { error make --unspanned { msg: "path parameter 'edgeConfigId' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({edge_config_id: (encode-path-segment $edge_config_id)} | format pattern "/edge-config/{edge_config_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Get an Edge Config
#
# GET /edge-config/{edgeConfigId}
# operationId: getEdgeConfig
export def "edge-config get" [
  edge_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<createdAt: float, creator: string, domain: string, id: string, itemCount: float, name: string, recordType: string, sizeInBytes: float, ttl: float, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($edge_config_id | is-empty) { error make --unspanned { msg: "path parameter 'edgeConfigId' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({edge_config_id: (encode-path-segment $edge_config_id)} | format pattern "/edge-config/{edge_config_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Update an Edge Config
#
# PUT /edge-config/{edgeConfigId}
# operationId: updateEdgeConfig
export def "edge-config update" [
  edge_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  slug: string
]: any -> record<blocking: bool, completedAt: float, conclusion: string, createdAt: float, deploymentId: string, detailsUrl: string, externalId: string, id: string, integrationId: string, itemCount: float, name: string, output: record<metrics: record<CLS: record, FCP: record, LCP: record, TBT: record, virtualExperienceScore: record>>, path: string, rerequestable: bool, sizeInBytes: float, startedAt: float, status: string, updatedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($edge_config_id | is-empty) { error make --unspanned { msg: "path parameter 'edgeConfigId' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({edge_config_id: (encode-path-segment $edge_config_id)} | format pattern "/edge-config/{edge_config_id}") $qp)
  let req_body = {"slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Get an Edge Config item
#
# GET /edge-config/{edgeConfigId}/item/{edgeConfigItemKey}
# operationId: getEdgeConfigItem
export def "edge-config-item get" [
  edge_config_id: string
  edge_config_item_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<createdAt: float, edgeConfigId: string, key: string, updatedAt: float, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($edge_config_id | is-empty) { error make --unspanned { msg: "path parameter 'edgeConfigId' must be non-empty" } }
  if ($edge_config_item_key | is-empty) { error make --unspanned { msg: "path parameter 'edgeConfigItemKey' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({edge_config_id: (encode-path-segment $edge_config_id), edge_config_item_key: (encode-path-segment $edge_config_item_key)} | format pattern "/edge-config/{edge_config_id}/item/{edge_config_item_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Get Edge Config items
#
# GET /edge-config/{edgeConfigId}/items
# operationId: getEdgeConfigItems
export def "edge-config-items get" [
  edge_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<createdAt: float, edgeConfigId: string, key: string, updatedAt: float, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($edge_config_id | is-empty) { error make --unspanned { msg: "path parameter 'edgeConfigId' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({edge_config_id: (encode-path-segment $edge_config_id)} | format pattern "/edge-config/{edge_config_id}/items") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Update Edge Config items in batch
#
# PATCH /edge-config/{edgeConfigId}/items
# operationId: patchtEdgeConfigItems
export def "edge-config-items update-patcht" [
  edge_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  items: list
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($edge_config_id | is-empty) { error make --unspanned { msg: "path parameter 'edgeConfigId' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({edge_config_id: (encode-path-segment $edge_config_id)} | format pattern "/edge-config/{edge_config_id}/items") $qp)
  let req_body = {"items": $items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Create an Edge Config token
#
# POST /edge-config/{edgeConfigId}/token
# operationId: createEdgeConfigToken
export def "edge-config-token create" [
  edge_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  label: string
]: any -> record<id: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($edge_config_id | is-empty) { error make --unspanned { msg: "path parameter 'edgeConfigId' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({edge_config_id: (encode-path-segment $edge_config_id)} | format pattern "/edge-config/{edge_config_id}/token") $qp)
  let req_body = {"label": $label} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Get Edge Config token meta data
#
# GET /edge-config/{edgeConfigId}/token/{token}
# operationId: getEdgeConfigToken
export def "edge-config-token get" [
  edge_config_id: string
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<createdAt: float, edgeConfigId: string, id: string, label: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($edge_config_id | is-empty) { error make --unspanned { msg: "path parameter 'edgeConfigId' must be non-empty" } }
  if ($token_arg | is-empty) { error make --unspanned { msg: "path parameter 'token' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({edge_config_id: (encode-path-segment $edge_config_id), token_arg: (encode-path-segment $token_arg)} | format pattern "/edge-config/{edge_config_id}/token/{token_arg}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Delete one or more Edge Config tokens
#
# DELETE /edge-config/{edgeConfigId}/tokens
# operationId: deleteEdgeConfigTokens
export def "edge-config-tokens delete" [
  edge_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  tokens: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($edge_config_id | is-empty) { error make --unspanned { msg: "path parameter 'edgeConfigId' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({edge_config_id: (encode-path-segment $edge_config_id)} | format pattern "/edge-config/{edge_config_id}/tokens") $qp)
  let req_body = {"tokens": $tokens} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Get all tokens of an Edge Config
#
# GET /edge-config/{edgeConfigId}/tokens
# operationId: getEdgeConfigTokens
export def "edge-config-tokens get" [
  edge_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<createdAt: float, edgeConfigId: string, id: string, label: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($edge_config_id | is-empty) { error make --unspanned { msg: "path parameter 'edgeConfigId' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({edge_config_id: (encode-path-segment $edge_config_id)} | format pattern "/edge-config/{edge_config_id}/tokens") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Login with email
#
# POST /registration
# operationId: emailLogin
export def "registration create-email-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The user email.
  --token-name: string # The desired name for the token. It will be displayed on the user account details.
]: any -> record<securityCode: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/registration")
  let req_body = {"email": $email, "tokenName": $token_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Verify a login request to get an authentication token
#
# GET /registration/verify
# operationId: verifyToken
export def "registration-verify verify-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email to verify the login.
  --qp-token: string # The token returned when the login was requested.
  --token-name: string # The desired name for the token. It will be displayed on the user account details.
  --sso-user-id: string # The SAML Profile ID, when connecting a SAML Profile to a Team member for the first time.
]: nothing -> record<email: string, teamId: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "tokenName" $token_name "scalar") (serialize-qp "ssoUserId" $sso_user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/registration/verify" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"email": $email, "token": $qp_token, "tokenName": $token_name, "ssoUserId": $sso_user_id} | compact), body: null}
}

# Retrieve a list of all checks
#
# GET /v1/deployments/{deploymentId}/checks
# operationId: getAllChecks
export def "deployments-checks get-list" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<checks: table<completedAt: float, conclusion: string, createdAt: float, detailsUrl: string, id: string, integrationId: string, name: string, output: record, path: string, rerequestable: bool, startedAt: float, status: string, updatedAt: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deploymentId' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({deployment_id: (encode-path-segment $deployment_id)} | format pattern "/v1/deployments/{deployment_id}/checks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Creates a new Check
#
# POST /v1/deployments/{deploymentId}/checks
# operationId: createCheck
export def "deployments-checks create" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --blocking: oneof<nothing, bool> # Whether the check should block a deployment from succeeding
  --details-url: string # URL to display for further details
  --external-id: string # An identifier that can be used as an external reference
  name: string # The name of the check being created
  --path: string # Path of the page that is being checked
  --rerequestable: oneof<nothing, bool> # Whether a user should be able to request for the check to be rerun if it fails
]: any -> record<blocking: bool, completedAt: float, conclusion: string, createdAt: float, deploymentId: string, detailsUrl: string, externalId: string, id: string, integrationId: string, name: string, output: record<metrics: record<CLS: record, FCP: record, LCP: record, TBT: record, virtualExperienceScore: record>>, path: string, rerequestable: bool, startedAt: float, status: string, updatedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deploymentId' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({deployment_id: (encode-path-segment $deployment_id)} | format pattern "/v1/deployments/{deployment_id}/checks") $qp)
  let req_body = {"blocking": $blocking, "detailsUrl": $details_url, "externalId": $external_id, "name": $name, "path": $path, "rerequestable": $rerequestable} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Get a single check
#
# GET /v1/deployments/{deploymentId}/checks/{checkId}
# operationId: getCheck
export def "deployments-checks get" [
  deployment_id: string
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<createdAt: float, creator: string, domain: string, id: string, name: string, recordType: string, ttl: float, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deploymentId' must be non-empty" } }
  if ($check_id | is-empty) { error make --unspanned { msg: "path parameter 'checkId' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({deployment_id: (encode-path-segment $deployment_id), check_id: (encode-path-segment $check_id)} | format pattern "/v1/deployments/{deployment_id}/checks/{check_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Update a check
#
# PATCH /v1/deployments/{deploymentId}/checks/{checkId}
# operationId: updateCheck
# --output shape: {metrics?: record}
export def "deployments-checks update" [
  deployment_id: string
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --conclusion: any@conclusion-completer # The result of the check being run
  --details-url: string # A URL a user may visit to see more information about the check
  --external-id: string # An identifier that can be used as an external reference
  --name: string # The name of the check being created
  --output: record # The results of the check Run — shape: {metrics?: record}
  --path: string # Path of the page that is being checked
  --status: any@status-completer # The current status of the check
]: any -> record<blocking: bool, completedAt: float, conclusion: string, createdAt: float, deploymentId: string, detailsUrl: string, externalId: string, id: string, integrationId: string, name: string, output: record<metrics: record<CLS: record, FCP: record, LCP: record, TBT: record, virtualExperienceScore: record>>, path: string, rerequestable: bool, startedAt: float, status: string, updatedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deploymentId' must be non-empty" } }
  if ($check_id | is-empty) { error make --unspanned { msg: "path parameter 'checkId' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({deployment_id: (encode-path-segment $deployment_id), check_id: (encode-path-segment $check_id)} | format pattern "/v1/deployments/{deployment_id}/checks/{check_id}") $qp)
  let req_body = {"conclusion": $conclusion, "detailsUrl": $details_url, "externalId": $external_id, "name": $name, "output": $output, "path": $path, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Rerequest a check
#
# POST /v1/deployments/{deploymentId}/checks/{checkId}/rerequest
# operationId: rerequestCheck
export def "deployments-checks-rerequest check" [
  deployment_id: string
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deploymentId' must be non-empty" } }
  if ($check_id | is-empty) { error make --unspanned { msg: "path parameter 'checkId' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({deployment_id: (encode-path-segment $deployment_id), check_id: (encode-path-segment $check_id)} | format pattern "/v1/deployments/{deployment_id}/checks/{check_id}/rerequest") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Update an existing DNS record
#
# PATCH /v1/domains/records/{recordId}
# operationId: updateRecord
# --srv shape: {port: int, priority: int, target: string, weight: int}
export def "domains-records update" [
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --mx-priority: int # The MX priority value of the DNS record (nullable)
  --name: string # The name of the DNS record (nullable)
  --srv: record # nullable — shape: {port: int, priority: int, target: string, weight: int}
  --ttl: int # The Time to live (TTL) value of the DNS record (nullable)
  --type: string@type-completer # The type of the DNS record (nullable)
  --value: string # The value of the DNS record (nullable)
]: any -> record<createdAt: float, creator: string, domain: string, id: string, name: string, recordType: string, ttl: float, type: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($record_id | is-empty) { error make --unspanned { msg: "path parameter 'recordId' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({record_id: (encode-path-segment $record_id)} | format pattern "/v1/domains/records/{record_id}") $qp)
  let req_body = {"mxPriority": $mx_priority, "name": $name, "srv": $srv, "ttl": $ttl, "type": $type, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/integrations/configuration/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/integrations/configuration/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --view: string@view-completer
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "view" $view "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/integrations/configurations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"view": $view, "teamId": $team_id} | compact), body: null}
}

# List git namespaces by provider
#
# GET /v1/integrations/git-namespaces
# operationId: gitNamespaces
export def "integrations-git-namespaces get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --provider: string@provider-completer
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> table<id: any, name: string, ownerType: string, provider: string, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "provider" $provider "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/integrations/git-namespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"provider": $provider, "teamId": $team_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/integrations/log-drains/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string
  --namespace-id: string
  --provider: string@provider-completer
  --installation-id: string
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<gitAccount: record<namespaceId: any, provider: string>, repos: table<defaultBranch: string, id: any, name: string, namespace: string, ownerType: string, private: bool, slug: string, updatedAt: float, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "namespaceId" $namespace_id "scalar") (serialize-qp "provider" $provider "scalar") (serialize-qp "installationId" $installation_id "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/integrations/search-repo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "namespaceId": $namespace_id, "provider": $provider, "installationId": $installation_id, "teamId": $team_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> table<branch: string, configurationId: string, createdAt: float, deliveryFormat: string, environment: string, headers: record, id: string, ownerId: string, projectIds: list<string>, sources: list<string>, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/log-drains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"projectId": $project_id, "teamId": $team_id} | compact), body: null}
}

# Creates a Configurable Log Drain
#
# POST /v1/log-drains
# operationId: createConfigurableLogDrain
export def "log-drains create-configurable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --branch: string # The branch regexp of log drain
  delivery_format: any@delivery-format-completer # The delivery log format
  --environment: any@environment-completer # The environment of log drain
  --headers: record # Headers to be sent together with the request
  --project-ids: list<string>
  sources: list<string>
  url: string # The log drain url (format: uri)
]: any -> record<branch: string, configurationId: string, createdAt: float, deliveryFormat: string, environment: string, headers: record, id: string, ownerId: string, projectIds: list<string>, secret: string, sources: list<string>, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/log-drains" $qp)
  let req_body = {"branch": $branch, "deliveryFormat": $delivery_format, "environment": $environment, "headers": $headers, "projectIds": $project_ids, "sources": $sources, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Deletes a Configurable Log Drain
#
# DELETE /v1/log-drains/{id}
# operationId: deleteConfigurableLogDrain
export def "log-drains delete-configurable" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/log-drains/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Retrieves a Configurable Log Drain
#
# GET /v1/log-drains/{id}
# operationId: getConfigurableLogDrain
export def "log-drains get-configurable" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<branch: string, configurationId: string, createdAt: float, deliveryFormat: string, environment: string, headers: record, id: string, ownerId: string, projectIds: list<string>, sources: list<string>, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/log-drains/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Retrieve the decrypted value of an environment variable of a project by id
#
# GET /v1/projects/{idOrName}/env/{id}
# operationId: getProjectEnv
export def "projects-env get" [
  id_or_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_name | is-empty) { error make --unspanned { msg: "path parameter 'idOrName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_or_name: (encode-path-segment $id_or_name), id: (encode-path-segment $id)} | format pattern "/v1/projects/{id_or_name}/env/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Create a Team
#
# POST /v1/teams
# operationId: createTeam
export def "teams create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The desired name for the Team. It will be generated from the provided slug if nothing is provided
  slug: string # The desired slug for the Team
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/teams")
  let req_body = {"name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a Team
#
# DELETE /v1/teams/{teamId}
# operationId: deleteTeam
# --reasons item shape: {description: string, slug: string}
export def "teams delete" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reasons: list # Optional array of objects that describe the reason why the team is being deleted. — item shape: {description: string, slug: string}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id | is-empty) { error make --unspanned { msg: "path parameter 'teamId' must be non-empty" } }
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id)} | format pattern "/v1/teams/{team_id}"))
  let req_body = {"reasons": $reasons} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a Team invite code
#
# DELETE /v1/teams/{teamId}/invites/{inviteId}
# operationId: deleteTeamInviteCode
export def "teams-invites delete-code" [
  team_id: string
  invite_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id | is-empty) { error make --unspanned { msg: "path parameter 'teamId' must be non-empty" } }
  if ($invite_id | is-empty) { error make --unspanned { msg: "path parameter 'inviteId' must be non-empty" } }
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id), invite_id: (encode-path-segment $invite_id)} | format pattern "/v1/teams/{team_id}/invites/{invite_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Invite a user
#
# POST /v1/teams/{teamId}/members
# operationId: inviteUserToTeam
export def "teams-members create-invite-user" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address of the user to invite (format: email)
  --role: any
  --uid: string # The id of the user to invite
]: any -> record<email: string, role: string, uid: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id | is-empty) { error make --unspanned { msg: "path parameter 'teamId' must be non-empty" } }
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id)} | format pattern "/v1/teams/{team_id}/members"))
  let req_body = {"email": $email, "role": $role, "uid": $uid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Join a team
#
# POST /v1/teams/{teamId}/members/teams/join
# operationId: joinTeam
export def "teams-members-teams-join create" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --invite-code: string # The invite code to join the team.
  --body-team-id: string # The team ID.
]: any -> record<from: string, name: string, slug: string, teamId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id | is-empty) { error make --unspanned { msg: "path parameter 'teamId' must be non-empty" } }
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id)} | format pattern "/v1/teams/{team_id}/members/teams/join"))
  let req_body = {"inviteCode": $invite_code, "teamId": $body_team_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove a Team Member
#
# DELETE /v1/teams/{teamId}/members/{uid}
# operationId: removeTeamMember
export def "teams-members delete" [
  team_id: string
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id | is-empty) { error make --unspanned { msg: "path parameter 'teamId' must be non-empty" } }
  if ($uid | is-empty) { error make --unspanned { msg: "path parameter 'uid' must be non-empty" } }
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id), uid: (encode-path-segment $uid)} | format pattern "/v1/teams/{team_id}/members/{uid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a Team Member
#
# PATCH /v1/teams/{teamId}/members/{uid}
# operationId: updateTeamMember
# --joinedFrom shape: {ssoUserId?: any}
export def "teams-members update" [
  team_id: string
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --confirmed: oneof<nothing, bool> # Accept a user who requested access to the team.
  --joined-from: record # shape: {ssoUserId?: any}
  --role: string # The role in the team of the member. (default: [MEMBER, VIEWER])
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id | is-empty) { error make --unspanned { msg: "path parameter 'teamId' must be non-empty" } }
  if ($uid | is-empty) { error make --unspanned { msg: "path parameter 'uid' must be non-empty" } }
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id), uid: (encode-path-segment $uid)} | format pattern "/v1/teams/{team_id}/members/{uid}"))
  let req_body = {"confirmed": $confirmed, "joinedFrom": $joined_from, "role": $role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Request access to a team
#
# POST /v1/teams/{teamId}/request
# operationId: requestAccessToTeam
# --joinedFrom shape: {commitId?: string, gitUserId?: any, gitUserLogin?: string, origin: "import"|"teams"|"github"|"gitlab"|"bitbucket"|"feedback", repoId?: string, repoPath?: string}
export def "teams-request request-access" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  joined_from: record # shape: {commitId?: string, gitUserId?: any, gitUserLogin?: string, origin: "import"|"teams"|"github"|"gitlab"|"bitbucket"|"feedback", repoId?: string, repoPath?: string}
]: any -> record<accessRequestedAt: float, bitbucket: record<login: string>, confirmed: bool, github: record<login: string>, gitlab: record<login: string>, joinedFrom: record<commitId: string, dsyncConnectedAt: float, dsyncUserId: string, gitUserId: any, gitUserLogin: string, idpUserId: string, origin: string, repoId: string, repoPath: string, ssoConnectedAt: float, ssoUserId: string>, teamName: string, teamSlug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id | is-empty) { error make --unspanned { msg: "path parameter 'teamId' must be non-empty" } }
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id)} | format pattern "/v1/teams/{team_id}/request"))
  let req_body = {"joinedFrom": $joined_from} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get access request status
#
# GET /v1/teams/{teamId}/request/{userId}
# operationId: getTeamAccessRequest
export def "teams-request get-access" [
  team_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accessRequestedAt: float, bitbucket: record<login: string>, confirmed: bool, github: record<login: string>, gitlab: record<login: string>, joinedFrom: record<commitId: string, dsyncConnectedAt: float, dsyncUserId: string, gitUserId: any, gitUserLogin: string, idpUserId: string, origin: string, repoId: string, repoPath: string, ssoConnectedAt: float, ssoUserId: string>, teamName: string, teamSlug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id | is-empty) { error make --unspanned { msg: "path parameter 'teamId' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id), user_id: (encode-path-segment $user_id)} | format pattern "/v1/teams/{team_id}/request/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete User Account
#
# DELETE /v1/user
# operationId: requestDelete
# --reasons item shape: {description: string, slug: string}
export def "user request-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reasons: list # Optional array of objects that describe the reason why the User account is being deleted. — item shape: {description: string, slug: string}
]: any -> record<email: string, id: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/user")
  let req_body = {"reasons": $reasons} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"projectId": $project_id, "teamId": $team_id} | compact), body: null}
}

# Creates a webhook
#
# POST /v1/webhooks
# operationId: createWebhook
export def "webhooks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  events: list<string>
  --project-ids: list<string>
  url: string # format: uri
]: any -> record<createdAt: float, events: list<string>, id: string, ownerId: string, projectIds: list<string>, secret: string, updatedAt: float, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/webhooks" $qp)
  let req_body = {"events": $events, "projectIds": $project_ids, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/webhooks/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<createdAt: float, events: list<string>, id: string, ownerId: string, projectIds: list<string>, updatedAt: float, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/webhooks/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Create one or more environment variables
#
# POST /v10/projects/{idOrName}/env
# operationId: createProjectEnv
export def "projects-env create" [
  id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --git-branch: string # The git branch of the environment variable (nullable)
  --key: string # The name of the environment variable
  --target: list # The target environment of the environment variable
  --type: string@type-completer-1 # The type of environment variable
  --value: string # The value of the environment variable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_name | is-empty) { error make --unspanned { msg: "path parameter 'idOrName' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_or_name: (encode-path-segment $id_or_name)} | format pattern "/v10/projects/{id_or_name}/env") $qp)
  let req_body = {"gitBranch": $git_branch, "key": $key, "target": $target, "type": $type, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if ($input | describe | str starts-with "list") { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# List Deployment Builds
#
# GET /v11/deployments/{deploymentId}/builds
# operationId: listDeploymentBuilds
export def "deployments-builds list" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<builds: table<config: record, copiedFrom: string, createdAt: float, createdIn: string, deployedAt: float, deploymentId: string, entrypoint: string, fingerprint: string, id: string, output: list, readyState: string, readyStateAt: float, scheduledAt: float, use: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deploymentId' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({deployment_id: (encode-path-segment $deployment_id)} | format pattern "/v11/deployments/{deployment_id}/builds") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Cancel a deployment
#
# PATCH /v12/deployments/{id}/cancel
# operationId: cancelDeployment
export def "deployments-cancel cancel" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<alias: list<string>, aliasAssigned: bool, aliasAssignedAt: any, aliasError: record<code: string, message: string>, aliasFinal: string, aliasWarning: record<action: string, code: string, link: string, message: string>, automaticAliases: list<string>, bootedAt: float, build: record<env: list<string>>, buildErrorAt: float, buildingAt: float, builds: table<config: record, src: string, use: string>, canceledAt: float, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record<uid: string, username: string>, env: list<string>, errorCode: string, errorLink: string, errorMessage: string, errorStep: string, functions: record, gitRepo: any, gitSource: any, id: string, inspectorUrl: string, isInConcurrentBuildsQueue: bool, lambdas: table<createdAt: float, entrypoint: string, id: string, output: list, readyState: string, readyStateAt: float>, meta: record, monorepoManager: string, name: string, ownerId: string, plan: string, previewCommentsEnabled: bool, projectId: string, public: bool, readyState: string, regions: list<string>, routes: list<any>, source: string, target: string, team: record<id: string, name: string, slug: string>, type: string, url: string, userAliases: list<string>, version: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v12/deployments/{id}/cancel") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
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
# --projectSettings shape: {buildCommand?: string, commandForIgnoringBuildStep?: string, devCommand?: string, ... (7 more fields)}
# --redirects item shape: {destination: string, has?: list, missing?: list, permanent?: bool, source: string}
# --rewrites item shape: {destination: string, has?: list, missing?: list, source: string}
@deprecated --flag build
@deprecated --flag builds
@deprecated --flag body-env
@deprecated --flag routes
export def "deployments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force-new: string@force-new-completer # Forces a new deployment even if there is a previous similar deployment
  --skip-auto-detection-confirmation: string@skip-auto-detection-confirmation-completer # Allows to skip framework detection so the API would not fail to ask for confirmation
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --schema: string # Ignored. Can be set to get completions, validations and documentation in some editors.
  --alias: list<string> # Aliases that will get assigned when the deployment is `READY` and the target is `production`. The client needs to make a `GET` request to its API to ensure the assignment
  --build: record # An object containing another object with information to be passed to the Build Process (DEPRECATED) — shape: {env?: record}
  --build-command: string # The build command for this project. When `null` is used this value will be automatically detected (nullable)
  --builds: list # A list of build descriptions whose src references valid source files. (DEPRECATED) — item shape: {config?: record, src?: string, use: string}
  --clean-urls: oneof<nothing, bool> # When set to `true`, all HTML files and Serverless Functions will have their extension removed. When visiting a path that ends with the extension, a 308 response will redirect the client to the extensionless path.
  --crons: list # An array of cron jobs that should be created for production Deployments. — item shape: {path: string, schedule: string}
  --deployment-id: string # An deployment id for an existing deployment to redeploy
  --dev-command: string # The dev command for this project. When `null` is used this value will be automatically detected (nullable)
  --body-env: record # An object containing the deployment's environment variable names and values. Secrets can be referenced by prefixing the value with `@` (DEPRECATED)
  --files: list # A list of objects with the files to be deployed
  --framework: string@framework-completer # The framework that is being used for this project. When `null` is used no framework is selected (nullable)
  --functions: record # An object describing custom options for your Serverless Functions. Each key must be glob pattern that matches the paths of the Serverless Functions you would like to customize (like `api/*.js` or `api/test.js`).
  --git: record # shape: {deploymentEnabled?: any}
  --git-metadata: record # Populates initial git metadata for different git providers. — shape: {commitAuthorName?: string, commitMessage?: string, commitRef?: string, commitSha?: string, dirty?: bool, remoteUrl: string}
  --git-source: any # Defines the Git Repository source to be deployed. This property can not be used in combination with `files`.
  --headers: list # A list of header definitions. — item shape: {has?: list, headers: list, missing?: list, source: string}
  --ignore-command: string # nullable
  --install-command: string # The install command for this project. When `null` is used this value will be automatically detected (nullable)
  --meta: record # An object containing the deployment's metadata. Multiple key-value pairs can be attached to a deployment
  --monorepo-manager: string # The monorepo manager that is being used for this deployment. When `null` is used no monorepo manager is selected (nullable)
  name: string # A string with the project name used in the deployment URL
  --output-directory: string # The output directory of the project. When `null` is used this value will be automatically detected (nullable)
  --project: string # The target project identifier in which the deployment will be created. When defined, this parameter overrides name
  --project-settings: record # Project settings that will be applied to the deployment. It is required for the first deployment of a project and will be saved for any following deployments — shape: {buildCommand?: string, commandForIgnoringBuildStep?: string, devCommand?: string, ... (7 more fields)}
  --public: oneof<nothing, bool> # Whether a deployment's source and logs are available publicly
  --redirects: list # A list of redirect definitions. — item shape: {destination: string, has?: list, missing?: list, permanent?: bool, source: string}
  --regions: list<string> # An array of the regions the deployment's Serverless Functions should be deployed to
  --rewrites: list # A list of rewrite definitions. — item shape: {destination: string, has?: list, missing?: list, source: string}
  --routes: list # A list of routes objects used to rewrite paths to point towards other internal or external paths (DEPRECATED)
  --target: string@target-completer # Either not defined, `staging`, or `production`. If `staging`, a staging alias in the format `..now.sh` will be assigned. If `production`, any aliases defined in `alias` will be assigned
  --trailing-slash: oneof<nothing, bool> # When `false`, visiting a path that ends with a forward slash will respond with a `308` status code and redirect to the path without the trailing slash.
  --with-latest-commit: oneof<nothing, bool> # When `true` and `deploymentId` is passed in, the sha from the previous deployment's `gitSource` is removed forcing the latest commit to be used.
]: any -> record<alias: list<string>, aliasAssigned: bool, aliasAssignedAt: any, aliasError: record<code: string, message: string>, aliasFinal: string, aliasWarning: record<action: string, code: string, link: string, message: string>, automaticAliases: list<string>, bootedAt: float, build: record<env: list<string>>, buildErrorAt: float, buildingAt: float, builds: list<record>, canceledAt: float, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record<uid: string, username: string>, env: list<string>, errorCode: string, errorLink: string, errorMessage: string, errorStep: string, functions: record, gitRepo: any, gitSource: any, id: string, inspectorUrl: string, isInConcurrentBuildsQueue: bool, lambdas: table<createdAt: float, entrypoint: string, id: string, output: list, readyState: string, readyStateAt: float>, meta: record, monorepoManager: string, name: string, ownerId: string, plan: string, previewCommentsEnabled: bool, projectId: string, public: bool, readyState: string, regions: list<string>, routes: list<any>, source: string, target: string, team: record<id: string, name: string, slug: string>, type: string, url: string, userAliases: list<string>, version: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceNew" $force_new "scalar") (serialize-qp "skipAutoDetectionConfirmation" $skip_auto_detection_confirmation "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v13/deployments" $qp)
  let req_body = {"$schema": $schema, "alias": $alias, "build": $build, "buildCommand": $build_command, "builds": $builds, "cleanUrls": $clean_urls, "crons": $crons, "deploymentId": $deployment_id, "devCommand": $dev_command, "env": $body_env, "files": $files, "framework": $framework, "functions": $functions, "git": $git, "gitMetadata": $git_metadata, "gitSource": $git_source, "headers": $headers, "ignoreCommand": $ignore_command, "installCommand": $install_command, "meta": $meta, "monorepoManager": $monorepo_manager, "name": $name, "outputDirectory": $output_directory, "project": $project, "projectSettings": $project_settings, "public": $public, "redirects": $redirects, "regions": $regions, "rewrites": $rewrites, "routes": $routes, "target": $target, "trailingSlash": $trailing_slash, "withLatestCommit": $with_latest_commit} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"forceNew": $force_new, "skipAutoDetectionConfirmation": $skip_auto_detection_confirmation, "teamId": $team_id} | compact), body: $req_body}
}

# Get a deployment by ID or URL
#
# GET /v13/deployments/{idOrUrl}
# operationId: getDeployment
export def "deployments get" [
  id_or_url: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-git-repo-info: string # Whether to add in gitRepo information.
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_url | is-empty) { error make --unspanned { msg: "path parameter 'idOrUrl' must be non-empty" } }
  let qp = [(serialize-qp "withGitRepoInfo" $with_git_repo_info "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_or_url: (encode-path-segment $id_or_url)} | format pattern "/v13/deployments/{id_or_url}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"withGitRepoInfo": $with_git_repo_info, "teamId": $team_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # A Deployment or Alias URL. In case it is passed, the ID will be ignored
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<state: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "url" $url "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v13/deployments/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"url": $url, "teamId": $team_id} | compact), body: null}
}

# Delete an Alias
#
# DELETE /v2/aliases/{aliasId}
# operationId: deleteAlias
export def "aliases delete-alias" [
  alias_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($alias_id | is-empty) { error make --unspanned { msg: "path parameter 'aliasId' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({alias_id: (encode-path-segment $alias_id)} | format pattern "/v2/aliases/{alias_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Get deployment events
#
# GET /v2/deployments/{idOrUrl}/events
# operationId: getDeploymentEvents
export def "deployments-events get" [
  id_or_url: string
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
  --direction: string@direction-completer # Order of the returned events based on the timestamp. (default: forward)
  --follow: float@follow-completer # When enabled, this endpoint will return live events as they happen.
  --limit: float # Maximum number of events to return. Provide `-1` to return all available logs.
  --name: string # Deployment build ID.
  --since: float # Timestamp for when build logs should be pulled from.
  --until: float # Timestamp for when the build logs should be pulled up until.
  --status-code: string # HTTP status code range to filter events by.
  --delimiter: float@delimiter-completer
  --builds: float@builds-completer
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_url | is-empty) { error make --unspanned { msg: "path parameter 'idOrUrl' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "follow" $follow "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "statusCode" $status_code "scalar") (serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "builds" $builds "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_or_url: (encode-path-segment $id_or_url)} | format pattern "/v2/deployments/{id_or_url}/events") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "follow": $follow, "limit": $limit, "name": $name, "since": $since, "until": $until, "statusCode": $status_code, "delimiter": $delimiter, "builds": $builds, "teamId": $team_id} | compact), body: null}
}

# List Deployment Aliases
#
# GET /v2/deployments/{id}/aliases
# operationId: listDeploymentAliases
export def "deployments-aliases list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<aliases: table<alias: string, created: string, protectionBypass: record, redirect: string, uid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/deployments/{id}/aliases") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Assign an Alias
#
# POST /v2/deployments/{id}/aliases
# operationId: assignAlias
export def "deployments-aliases assign-alias" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --alias: string # The alias we want to assign to the deployment defined in the URL
  --redirect: string # The redirect property will take precedence over the deployment id from the URL and consists of a hostname (like test.com) to which the alias should redirect using status code 307 (nullable)
]: any -> record<alias: string, created: string, oldDeploymentId: string, uid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/deployments/{id}/aliases") $qp)
  let req_body = {"alias": $alias, "redirect": $redirect} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Create a DNS record
#
# POST /v2/domains/{domain}/records
# operationId: createRecord
# --srv shape: {port: any, priority: any, target?: string, weight: any}
export def "domains-records create" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  type: string@type-completer # The type of record, it could be one of the valid DNS records.
  --name: string # A subdomain name or an empty string for the root domain.
  --ttl: float # The TTL value. Must be a number between 60 and 2147483647. Default value is 60.
  --value: string # The record value must be a valid IPv4 address. (format: ipv4)
  --mx-priority: float
  --srv: record # shape: {port: any, priority: any, target?: string, weight: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain: (encode-path-segment $domain)} | format pattern "/v2/domains/{domain}/records") $qp)
  let req_body = {"type": $type, "name": $name, "ttl": $ttl, "value": $value, "mxPriority": $mx_priority, "srv": $srv} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Delete a DNS record
#
# DELETE /v2/domains/{domain}/records/{recordId}
# operationId: removeRecord
export def "domains-records delete" [
  domain: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  if ($record_id | is-empty) { error make --unspanned { msg: "path parameter 'recordId' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain: (encode-path-segment $domain), record_id: (encode-path-segment $record_id)} | format pattern "/v2/domains/{domain}/records/{record_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Upload Deployment Files
#
# POST /v2/files
# operationId: uploadFile
export def "files upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --content-length: float # The file size in bytes
  --x-vercel-digest: string # The file SHA1 used to check the integrity
  --x-now-digest: string # The file SHA1 used to check the integrity
  --x-now-size: float # The file size as an alternative to `Content-Length`
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Length": $content_length, "x-vercel-digest": $x_vercel_digest, "x-now-digest": $x_now_digest, "x-now-size": $x_now_size} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> table<branch: string, clientId: string, configurationId: string, createdAt: float, createdFrom: string, deliveryFormat: string, environment: string, headers: record, id: string, name: string, ownerId: string, projectId: string, projectIds: list<string>, sources: list<string>, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/integrations/log-drains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Creates a new Integration Log Drain
#
# POST /v2/integrations/log-drains
# operationId: createLogDrain
export def "integrations-log-drains create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --branch: string # The branch regexp of log drain
  --delivery-format: any@delivery-format-completer-1 # The delivery log format
  --environment: any@environment-completer # The environment of log drain
  --headers: record # Headers to be sent together with the request
  name: string # The name of the log drain
  --project-ids: list<string>
  --secret: string # A secret to sign log drain notification headers so a consumer can verify their authenticity
  --sources: list<string>
  url: string # The url where you will receive logs. The protocol must be `https://` or `http://` when type is `json` and `ndjson`, and `syslog+tls:` or `syslog:` when the type is `syslog`. (format: uri)
]: any -> record<branch: string, clientId: string, configurationId: string, createdAt: float, createdFrom: string, deliveryFormat: string, environment: string, headers: record, id: string, name: string, ownerId: string, projectId: string, projectIds: list<string>, sources: list<string>, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/integrations/log-drains" $qp)
  let req_body = {"branch": $branch, "deliveryFormat": $delivery_format, "environment": $environment, "headers": $headers, "name": $name, "projectIds": $project_ids, "secret": $secret, "sources": $sources, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Delete a secret
#
# DELETE /v2/secrets/{idOrName}
# operationId: deleteSecret
export def "secrets delete" [
  id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<created: float, name: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_name | is-empty) { error make --unspanned { msg: "path parameter 'idOrName' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_or_name: (encode-path-segment $id_or_name)} | format pattern "/v2/secrets/{id_or_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Change secret name
#
# PATCH /v2/secrets/{name}
# operationId: renameSecret
export def "secrets rename" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --body-name: string # The name of the new secret.
]: any -> record<created: string, name: string, oldName: string, uid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2/secrets/{name}") $qp)
  let req_body = {"name": $body_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Create a new secret
#
# POST /v2/secrets/{name}
# operationId: createSecret
@deprecated --flag project-id
export def "secrets create" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --decryptable: oneof<nothing, bool> # Whether the secret value can be decrypted after it has been created.
  --body-name: string # The name of the secret (max 100 characters).
  --project-id: string # Associate a secret to a project. (DEPRECATED)
  value: string # The value of the new secret.
]: any -> record<created: string, createdAt: float, decryptable: bool, name: string, projectId: string, teamId: string, uid: string, userId: string, value: record<data: list<float>, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2/secrets/{name}") $qp)
  let req_body = {"decryptable": $decryptable, "name": $body_name, "projectId": $project_id, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "since": $since, "until": $until} | compact), body: null}
}

# Get a Team
#
# GET /v2/teams/{teamId}
# operationId: getTeam
export def "teams get" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --slug: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id | is-empty) { error make --unspanned { msg: "path parameter 'teamId' must be non-empty" } }
  let qp = [(serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id)} | format pattern "/v2/teams/{team_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"slug": $slug} | compact), body: null}
}

# Update a Team
#
# PATCH /v2/teams/{teamId}
# operationId: patchTeam
# --remoteCaching shape: {enabled?: bool}
# --saml shape: {enforced?: bool, roles?: record}
export def "teams update" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatar: string # The hash value of an uploaded image. (format: regex)
  --description: string # A short text that describes the team.
  --email-domain: string # nullable, format: regex
  --enable-preview-feedback: string # Enable preview comments: one of on, off or default.
  --migrate-existing-env-variables-to-sensitive: oneof<nothing, bool> # Runs a task that migrates all existing environment variables to sensitive environment variables.
  --name: string # The name of the team.
  --preview-deployment-suffix: string # Suffix that will be used for all preview deployments. (nullable, format: hostname)
  --regenerate-invite-code: oneof<nothing, bool> # Create a new invite code and replace the current one.
  --remote-caching: record # Whether or not remote caching is enabled for the team — shape: {enabled?: bool}
  --saml: record # shape: {enforced?: bool, roles?: record}
  --sensitive-environment-variable-policy: string # Sensitive environment variable policy: one of on, off or default.
  --slug: string # A new slug for the team.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id | is-empty) { error make --unspanned { msg: "path parameter 'teamId' must be non-empty" } }
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id)} | format pattern "/v2/teams/{team_id}"))
  let req_body = {"avatar": $avatar, "description": $description, "emailDomain": $email_domain, "enablePreviewFeedback": $enable_preview_feedback, "migrateExistingEnvVariablesToSensitive": $migrate_existing_env_variables_to_sensitive, "name": $name, "previewDeploymentSuffix": $preview_deployment_suffix, "regenerateInviteCode": $regenerate_invite_code, "remoteCaching": $remote_caching, "saml": $saml, "sensitiveEnvironmentVariablePolicy": $sensitive_environment_variable_policy, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List team members
#
# GET /v2/teams/{teamId}/members
# operationId: getTeamMembers
export def "teams-members get" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # Limit how many teams should be returned
  --since: float # Timestamp in milliseconds to only include members added since then.
  --until: float # Timestamp in milliseconds to only include members added until then.
  --search: string # Search team members by their name, username, and email.
  --role: string@role-completer # Only return members with the specified team role.
  --exclude-project: string # Exclude members who belong to the specified project.
]: nothing -> record<emailInviteCodes: table<createdAt: float, email: string, id: string, isDSyncUser: bool, role: string>, members: table<accessRequestedAt: float, avatar: string, bitbucket: record, confirmed: bool, createdAt: float, email: string, github: record, gitlab: record, joinedFrom: record, name: string, role: string, uid: string, username: string>, pagination: record<count: float, hasNext: bool, next: float, prev: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id | is-empty) { error make --unspanned { msg: "path parameter 'teamId' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "excludeProject" $exclude_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id)} | format pattern "/v2/teams/{team_id}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "since": $since, "until": $until, "search": $search, "role": $role, "excludeProject": $exclude_project} | compact), body: null}
}

# Get the User
#
# GET /v2/user
# operationId: getAuthUser
export def "user get-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<user: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List User Events
#
# GET /v3/events
# operationId: listUserEvents
export def "events list-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # Maximum number of items which may be returned.
  --since: string # Timestamp to only include items created since then.
  --until: string # Timestamp to only include items created until then.
  --types: string # Comma-delimited list of event \"types\" to filter the results by.
  --user-id: string # When retrieving events for a Team, the `userId` parameter may be specified to filter events generated by a specific member of the Team.
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<events: table<createdAt: float, entities: list, id: string, text: string, user: record, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "userId" $user_id "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "since": $since, "until": $until, "types": $types, "userId": $user_id, "teamId": $team_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Filter out secrets based on comma separated secret ids.
  --project-id: string # Filter out secrets that belong to a project.
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<pagination: record<count: float, next: float, prev: float>, secrets: table<created: string, createdAt: float, decryptable: bool, name: string, projectId: string, teamId: string, uid: string, userId: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "projectId" $project_id "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "projectId": $project_id, "teamId": $team_id} | compact), body: null}
}

# Get a single secret
#
# GET /v3/secrets/{idOrName}
# operationId: getSecret
export def "secrets get" [
  id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --decrypt: string@decrypt-completer # Whether to try to decrypt the value of the secret. Only works if `decryptable` has been set to `true` when the secret was created.
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<created: string, createdAt: float, decryptable: bool, name: string, projectId: string, teamId: string, uid: string, userId: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_name | is-empty) { error make --unspanned { msg: "path parameter 'idOrName' must be non-empty" } }
  let qp = [(serialize-qp "decrypt" $decrypt "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_or_name: (encode-path-segment $id_or_name)} | format pattern "/v3/secrets/{id_or_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"decrypt": $decrypt, "teamId": $team_id} | compact), body: null}
}

# Create an Auth Token
#
# POST /v3/user/tokens
# operationId: createAuthToken
export def "user-tokens create-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --expires-at: float
  --name: string
  --client-id: string
  --installation-id: string
  --type: any@type-completer-2
]: any -> record<bearerToken: string, token: record<activeAt: float, createdAt: float, expiresAt: float, id: string, name: string, origin: string, scopes: list<any>, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/user/tokens" $qp)
  let req_body = {"expiresAt": $expires_at, "name": $name, "clientId": $client_id, "installationId": $installation_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Delete an authentication token
#
# DELETE /v3/user/tokens/{tokenId}
# operationId: deleteAuthToken
export def "user-tokens delete-auth" [
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tokenId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($token_id | is-empty) { error make --unspanned { msg: "path parameter 'tokenId' must be non-empty" } }
  let full_url = (build-url $base ({token_id: (encode-path-segment $token_id)} | format pattern "/v3/user/tokens/{token_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List aliases
#
# GET /v4/aliases
# operationId: listAliases
export def "aliases list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # Get only aliases of the given domain name
  --qp-from: float # Get only aliases created after the provided timestamp
  --limit: float # Maximum number of aliases to list from a request
  --project-id: string # Filter aliases from the given `projectId`
  --since: float # Get aliases created after this JavaScript timestamp
  --until: float # Get aliases created before this JavaScript timestamp
  --rollback-deployment-id: string # Get aliases that would be rolled back for the given deployment
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<aliases: table<alias: string, created: string, createdAt: float, creator: record, deletedAt: float, deployment: record, deploymentId: string, projectId: string, protectionBypass: record, redirect: string, redirectStatusCode: float, uid: string, updatedAt: float>, pagination: record<count: float, next: float, prev: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "projectId" $project_id "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "rollbackDeploymentId" $rollback_deployment_id "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/aliases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain, "from": $qp_from, "limit": $limit, "projectId": $project_id, "since": $since, "until": $until, "rollbackDeploymentId": $rollback_deployment_id, "teamId": $team_id} | compact), body: null}
}

# Get an Alias
#
# GET /v4/aliases/{idOrAlias}
# operationId: getAlias
export def "aliases get-alias" [
  id_or_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: float # Get the alias only if it was created after the provided timestamp
  --project-id: string # Get the alias only if it is assigned to the provided project ID
  --since: float # Get the alias only if it was created after this JavaScript timestamp
  --until: float # Get the alias only if it was created before this JavaScript timestamp
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<alias: string, created: string, createdAt: float, creator: record<email: string, uid: string, username: string>, deletedAt: float, deployment: record<id: string, meta: string, url: string>, deploymentId: string, projectId: string, protectionBypass: record, redirect: string, redirectStatusCode: float, uid: string, updatedAt: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_alias | is-empty) { error make --unspanned { msg: "path parameter 'idOrAlias' must be non-empty" } }
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "projectId" $project_id "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_or_alias: (encode-path-segment $id_or_alias)} | format pattern "/v4/aliases/{id_or_alias}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"from": $qp_from, "projectId": $project_id, "since": $since, "until": $until, "teamId": $team_id} | compact), body: null}
}

# Register or transfer-in a new Domain
#
# POST /v4/domains
# operationId: createOrTransferDomain
export def "domains create-or-transfer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --method: string # The domain operation to perform. It can be either `add` or `transfer-in`.
  --name: string # The domain name you want to add.
  --body-token: string # The move-in token from Move Requested email.
  --auth-code: string # The authorization code assigned to the domain.
  --expected-price: float # The price you expect to be charged for the required 1 year renewal.
  --cdn-enabled: oneof<nothing, bool> # Whether the domain has the Vercel Edge Network enabled or not.
]: any -> record<domain: record<boughtAt: float, createdAt: float, creator: record<customerId: string, email: string, id: string, isDomainReseller: bool, username: string>, customNameservers: list<string>, expiresAt: float, id: string, intendedNameservers: list<string>, name: string, nameservers: list<string>, orderedAt: float, renew: bool, serviceType: string, transferStartedAt: float, transferredAt: float, verified: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/domains" $qp)
  let req_body = {"method": $method, "name": $name, "token": $body_token, "authCode": $auth_code, "expectedPrice": $expected_price, "cdnEnabled": $cdn_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Purchase a domain
#
# POST /v4/domains/buy
# operationId: buyDomain
export def "domains-buy create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --expected-price: float # The price you expect to be charged for the purchase.
  name: string # The domain name to purchase.
  --renew: oneof<nothing, bool> # Indicates whether the domain should be automatically renewed.
]: any -> record<domain: record<created: float, ns: list<string>, pending: bool, uid: string, verified: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/domains/buy" $qp)
  let req_body = {"expectedPrice": $expected_price, "name": $name, "renew": $renew} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Check the price for a domain
#
# GET /v4/domains/price
# operationId: checkDomainPrice
export def "domains-price check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the domain for which the price needs to be checked.
  --type: string@type-completer-3 # In which status of the domain the price needs to be checked.
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<period: float, price: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/domains/price" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "type": $type, "teamId": $team_id} | compact), body: null}
}

# Check a Domain Availability
#
# GET /v4/domains/status
# operationId: checkDomainStatus
export def "domains-status check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the domain for which we would like to check the status.
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<available: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/domains/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "teamId": $team_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Maximum number of records to list from a request.
  --since: string # Get records created after this JavaScript timestamp.
  --until: string # Get records created before this JavaScript timestamp.
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain: (encode-path-segment $domain)} | format pattern "/v4/domains/{domain}/records") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "since": $since, "until": $until, "teamId": $team_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # Maximum number of domains to list from a request.
  --since: float # Get domains created after this JavaScript timestamp.
  --until: float # Get domains created before this JavaScript timestamp.
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<domains: table<boughtAt: float, createdAt: float, creator: record, customNameservers: list, expiresAt: float, id: string, intendedNameservers: list, name: string, nameservers: list, orderedAt: float, renew: bool, serviceType: string, transferStartedAt: float, transferredAt: float, verified: bool>, pagination: record<count: float, next: float, prev: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v5/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "since": $since, "until": $until, "teamId": $team_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<domain: record<boughtAt: float, createdAt: float, creator: record<customerId: string, email: string, id: string, isDomainReseller: bool, username: string>, customNameservers: list<string>, expiresAt: float, id: string, intendedNameservers: list<string>, name: string, nameservers: list<string>, orderedAt: float, renew: bool, serviceType: string, suffix: bool, transferStartedAt: float, transferredAt: float, verified: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain: (encode-path-segment $domain)} | format pattern "/v5/domains/{domain}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# List Auth Tokens
#
# GET /v5/user/tokens
# operationId: listAuthTokens
export def "user-tokens list-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<pagination: record<count: float, next: float, prev: float>, testingToken: record<activeAt: float, createdAt: float, expiresAt: float, id: string, name: string, origin: string, scopes: list<any>, type: string>, tokens: table<activeAt: float, createdAt: float, expiresAt: float, id: string, name: string, origin: string, scopes: list, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v5/user/tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Auth Token Metadata
#
# GET /v5/user/tokens/{tokenId}
# operationId: getAuthToken
export def "user-tokens get-auth" [
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<token: record<activeAt: float, createdAt: float, expiresAt: float, id: string, name: string, origin: string, scopes: list<any>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($token_id | is-empty) { error make --unspanned { msg: "path parameter 'tokenId' must be non-empty" } }
  let full_url = (build-url $base ({token_id: (encode-path-segment $token_id)} | format pattern "/v5/user/tokens/{token_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app: string # Name of the deployment.
  --qp-from: float # Gets the deployment created after this Date timestamp. (default: current time)
  --limit: float # Maximum number of deployments to list from a request.
  --project-id: string # Filter deployments from the given `projectId`.
  --target: string@target-completer-1 # Filter deployments based on the environment.
  --qp-to: float # Gets the deployment created before this Date timestamp. (default: current time)
  --users: string # Filter out deployments based on users who have created the deployment.
  --since: float # Get Deployments created after this JavaScript timestamp.
  --until: float # Get Deployments created before this JavaScript timestamp.
  --state: string # Filter deployments based on their state (`BUILDING`, `ERROR`, `INITIALIZING`, `QUEUED`, `READY`, `CANCELED`)
  --rollback-candidate: oneof<nothing, bool> # Filter deployments based on their rollback candidacy
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<deployments: table<aliasAssigned: any, aliasError: record, buildingAt: float, checksConclusion: string, checksState: string, created: float, createdAt: float, creator: record, inspectorUrl: string, isRollbackCandidate: bool, meta: record, name: string, ready: float, source: string, state: string, target: string, type: string, uid: string, url: string>, pagination: record<count: float, next: float, prev: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app" $app "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "projectId" $project_id "scalar") (serialize-qp "target" $target "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "users" $users "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "rollbackCandidate" $rollback_candidate "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v6/deployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"app": $app, "from": $qp_from, "limit": $limit, "projectId": $project_id, "target": $target, "to": $qp_to, "users": $users, "since": $since, "until": $until, "state": $state, "rollbackCandidate": $rollback_candidate, "teamId": $team_id} | compact), body: null}
}

# List Deployment Files
#
# GET /v6/deployments/{id}/files
# operationId: listDeploymentFiles
export def "deployments-files list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> table<children: list<any>, contentType: string, mode: float, name: string, symlink: string, type: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v6/deployments/{id}/files") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Get Deployment File Contents
#
# GET /v6/deployments/{id}/files/{fileId}
# operationId: getDeploymentFileContents
export def "deployments-files get-contents" [
  id: string
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'fileId' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), file_id: (encode-path-segment $file_id)} | format pattern "/v6/deployments/{id}/files/{file_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain: (encode-path-segment $domain)} | format pattern "/v6/domains/{domain}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<acceptedChallenges: list<string>, configuredBy: string, misconfigured: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain: (encode-path-segment $domain)} | format pattern "/v6/domains/{domain}/config") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Issue a new cert
#
# POST /v7/certs
# operationId: issueCert
export def "certs create-issue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --cns: list<string> # The common names the cert should be issued for
]: any -> record<autoRenew: bool, cns: list<string>, createdAt: float, expiresAt: float, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v7/certs" $qp)
  let req_body = {"cns": $cns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Upload a cert
#
# PUT /v7/certs
# operationId: uploadCert
export def "certs upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  ca: string # The certificate authority
  cert: string # The certificate
  key: string # The certificate key
  --skip-validation: oneof<nothing, bool> # Skip validation of the certificate
]: any -> record<autoRenew: bool, cns: list<string>, createdAt: float, expiresAt: float, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v7/certs" $qp)
  let req_body = {"ca": $ca, "cert": $cert, "key": $key, "skipValidation": $skip_validation} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Remove cert
#
# DELETE /v7/certs/{id}
# operationId: removeCert
export def "certs delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v7/certs/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<autoRenew: bool, cns: list<string>, createdAt: float, expiresAt: float, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v7/certs/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Query information about an artifact
#
# POST /v8/artifacts
# operationId: artifactQuery
export def "artifacts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  hashes: list<string> # artifact hashes
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v8/artifacts" $qp)
  let req_body = {"hashes": $hashes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Record an artifacts cache usage event
#
# POST /v8/artifacts/events
# operationId: recordEvents
export def "artifacts-events create-record" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --x-artifact-client-ci: string # The continuous integration or delivery environment where this artifact is downloaded.
  --x-artifact-client-interactive: int # 1 if the client is an interactive shell. Otherwise 0
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v8/artifacts/events" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-artifact-client-ci": $x_artifact_client_ci, "x-artifact-client-interactive": $x_artifact_client_interactive} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Get status of Remote Caching for this principal
#
# GET /v8/artifacts/status
# operationId: status
export def "artifacts-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v8/artifacts/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Download a cache artifact
#
# GET /v8/artifacts/{hash}
# operationId: downloadArtifact
export def "artifacts download" [
  hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --x-artifact-client-ci: string # The continuous integration or delivery environment where this artifact is downloaded.
  --x-artifact-client-interactive: int # 1 if the client is an interactive shell. Otherwise 0
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hash | is-empty) { error make --unspanned { msg: "path parameter 'hash' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({hash: (encode-path-segment $hash)} | format pattern "/v8/artifacts/{hash}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-artifact-client-ci": $x_artifact_client_ci, "x-artifact-client-interactive": $x_artifact_client_interactive} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Check if a cache artifact exists
#
# HEAD /v8/artifacts/{hash}
# operationId: artifactExists
export def "artifacts head-exists" [
  hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hash | is-empty) { error make --unspanned { msg: "path parameter 'hash' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({hash: (encode-path-segment $hash)} | format pattern "/v8/artifacts/{hash}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Upload a cache artifact
#
# PUT /v8/artifacts/{hash}
# operationId: uploadArtifact
export def "artifacts upload" [
  hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --content-length: float # The artifact size in bytes
  --x-artifact-duration: float # The time taken to generate the uploaded artifact in milliseconds.
  --x-artifact-client-ci: string # The continuous integration or delivery environment where this artifact was generated.
  --x-artifact-client-interactive: int # 1 if the client is an interactive shell. Otherwise 0
  --x-artifact-tag: string # The base64 encoded tag for this artifact. The value is sent back to clients when the artifact is downloaded as the header `x-artifact-tag`
  --body: any
]: any -> record<urls: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hash | is-empty) { error make --unspanned { msg: "path parameter 'hash' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({hash: (encode-path-segment $hash)} | format pattern "/v8/artifacts/{hash}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Length": $content_length, "x-artifact-duration": $x_artifact_duration, "x-artifact-client-ci": $x_artifact_client_ci, "x-artifact-client-interactive": $x_artifact_client_interactive, "x-artifact-tag": $x_artifact_tag} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # Query only projects updated after the given timestamp
  --git-fork-protection: string@git-fork-protection-completer # Specifies whether PRs from Git forks should require a team member's authorization before it can be deployed
  --limit: string # Limit the number of projects returned
  --search: string # Search projects by the name field
  --repo: string # Filter results by repo. Also used for project count
  --repo-id: string # Filter results by Repository ID.
  --repo-url: string # Filter results by Repository URL.
  --exclude-repos: string # Filter results by excluding those projects that belong to a repo
  --edge-config-id: string # Filter results by connected Edge Config ID
  --edge-config-token-id: string # Filter results by connected Edge Config Token ID
  --connect-configuration-id: string # Filter results by linked Connect configuration ID
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<pagination: record<count: float, next: float, prev: float>, projects: table<accountId: string, analytics: record, autoExposeSystemEnvs: bool, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurationId: string, createdAt: float, devCommand: string, directoryListing: bool, enablePreviewFeedback: bool, env: list, framework: string, gitForkProtection: bool, hasFloatingAliases: bool, id: string, installCommand: string, lastRollbackTarget: record, latestDeployments: list, link: any, live: bool, name: string, nodeVersion: string, outputDirectory: string, passwordProtection: record, permissions: record, protectionBypass: record, publicSource: bool, rootDirectory: string, serverlessFunctionRegion: string, skipGitConnectDuringLink: bool, sourceFilesOutsideRootDirectory: bool, ssoProtection: record, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "gitForkProtection" $git_fork_protection "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "repo" $repo "scalar") (serialize-qp "repoId" $repo_id "scalar") (serialize-qp "repoUrl" $repo_url "scalar") (serialize-qp "excludeRepos" $exclude_repos "scalar") (serialize-qp "edgeConfigId" $edge_config_id "scalar") (serialize-qp "edgeConfigTokenId" $edge_config_token_id "scalar") (serialize-qp "connectConfigurationId" $connect_configuration_id "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v9/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"from": $qp_from, "gitForkProtection": $git_fork_protection, "limit": $limit, "search": $search, "repo": $repo, "repoId": $repo_id, "repoUrl": $repo_url, "excludeRepos": $exclude_repos, "edgeConfigId": $edge_config_id, "edgeConfigTokenId": $edge_config_token_id, "connectConfigurationId": $connect_configuration_id, "teamId": $team_id} | compact), body: null}
}

# Create a new project
#
# POST /v9/projects
# operationId: createProject
# --environmentVariables item shape: {gitBranch?: string, key: string, target: any, type?: "system"|"secret"|"encrypted"|"plain", value: string}
# --gitRepository shape: {repo: string, type: "github"|"gitlab"|"bitbucket"}
@deprecated --flag skip-git-connect-during-link
export def "projects create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --build-command: string # The build command for this project. When `null` is used this value will be automatically detected (nullable)
  --command-for-ignoring-build-step: string # nullable
  --dev-command: string # The dev command for this project. When `null` is used this value will be automatically detected (nullable)
  --environment-variables: list # Collection of ENV Variables the Project will use — item shape: {gitBranch?: string, key: string, target: any, type?: "system"|"secret"|"encrypted"|"plain", value: string}
  --framework: any@framework-completer # The framework that is being used for this project. When `null` is used no framework is selected
  --git-repository: record # The Git Repository that will be connected to the project. When this is defined, any pushes to the specified connected Git Repository will be automatically deployed — shape: {repo: string, type: "github"|"gitlab"|"bitbucket"}
  --install-command: string # The install command for this project. When `null` is used this value will be automatically detected (nullable)
  name: string # The desired name for the project
  --output-directory: string # The output directory of the project. When `null` is used this value will be automatically detected (nullable)
  --public-source: oneof<nothing, bool> # Specifies whether the source code and logs of the deployments for this project should be public or not (nullable)
  --root-directory: string # The name of a directory or relative path to the source code of your project. When `null` is used it will default to the project root (nullable)
  --serverless-function-region: string # The region to deploy Serverless Functions in this project (nullable)
  --skip-git-connect-during-link: oneof<nothing, bool> # Opts-out of the message prompting a CLI user to connect a Git repository in `vercel link`. (DEPRECATED)
]: any -> record<accountId: string, analytics: record<canceledAt: float, disabledAt: float, enabledAt: float, id: string, paidAt: float, sampleRatePercent: float, spendLimitInDollars: float>, autoExposeSystemEnvs: bool, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurationId: string, createdAt: float, devCommand: string, directoryListing: bool, enablePreviewFeedback: bool, env: table<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string>, framework: string, gitForkProtection: bool, hasFloatingAliases: bool, id: string, installCommand: string, lastRollbackTarget: record<fromDeploymentId: string, jobStatus: string, requestedAt: float, toDeploymentId: string>, latestDeployments: table<alias: list, aliasAssigned: any, aliasError: record, aliasFinal: string, automaticAliases: list, buildingAt: float, builds: list, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record, deploymentHostname: string, forced: bool, id: string, meta: record, monorepoManager: string, name: string, plan: string, previewCommentsEnabled: bool, private: bool, readyAt: float, readyState: string, requestedAt: float, target: string, teamId: string, type: string, url: string, userId: string, withCache: bool>, link: any, live: bool, name: string, nodeVersion: string, outputDirectory: string, passwordProtection: record<deploymentType: string>, permissions: record<Monitoring: list<string>, aliasGlobal: list<string>, aliasProject: list<string>, aliasProtectionBypass: list<string>, analytics: list<string>, analyticsSampling: list<string>, analyticsUsage: list<string>, auditLog: list<string>, awsBillingIntegration: list<string>, billingAddress: list<string>, billingInformation: list<string>, billingInvoice: list<string>, billingInvoiceEmailRecipient: list<string>, billingInvoiceLanguage: list<string>, billingPlan: list<string>, billingPurchaseOrder: list<string>, billingTaxId: list<string>, cacheArtifact: list<string>, cacheArtifactUsageEvent: list<string>, concurrentBuilds: list<string>, connect: list<string>, connectConfiguration: list<string>, connectConfigurationLink: list<string>, deployment: list<string>, deploymentCheck: list<string>, deploymentCheckPreview: list<string>, deploymentPreview: list<string>, deploymentPrivate: list<string>, deploymentProductionGit: list<string>, deploymentRollback: list<string>, domain: list<string>, domainAcceptDelegation: list<string>, domainAuthCodes: list<string>, domainCertificate: list<string>, domainCheckConfig: list<string>, domainMove: list<string>, domainPurchase: list<string>, domainRecord: list<string>, domainTransferIn: list<string>, edgeConfig: list<string>, edgeConfigItem: list<string>, edgeConfigToken: list<string>, endpointVerification: list<string>, event: list<string>, fileUpload: list<string>, gitRepository: list<string>, integration: list<string>, integrationConfiguration: list<string>, integrationConfigurationProjects: list<string>, integrationConfigurationTransfer: list<string>, integrationVercelConfigurationOverride: list<string>, job: list<string>, logDrain: list<string>, monitoringChart: list<string>, monitoringQuery: list<string>, notificationDomainConfiguration: list<string>, notificationDomainExpire: list<string>, notificationDomainMoved: list<string>, notificationDomainPurchase: list<string>, notificationDomainRenewal: list<string>, notificationDomainTransfer: list<string>, notificationDomainUnverified: list<string>, notificationPaymentFailed: list<string>, notificationSpendCap: list<string>, notificationUsageAlert: list<string>, openTelemetryEndpoint: list<string>, passwordProtection: list<string>, paymentMethod: list<string>, permissions: list<string>, previewDeploymentSuffix: list<string>, proTrialOnboarding: list<string>, project: list<string>, projectDeploymentHook: list<string>, projectDomain: list<string>, projectDomainMove: list<string>, projectEnvVars: list<string>, projectEnvVarsProduction: list<string>, projectEnvVarsUnownedByIntegration: list<string>, projectIntegrationConfiguration: list<string>, projectLink: list<string>, projectMember: list<string>, projectProductionBranch: list<string>, projectProtectionBypass: list<string>, projectTransfer: list<string>, rateLimit: list<string>, redis: list<string>, remoteCaching: list<string>, samlConfig: list<string>, secret: list<string>, sensitiveEnvironmentVariablePolicy: list<string>, sharedEnvVars: list<string>, sharedEnvVarsProduction: list<string>, spendCapConfiguration: list<string>, spendCapState: list<string>, supportCase: list<string>, supportCaseComment: list<string>, team: list<string>, teamAccessRequest: list<string>, teamFellowMembership: list<string>, teamInvite: list<string>, teamInviteCode: list<string>, teamJoin: list<string>, teamOwnMembership: list<string>, teamOwnMembershipDisconnectSAML: list<string>, token: list<string>, usage: list<string>, user: list<string>, userConnection: list<string>, webAnalytics: list<string>, webhook: list<string>, webhook_event: list<string>>, protectionBypass: record, publicSource: bool, rootDirectory: string, serverlessFunctionRegion: string, skipGitConnectDuringLink: bool, sourceFilesOutsideRootDirectory: bool, ssoProtection: record<deploymentType: string>, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v9/projects" $qp)
  let req_body = {"buildCommand": $build_command, "commandForIgnoringBuildStep": $command_for_ignoring_build_step, "devCommand": $dev_command, "environmentVariables": $environment_variables, "framework": $framework, "gitRepository": $git_repository, "installCommand": $install_command, "name": $name, "outputDirectory": $output_directory, "publicSource": $public_source, "rootDirectory": $root_directory, "serverlessFunctionRegion": $serverless_function_region, "skipGitConnectDuringLink": $skip_git_connect_during_link} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Delete a Project
#
# DELETE /v9/projects/{idOrName}
# operationId: deleteProject
export def "projects delete" [
  id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_name | is-empty) { error make --unspanned { msg: "path parameter 'idOrName' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_or_name: (encode-path-segment $id_or_name)} | format pattern "/v9/projects/{id_or_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Find a project by id or name
#
# GET /v9/projects/{idOrName}
# operationId: getProject
export def "projects get" [
  id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<accountId: string, analytics: record<canceledAt: float, disabledAt: float, enabledAt: float, id: string, paidAt: float, sampleRatePercent: float, spendLimitInDollars: float>, autoExposeSystemEnvs: bool, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurationId: string, createdAt: float, devCommand: string, directoryListing: bool, enablePreviewFeedback: bool, env: table<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string>, framework: string, gitForkProtection: bool, hasFloatingAliases: bool, id: string, installCommand: string, lastRollbackTarget: record<fromDeploymentId: string, jobStatus: string, requestedAt: float, toDeploymentId: string>, latestDeployments: table<alias: list, aliasAssigned: any, aliasError: record, aliasFinal: string, automaticAliases: list, buildingAt: float, builds: list, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record, deploymentHostname: string, forced: bool, id: string, meta: record, monorepoManager: string, name: string, plan: string, previewCommentsEnabled: bool, private: bool, readyAt: float, readyState: string, requestedAt: float, target: string, teamId: string, type: string, url: string, userId: string, withCache: bool>, link: any, live: bool, name: string, nodeVersion: string, outputDirectory: string, passwordProtection: record<deploymentType: string>, permissions: record<Monitoring: list<string>, aliasGlobal: list<string>, aliasProject: list<string>, aliasProtectionBypass: list<string>, analytics: list<string>, analyticsSampling: list<string>, analyticsUsage: list<string>, auditLog: list<string>, awsBillingIntegration: list<string>, billingAddress: list<string>, billingInformation: list<string>, billingInvoice: list<string>, billingInvoiceEmailRecipient: list<string>, billingInvoiceLanguage: list<string>, billingPlan: list<string>, billingPurchaseOrder: list<string>, billingTaxId: list<string>, cacheArtifact: list<string>, cacheArtifactUsageEvent: list<string>, concurrentBuilds: list<string>, connect: list<string>, connectConfiguration: list<string>, connectConfigurationLink: list<string>, deployment: list<string>, deploymentCheck: list<string>, deploymentCheckPreview: list<string>, deploymentPreview: list<string>, deploymentPrivate: list<string>, deploymentProductionGit: list<string>, deploymentRollback: list<string>, domain: list<string>, domainAcceptDelegation: list<string>, domainAuthCodes: list<string>, domainCertificate: list<string>, domainCheckConfig: list<string>, domainMove: list<string>, domainPurchase: list<string>, domainRecord: list<string>, domainTransferIn: list<string>, edgeConfig: list<string>, edgeConfigItem: list<string>, edgeConfigToken: list<string>, endpointVerification: list<string>, event: list<string>, fileUpload: list<string>, gitRepository: list<string>, integration: list<string>, integrationConfiguration: list<string>, integrationConfigurationProjects: list<string>, integrationConfigurationTransfer: list<string>, integrationVercelConfigurationOverride: list<string>, job: list<string>, logDrain: list<string>, monitoringChart: list<string>, monitoringQuery: list<string>, notificationDomainConfiguration: list<string>, notificationDomainExpire: list<string>, notificationDomainMoved: list<string>, notificationDomainPurchase: list<string>, notificationDomainRenewal: list<string>, notificationDomainTransfer: list<string>, notificationDomainUnverified: list<string>, notificationPaymentFailed: list<string>, notificationSpendCap: list<string>, notificationUsageAlert: list<string>, openTelemetryEndpoint: list<string>, passwordProtection: list<string>, paymentMethod: list<string>, permissions: list<string>, previewDeploymentSuffix: list<string>, proTrialOnboarding: list<string>, project: list<string>, projectDeploymentHook: list<string>, projectDomain: list<string>, projectDomainMove: list<string>, projectEnvVars: list<string>, projectEnvVarsProduction: list<string>, projectEnvVarsUnownedByIntegration: list<string>, projectIntegrationConfiguration: list<string>, projectLink: list<string>, projectMember: list<string>, projectProductionBranch: list<string>, projectProtectionBypass: list<string>, projectTransfer: list<string>, rateLimit: list<string>, redis: list<string>, remoteCaching: list<string>, samlConfig: list<string>, secret: list<string>, sensitiveEnvironmentVariablePolicy: list<string>, sharedEnvVars: list<string>, sharedEnvVarsProduction: list<string>, spendCapConfiguration: list<string>, spendCapState: list<string>, supportCase: list<string>, supportCaseComment: list<string>, team: list<string>, teamAccessRequest: list<string>, teamFellowMembership: list<string>, teamInvite: list<string>, teamInviteCode: list<string>, teamJoin: list<string>, teamOwnMembership: list<string>, teamOwnMembershipDisconnectSAML: list<string>, token: list<string>, usage: list<string>, user: list<string>, userConnection: list<string>, webAnalytics: list<string>, webhook: list<string>, webhook_event: list<string>>, protectionBypass: record, publicSource: bool, rootDirectory: string, serverlessFunctionRegion: string, skipGitConnectDuringLink: bool, sourceFilesOutsideRootDirectory: bool, ssoProtection: record<deploymentType: string>, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_name | is-empty) { error make --unspanned { msg: "path parameter 'idOrName' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_or_name: (encode-path-segment $id_or_name)} | format pattern "/v9/projects/{id_or_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Update an existing project
#
# PATCH /v9/projects/{idOrName}
# operationId: updateProject
# --passwordProtection shape: {deploymentType: "all"|"preview", password?: string}
# --ssoProtection shape: {deploymentType: "all"|"preview"}
@deprecated --flag skip-git-connect-during-link
export def "projects update" [
  id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --auto-expose-system-envs: oneof<nothing, bool>
  --build-command: string # The build command for this project. When `null` is used this value will be automatically detected (nullable)
  --command-for-ignoring-build-step: string # nullable
  --dev-command: string # The dev command for this project. When `null` is used this value will be automatically detected (nullable)
  --directory-listing: oneof<nothing, bool>
  --enable-preview-feedback: oneof<nothing, bool> # Opt-in to Preview comments on the project level (nullable)
  --framework: string@framework-completer # The framework that is being used for this project. When `null` is used no framework is selected (nullable)
  --git-fork-protection: oneof<nothing, bool> # Specifies whether PRs from Git forks should require a team member's authorization before it can be deployed
  --install-command: string # The install command for this project. When `null` is used this value will be automatically detected (nullable)
  --name: string # The desired name for the project
  --node-version: string@node-version-completer
  --output-directory: string # The output directory of the project. When `null` is used this value will be automatically detected (nullable)
  --password-protection: record # Allows to protect project deployments with a password (nullable) — shape: {deploymentType: "all"|"preview", password?: string}
  --public-source: oneof<nothing, bool> # Specifies whether the source code and logs of the deployments for this project should be public or not (nullable)
  --root-directory: string # The name of a directory or relative path to the source code of your project. When `null` is used it will default to the project root (nullable)
  --serverless-function-region: string # The region to deploy Serverless Functions in this project (nullable)
  --skip-git-connect-during-link: oneof<nothing, bool> # Opts-out of the message prompting a CLI user to connect a Git repository in `vercel link`. (DEPRECATED)
  --source-files-outside-root-directory: oneof<nothing, bool> # Indicates if there are source files outside of the root directory
  --sso-protection: record # Ensures visitors to your Preview Deployments are logged into Vercel and have a minimum of Viewer access on your team (nullable) — shape: {deploymentType: "all"|"preview"}
]: any -> record<accountId: string, analytics: record<canceledAt: float, disabledAt: float, enabledAt: float, id: string, paidAt: float, sampleRatePercent: float, spendLimitInDollars: float>, autoExposeSystemEnvs: bool, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurationId: string, createdAt: float, devCommand: string, directoryListing: bool, enablePreviewFeedback: bool, env: table<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string>, framework: string, gitForkProtection: bool, hasFloatingAliases: bool, id: string, installCommand: string, lastRollbackTarget: record<fromDeploymentId: string, jobStatus: string, requestedAt: float, toDeploymentId: string>, latestDeployments: table<alias: list, aliasAssigned: any, aliasError: record, aliasFinal: string, automaticAliases: list, buildingAt: float, builds: list, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record, deploymentHostname: string, forced: bool, id: string, meta: record, monorepoManager: string, name: string, plan: string, previewCommentsEnabled: bool, private: bool, readyAt: float, readyState: string, requestedAt: float, target: string, teamId: string, type: string, url: string, userId: string, withCache: bool>, link: any, live: bool, name: string, nodeVersion: string, outputDirectory: string, passwordProtection: record<deploymentType: string>, permissions: record<Monitoring: list<string>, aliasGlobal: list<string>, aliasProject: list<string>, aliasProtectionBypass: list<string>, analytics: list<string>, analyticsSampling: list<string>, analyticsUsage: list<string>, auditLog: list<string>, awsBillingIntegration: list<string>, billingAddress: list<string>, billingInformation: list<string>, billingInvoice: list<string>, billingInvoiceEmailRecipient: list<string>, billingInvoiceLanguage: list<string>, billingPlan: list<string>, billingPurchaseOrder: list<string>, billingTaxId: list<string>, cacheArtifact: list<string>, cacheArtifactUsageEvent: list<string>, concurrentBuilds: list<string>, connect: list<string>, connectConfiguration: list<string>, connectConfigurationLink: list<string>, deployment: list<string>, deploymentCheck: list<string>, deploymentCheckPreview: list<string>, deploymentPreview: list<string>, deploymentPrivate: list<string>, deploymentProductionGit: list<string>, deploymentRollback: list<string>, domain: list<string>, domainAcceptDelegation: list<string>, domainAuthCodes: list<string>, domainCertificate: list<string>, domainCheckConfig: list<string>, domainMove: list<string>, domainPurchase: list<string>, domainRecord: list<string>, domainTransferIn: list<string>, edgeConfig: list<string>, edgeConfigItem: list<string>, edgeConfigToken: list<string>, endpointVerification: list<string>, event: list<string>, fileUpload: list<string>, gitRepository: list<string>, integration: list<string>, integrationConfiguration: list<string>, integrationConfigurationProjects: list<string>, integrationConfigurationTransfer: list<string>, integrationVercelConfigurationOverride: list<string>, job: list<string>, logDrain: list<string>, monitoringChart: list<string>, monitoringQuery: list<string>, notificationDomainConfiguration: list<string>, notificationDomainExpire: list<string>, notificationDomainMoved: list<string>, notificationDomainPurchase: list<string>, notificationDomainRenewal: list<string>, notificationDomainTransfer: list<string>, notificationDomainUnverified: list<string>, notificationPaymentFailed: list<string>, notificationSpendCap: list<string>, notificationUsageAlert: list<string>, openTelemetryEndpoint: list<string>, passwordProtection: list<string>, paymentMethod: list<string>, permissions: list<string>, previewDeploymentSuffix: list<string>, proTrialOnboarding: list<string>, project: list<string>, projectDeploymentHook: list<string>, projectDomain: list<string>, projectDomainMove: list<string>, projectEnvVars: list<string>, projectEnvVarsProduction: list<string>, projectEnvVarsUnownedByIntegration: list<string>, projectIntegrationConfiguration: list<string>, projectLink: list<string>, projectMember: list<string>, projectProductionBranch: list<string>, projectProtectionBypass: list<string>, projectTransfer: list<string>, rateLimit: list<string>, redis: list<string>, remoteCaching: list<string>, samlConfig: list<string>, secret: list<string>, sensitiveEnvironmentVariablePolicy: list<string>, sharedEnvVars: list<string>, sharedEnvVarsProduction: list<string>, spendCapConfiguration: list<string>, spendCapState: list<string>, supportCase: list<string>, supportCaseComment: list<string>, team: list<string>, teamAccessRequest: list<string>, teamFellowMembership: list<string>, teamInvite: list<string>, teamInviteCode: list<string>, teamJoin: list<string>, teamOwnMembership: list<string>, teamOwnMembershipDisconnectSAML: list<string>, token: list<string>, usage: list<string>, user: list<string>, userConnection: list<string>, webAnalytics: list<string>, webhook: list<string>, webhook_event: list<string>>, protectionBypass: record, publicSource: bool, rootDirectory: string, serverlessFunctionRegion: string, skipGitConnectDuringLink: bool, sourceFilesOutsideRootDirectory: bool, ssoProtection: record<deploymentType: string>, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_name | is-empty) { error make --unspanned { msg: "path parameter 'idOrName' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_or_name: (encode-path-segment $id_or_name)} | format pattern "/v9/projects/{id_or_name}") $qp)
  let req_body = {"autoExposeSystemEnvs": $auto_expose_system_envs, "buildCommand": $build_command, "commandForIgnoringBuildStep": $command_for_ignoring_build_step, "devCommand": $dev_command, "directoryListing": $directory_listing, "enablePreviewFeedback": $enable_preview_feedback, "framework": $framework, "gitForkProtection": $git_fork_protection, "installCommand": $install_command, "name": $name, "nodeVersion": $node_version, "outputDirectory": $output_directory, "passwordProtection": $password_protection, "publicSource": $public_source, "rootDirectory": $root_directory, "serverlessFunctionRegion": $serverless_function_region, "skipGitConnectDuringLink": $skip_git_connect_during_link, "sourceFilesOutsideRootDirectory": $source_files_outside_root_directory, "ssoProtection": $sso_protection} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Retrieve project domains by project by id or name
#
# GET /v9/projects/{idOrName}/domains
# operationId: getProjectDomains
export def "projects-domains list" [
  id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --production: string@production-completer # Filters only production domains when set to `true`. (default: false)
  --git-branch: string # Filters domains based on specific branch.
  --redirects: string@redirects-completer # Excludes redirect project domains when \"false\". Includes redirect project domains when \"true\" (default). (default: true)
  --redirect: string # Filters domains based on their redirect target.
  --verified: string@verified-completer # Filters domains based on their verification status.
  --limit: float # Maximum number of domains to list from a request (max 100).
  --since: float # Get domains created after this JavaScript timestamp.
  --until: float # Get domains created before this JavaScript timestamp.
  --order: string@order-completer # Domains sort order by createdAt (default: DESC)
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<domains: table<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: list, verified: bool>, pagination: record<count: float, next: float, prev: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_name | is-empty) { error make --unspanned { msg: "path parameter 'idOrName' must be non-empty" } }
  let qp = [(serialize-qp "production" $production "scalar") (serialize-qp "gitBranch" $git_branch "scalar") (serialize-qp "redirects" $redirects "scalar") (serialize-qp "redirect" $redirect "scalar") (serialize-qp "verified" $verified "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_or_name: (encode-path-segment $id_or_name)} | format pattern "/v9/projects/{id_or_name}/domains") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"production": $production, "gitBranch": $git_branch, "redirects": $redirects, "redirect": $redirect, "verified": $verified, "limit": $limit, "since": $since, "until": $until, "order": $order, "teamId": $team_id} | compact), body: null}
}

# Add a domain to a project
#
# POST /v9/projects/{idOrName}/domains
# operationId: addProjectDomain
export def "projects-domains create" [
  id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --git-branch: string # Git branch to link the project domain (nullable)
  name: string # The project domain name
  --redirect: string # Target destination domain for redirect (nullable)
  --redirect-status-code: int@redirect-status-code-completer # Status code for domain redirect (nullable)
]: any -> record<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: table<domain: string, reason: string, type: string, value: string>, verified: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_name | is-empty) { error make --unspanned { msg: "path parameter 'idOrName' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_or_name: (encode-path-segment $id_or_name)} | format pattern "/v9/projects/{id_or_name}/domains") $qp)
  let req_body = {"gitBranch": $git_branch, "name": $name, "redirect": $redirect, "redirectStatusCode": $redirect_status_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Remove a domain from a project
#
# DELETE /v9/projects/{idOrName}/domains/{domain}
# operationId: removeProjectDomain
export def "projects-domains delete" [
  id_or_name: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_name | is-empty) { error make --unspanned { msg: "path parameter 'idOrName' must be non-empty" } }
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_or_name: (encode-path-segment $id_or_name), domain: (encode-path-segment $domain)} | format pattern "/v9/projects/{id_or_name}/domains/{domain}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Get a project domain
#
# GET /v9/projects/{idOrName}/domains/{domain}
# operationId: getProjectDomain
export def "projects-domains get" [
  id_or_name: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: table<domain: string, reason: string, type: string, value: string>, verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_name | is-empty) { error make --unspanned { msg: "path parameter 'idOrName' must be non-empty" } }
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_or_name: (encode-path-segment $id_or_name), domain: (encode-path-segment $domain)} | format pattern "/v9/projects/{id_or_name}/domains/{domain}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Update a project domain
#
# PATCH /v9/projects/{idOrName}/domains/{domain}
# operationId: updateProjectDomain
export def "projects-domains update" [
  id_or_name: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --git-branch: string # Git branch to link the project domain (nullable)
  --redirect: string # Target destination domain for redirect (nullable)
  --redirect-status-code: int@redirect-status-code-completer # Status code for domain redirect (nullable)
]: any -> record<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: table<domain: string, reason: string, type: string, value: string>, verified: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_name | is-empty) { error make --unspanned { msg: "path parameter 'idOrName' must be non-empty" } }
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_or_name: (encode-path-segment $id_or_name), domain: (encode-path-segment $domain)} | format pattern "/v9/projects/{id_or_name}/domains/{domain}") $qp)
  let req_body = {"gitBranch": $git_branch, "redirect": $redirect, "redirectStatusCode": $redirect_status_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}

# Verify project domain
#
# POST /v9/projects/{idOrName}/domains/{domain}/verify
# operationId: verifyProjectDomain
export def "projects-domains-verify verify" [
  id_or_name: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> record<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: table<domain: string, reason: string, type: string, value: string>, verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_name | is-empty) { error make --unspanned { msg: "path parameter 'idOrName' must be non-empty" } }
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_or_name: (encode-path-segment $id_or_name), domain: (encode-path-segment $domain)} | format pattern "/v9/projects/{id_or_name}/domains/{domain}/verify") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Retrieve the environment variables of a project by id or name
#
# GET /v9/projects/{idOrName}/env
# operationId: filterProjectEnvs
export def "projects-env get-filter" [
  id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --git-branch: string # If defined, the git branch of the environment variable to filter the results
  --decrypt: string@decrypt-completer # If true, the environment variable value will be decrypted
  --qp-source: string # The source that is calling the endpoint.
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_name | is-empty) { error make --unspanned { msg: "path parameter 'idOrName' must be non-empty" } }
  let qp = [(serialize-qp "gitBranch" $git_branch "scalar") (serialize-qp "decrypt" $decrypt "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_or_name: (encode-path-segment $id_or_name)} | format pattern "/v9/projects/{id_or_name}/env") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"gitBranch": $git_branch, "decrypt": $decrypt, "source": $qp_source, "teamId": $team_id} | compact), body: null}
}

# Remove an environment variable
#
# DELETE /v9/projects/{idOrName}/env/{id}
# operationId: removeProjectEnv
export def "projects-env delete" [
  id_or_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_name | is-empty) { error make --unspanned { msg: "path parameter 'idOrName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_or_name: (encode-path-segment $id_or_name), id: (encode-path-segment $id)} | format pattern "/v9/projects/{id_or_name}/env/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"teamId": $team_id} | compact), body: null}
}

# Edit an environment variable
#
# PATCH /v9/projects/{idOrName}/env/{id}
# operationId: editProjectEnv
export def "projects-env update-edit" [
  id_or_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --git-branch: string # The git branch of the environment variable (nullable)
  --key: string # The name of the environment variable
  --target: list # The target environment of the environment variable
  --type: string@type-completer-1 # The type of environment variable
  --value: string # The value of the environment variable
]: any -> record<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_name | is-empty) { error make --unspanned { msg: "path parameter 'idOrName' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "teamId" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_or_name: (encode-path-segment $id_or_name), id: (encode-path-segment $id)} | format pattern "/v9/projects/{id_or_name}/env/{id}") $qp)
  let req_body = {"gitBranch": $git_branch, "key": $key, "target": $target, "type": $type, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"teamId": $team_id} | compact), body: $req_body}
}
