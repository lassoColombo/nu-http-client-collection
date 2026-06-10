# Auto-generated client for InfluxDB Cloud API Service v2.0.1
# Source: https://raw.githubusercontent.com/influxdata/openapi/master/contracts/cloud.yml
# Auth: --token flag or $env.INFLUXDB_CLOUD_API_SERVICE_TOKEN

const BASE_URL = "http://localhost/api/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o INFLUXDB_CLOUD_API_SERVICE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["http://localhost/api/v2" ""] }
def auth-scheme-completer [] { ["bearer" "basic"] }

# Completers for enum parameters
def Accept-completer [] { ["application/json" "application/octet-stream" "application/toml"] }
def accept-completer [] { ["application/json" "application/octet-stream" "application/toml"] }
def Content-Encoding-completer [] { ["gzip" "identity"] }
def Content-Type-completer [] { ["text/plain" "text/plain; charset=utf-8"] }
def Accept-completer-1 [] { ["application/json"] }
def include-completer [] { ["properties"] }
def Content-Type-completer-1 [] { ["application/json"] }
def type-completer [] { ["flux"] }
def Accept-Encoding-completer [] { ["gzip" "identity"] }
def Content-Type-completer-2 [] { ["application/json" "application/vnd.flux"] }
def schemaType-completer [] { ["explicit" "implicit"] }
def accept-completer-1 [] { ["application/json" "application/x-yaml"] }
def status-completer [] { ["active" "inactive"] }
def role-completer [] { ["member" "owner"] }
def sortBy-completer [] { ["CreatedAt" "ID" "UpdatedAt"] }
def sortBy-completer-1 [] { ["name"] }
def type-completer-1 [] { ["basic" "system"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "signin PostSignin" } } | get name | first)
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

# Create a user session.
#
# POST /signin
# operationId: PostSignin
export def "signin PostSignin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signin")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Expire a user session
#
# POST /signout
# operationId: PostSignout
export def "signout PostSignout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signout")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the status of the instance
#
# GET /ping
# operationId: GetPing
export def "ping GetPing" [
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
  let full_url = (build-url $base "/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the status of the instance
#
# HEAD /ping
# operationId: HeadPing
export def "ping HeadPing" [
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
  let full_url = (build-url $base "/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all top level routes
#
# GET /
# operationId: GetRoutes
export def "routes GetRoutes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<authorizations: string, buckets: string, dashboards: string, external: record<statusFeed: string>, variables: string, me: string, flags: string, orgs: string, query: record<self: string, ast: string, analyze: string, suggestions: string>, setup: string, signin: string, signout: string, sources: string, system: record<metrics: string, debug: string, health: string>, tasks: string, telegrafs: string, users: string, write: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List database retention policy mappings
#
# GET /dbrps
# operationId: GetDBRPs
export def "dbrps GetDBRPs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orgID: string # An organization ID. Only returns DBRP mappings for the specified organization.
  --org: string # An organization name. Only returns DBRP mappings for the specified organization.
  --id: string # A DBPR mapping ID. Only returns the specified DBRP mapping.
  --bucketID: string # A bucket ID. Only returns DBRP mappings that belong to the specified bucket.
  --default: string@bool-completer # Specifies filtering on default
  --db: string # A database. Only returns DBRP mappings that belong to the 1.x database.
  --rp: string # A [retention policy](https://docs.influxdata.com/influxdb/v1.8/concepts/glossary/#retention-policy-rp). Specifies the 1.x retention policy to filter on.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<content: table<id: string, orgID: string, bucketID: string, database: string, retention_policy: string, default: bool, virtual: bool, links: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $orgID "scalar") (serialize-qp "org" $org "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "bucketID" $bucketID "scalar") (serialize-qp "default" $default "scalar") (serialize-qp "db" $db "scalar") (serialize-qp "rp" $rp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dbrps" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a database retention policy mapping
#
# POST /dbrps
# operationId: PostDBRP
export def "dbrps PostDBRP" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --org: string # An organization name. Identifies the [organization](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#organization) that owns the mapping.
  --orgID: string # An organization ID. Identifies the [organization](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#organization) that owns the mapping.
  bucketID: string # A bucket ID. Identifies the bucket used as the target for the translation.
  database: string # A database name. Identifies the InfluxDB v1 database.
  retention_policy: string # A [retention policy](https://docs.influxdata.com/influxdb/v1.8/concepts/glossary/#retention-policy-rp) name. Identifies the InfluxDB v1 retention policy mapping.
  --default: string@bool-completer # Set to `true` to use this DBRP mapping as the default retention policy for the database (specified by the `database` property's value).
]: any -> record<id: string, orgID: string, bucketID: string, database: string, retention_policy: string, default: bool, virtual: bool, links: record<next: string, self: string, prev: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dbrps")
  let body = {org: $org, orgID: $orgID, bucketID: $bucketID, database: $database, retention_policy: $retention_policy, default: $default} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a database retention policy mapping
#
# GET /dbrps/{dbrpID}
# operationId: GetDBRPsID
export def "dbrps GetDBRPsID" [
  dbrpID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orgID: string # An organization ID. Specifies the organization that owns the DBRP mapping.
  --org: string # An organization name. Specifies the organization that owns the DBRP mapping.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<content: record<id: string, orgID: string, bucketID: string, database: string, retention_policy: string, default: bool, virtual: bool, links: record<next: string, self: string, prev: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $orgID "scalar") (serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dbrps/($dbrpID)" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a database retention policy mapping
#
# PATCH /dbrps/{dbrpID}
# operationId: PatchDBRPID
export def "dbrps PatchDBRPID" [
  dbrpID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orgID: string # An organization ID. Specifies the organization that owns the DBRP mapping.
  --org: string # An organization name. Specifies the organization that owns the DBRP mapping.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --retention-policy: string # A [retention policy](https://docs.influxdata.com/influxdb/v1.8/concepts/glossary/#retention-policy-rp) name. Identifies the InfluxDB v1 retention policy mapping.
  --default: string@bool-completer # Set to `true` to use this DBRP mapping as the default retention policy for the database (specified by the `database` property's value). To remove the default mapping, set to `false`.
]: any -> record<content: record<id: string, orgID: string, bucketID: string, database: string, retention_policy: string, default: bool, virtual: bool, links: record<next: string, self: string, prev: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $orgID "scalar") (serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dbrps/($dbrpID)" $qp)
  let body = {retention_policy: $retention_policy, default: $default} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a database retention policy
#
# DELETE /dbrps/{dbrpID}
# operationId: DeleteDBRPID
export def "dbrps DeleteDBRPID" [
  dbrpID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orgID: string # An organization ID. Specifies the organization that owns the DBRP mapping.
  --org: string # An organization name. Specifies the organization that owns the DBRP mapping.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $orgID "scalar") (serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dbrps/($dbrpID)" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all Telegraf plugins
#
# GET /telegraf/plugins
# operationId: GetTelegrafPlugins
export def "telegraf-plugins GetTelegrafPlugins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # The type of plugin desired.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<version: string, os: string, plugins: table<type: string, name: string, description: string, config: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/telegraf/plugins" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all Telegraf configurations
#
# GET /telegrafs
# operationId: GetTelegrafs
export def "telegrafs GetTelegrafs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orgID: string # The organization ID the Telegraf config belongs to.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<configurations: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/telegrafs" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Telegraf configuration
#
# POST /telegrafs
# operationId: PostTelegrafs
# --plugins item shape: {type?: string, name?: string, alias?: string, description?: string, config?: string}
# --metadata shape: {buckets?: list}
export def "telegrafs PostTelegrafs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --name: string
  --description: string
  --plugins: list # item shape: {type?: string, name?: string, alias?: string, description?: string, config?: string}
  --metadata: record # shape: {buckets?: list}
  --config: string
  --orgID: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/telegrafs")
  let body = {name: $name, description: $description, plugins: $plugins, metadata: $metadata, config: $config, orgID: $orgID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Telegraf configuration
#
# GET /telegrafs/{telegrafID}
# operationId: GetTelegrafsID
export def "telegrafs GetTelegrafsID" [
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --Accept: string@Accept-completer
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/toml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Telegraf configuration
#
# PUT /telegrafs/{telegrafID}
# operationId: PutTelegrafsID
# --plugins item shape: {type?: string, name?: string, alias?: string, description?: string, config?: string}
# --metadata shape: {buckets?: list}
export def "telegrafs PutTelegrafsID" [
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --name: string
  --description: string
  --plugins: list # item shape: {type?: string, name?: string, alias?: string, description?: string, config?: string}
  --metadata: record # shape: {buckets?: list}
  --config: string
  --orgID: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)")
  let body = {name: $name, description: $description, plugins: $plugins, metadata: $metadata, config: $config, orgID: $orgID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Telegraf configuration
#
# DELETE /telegrafs/{telegrafID}
# operationId: DeleteTelegrafsID
export def "telegrafs DeleteTelegrafsID" [
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all labels for a Telegraf config
#
# GET /telegrafs/{telegrafID}/labels
# operationId: GetTelegrafsIDLabels
export def "telegrafs-labels GetTelegrafsIDLabels" [
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<labels: table<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)/labels")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a label to a Telegraf config
#
# POST /telegrafs/{telegrafID}/labels
# operationId: PostTelegrafsIDLabels
export def "telegrafs-labels PostTelegrafsIDLabels" [
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  labelID: string # A label ID. Specifies the label to attach.
]: any -> record<label: record<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)/labels")
  let body = {labelID: $labelID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a label from a Telegraf config
#
# DELETE /telegrafs/{telegrafID}/labels/{labelID}
# operationId: DeleteTelegrafsIDLabelsID
export def "telegrafs-labels DeleteTelegrafsIDLabelsID" [
  telegrafID: string
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all users with member privileges for a Telegraf config
#
# GET /telegrafs/{telegrafID}/members
# operationId: GetTelegrafsIDMembers
export def "telegrafs-members GetTelegrafsIDMembers" [
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<self: string>, users: table<id: string, name: string, status: string, links: record, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)/members")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a member to a Telegraf config
#
# POST /telegrafs/{telegrafID}/members
# operationId: PostTelegrafsIDMembers
export def "telegrafs-members PostTelegrafsIDMembers" [
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  id: string # The ID of the user to add to the resource.
  --name: string # The name of the user to add to the resource.
]: any -> record<id: string, name: string, status: string, links: record<self: string>, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)/members")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a member from a Telegraf config
#
# DELETE /telegrafs/{telegrafID}/members/{userID}
# operationId: DeleteTelegrafsIDMembersID
export def "telegrafs-members DeleteTelegrafsIDMembersID" [
  userID: string
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)/members/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all owners of a Telegraf configuration
#
# GET /telegrafs/{telegrafID}/owners
# operationId: GetTelegrafsIDOwners
export def "telegrafs-owners GetTelegrafsIDOwners" [
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<self: string>, users: table<id: string, name: string, status: string, links: record, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)/owners")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an owner to a Telegraf configuration
#
# POST /telegrafs/{telegrafID}/owners
# operationId: PostTelegrafsIDOwners
export def "telegrafs-owners PostTelegrafsIDOwners" [
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  id: string # The ID of the user to add to the resource.
  --name: string # The name of the user to add to the resource.
]: any -> record<id: string, name: string, status: string, links: record<self: string>, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)/owners")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an owner from a Telegraf config
#
# DELETE /telegrafs/{telegrafID}/owners/{userID}
# operationId: DeleteTelegrafsIDOwnersID
export def "telegrafs-owners DeleteTelegrafsIDOwnersID" [
  userID: string
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)/owners/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all labels for a variable
#
# GET /variables/{variableID}/labels
# operationId: GetVariablesIDLabels
export def "variables-labels GetVariablesIDLabels" [
  variableID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<labels: table<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/variables/($variableID)/labels")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a label to a variable
#
# POST /variables/{variableID}/labels
# operationId: PostVariablesIDLabels
export def "variables-labels PostVariablesIDLabels" [
  variableID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  labelID: string # A label ID. Specifies the label to attach.
]: any -> record<label: record<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/variables/($variableID)/labels")
  let body = {labelID: $labelID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a label from a variable
#
# DELETE /variables/{variableID}/labels/{labelID}
# operationId: DeleteVariablesIDLabelsID
export def "variables-labels DeleteVariablesIDLabelsID" [
  variableID: string
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/variables/($variableID)/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Write data
#
# POST /write
# operationId: PostWrite
export def "write PostWrite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --org: string # An organization name or ID.  #### InfluxDB Cloud  - Doesn't use the `org` parameter or `orgID` parameter. - Writes data to the bucket in the organization   associated with the authorization (API token).  #### InfluxDB OSS  - Requires either the `org` parameter or the `orgID` parameter. - If you pass both `orgID` and `org`, they must both be valid. - Writes data to the bucket in the specified organization.
  --orgID: string # An organization ID.  #### InfluxDB Cloud  - Doesn't use the `org` parameter or `orgID` parameter. - Writes data to the bucket in the organization   associated with the authorization (API token).  #### InfluxDB OSS  - Requires either the `org` parameter or the `orgID` parameter. - If you pass both `orgID` and `org`, they must both be valid. - Writes data to the bucket in the specified organization.
  --bucket: string # A bucket name or ID. InfluxDB writes all points in the batch to the specified bucket.
  --precision: string # The precision for unix timestamps in the line protocol batch.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --Content-Encoding: string@Content-Encoding-completer # The compression applied to the line protocol in the request payload. To send a GZIP payload, pass `Content-Encoding: gzip` header.
  --Content-Type: string@Content-Type-completer # The format of the data in the request body. To send a line protocol payload, pass `Content-Type: text/plain; charset=utf-8`.
  --Content-Length: int # The size of the entity-body, in bytes, sent to InfluxDB. If the length is greater than the `max body` configuration option, the server responds with status code `413`.
  --Accept: string@Accept-completer-1 # The content type that the client can understand. Writes only return a response body if they fail--for example, due to a formatting problem or quota limit.  #### InfluxDB Cloud    - Returns only `application/json` for format and limit errors.   - Returns only `text/html` for some quota limit errors.  #### InfluxDB OSS    - Returns only `application/json` for format and limit errors.  #### Related guides  - [Troubleshoot issues writing data](https://docs.influxdata.com/influxdb/cloud/write-data/troubleshoot/)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "orgID" $orgID "scalar") (serialize-qp "bucket" $bucket "scalar") (serialize-qp "precision" $precision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/write" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span, "Content-Encoding": $Content_Encoding, "Content-Type": $Content_Type, "Content-Length": $Content_Length, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "text/plain" $body
}

# Delete data
#
# POST /delete
# operationId: PostDelete
export def "delete PostDelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --org: string # An organization name or ID.  #### InfluxDB Cloud  - Doesn't use the `org` parameter or `orgID` parameter. - Deletes data from the bucket in the organization   associated with the authorization (API token).  #### InfluxDB OSS  - Requires either the `org` parameter or the `orgID` parameter. - Deletes data from the bucket in the specified organization. - If you pass both `orgID` and `org`, they must both be valid.
  --bucket: string # A bucket name or ID. Specifies the bucket to delete data from. If you pass both `bucket` and `bucketID`, `bucketID` takes precedence.
  --orgID: string # An organization ID.  #### InfluxDB Cloud  - Doesn't use the `org` parameter or `orgID` parameter. - Deletes data from the bucket in the organization   associated with the authorization (API token).  #### InfluxDB OSS  - Requires either the `org` parameter or the `orgID` parameter. - Deletes data from the bucket in the specified organization. - If you pass both `orgID` and `org`, they must both be valid.
  --bucketID: string # A bucket ID. Specifies the bucket to delete data from. If you pass both `bucket` and `bucketID`, `bucketID` takes precedence.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  start: string # A timestamp ([RFC3339 date/time format](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#rfc3339-timestamp)). The earliest time to delete from.  (format: date-time)
  stop: string # A timestamp ([RFC3339 date/time format](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#rfc3339-timestamp)). The latest time to delete from.  (format: date-time)
  --predicate: string # An expression in [delete predicate syntax](https://docs.influxdata.com/influxdb/cloud/reference/syntax/delete-predicate/).  (e.g. tag1="value1" and (tag2="value2" and tag3!="value3"))
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "bucket" $bucket "scalar") (serialize-qp "orgID" $orgID "scalar") (serialize-qp "bucketID" $bucketID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/delete" $qp)
  let body = {start: $start, stop: $stop, predicate: $predicate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a label
#
# POST /labels
# operationId: PostLabels
export def "labels PostLabels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  orgID: string
  name: string
  --properties: record # Key-value pairs associated with this label.  To remove a property, send an update with an empty value (`""`) for the key.  (e.g. {color: ffb3b3, description: this is a description})
]: any -> record<label: record<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/labels")
  let body = {orgID: $orgID, name: $name, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all labels
#
# GET /labels
# operationId: GetLabels
export def "labels GetLabels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orgID: string # The organization ID.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<labels: table<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/labels" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a label
#
# GET /labels/{labelID}
# operationId: GetLabelsID
export def "labels GetLabelsID" [
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<label: record<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a label
#
# PATCH /labels/{labelID}
# operationId: PatchLabelsID
export def "labels PatchLabelsID" [
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --name: string
  --properties: record # e.g. {color: ffb3b3, description: this is a description}
]: any -> record<label: record<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/labels/($labelID)")
  let body = {name: $name, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a label
#
# DELETE /labels/{labelID}
# operationId: DeleteLabelsID
export def "labels DeleteLabelsID" [
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a dashboard
#
# GET /dashboards/{dashboardID}
# operationId: GetDashboardsID
export def "dashboards GetDashboardsID" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer # If `properties`, includes the cell view properties in the response.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dashboards/($dashboardID)" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a dashboard
#
# PATCH /dashboards/{dashboardID}
# operationId: PatchDashboardsID
# --cells shape: {id?: string, links?: record, x?: int, y?: int, w?: int, h?: int, viewID?: string, name?: string, properties?: any}
export def "dashboards PatchDashboardsID" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --name: string # optional, when provided will replace the name
  --description: string # optional, when provided will replace the description
  --cells: record # shape: {id?: string, links?: record, x?: int, y?: int, w?: int, h?: int, viewID?: string, name?: string, properties?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)")
  let body = {name: $name, description: $description, cells: $cells} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a dashboard
#
# DELETE /dashboards/{dashboardID}
# operationId: DeleteDashboardsID
export def "dashboards DeleteDashboardsID" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace cells in a dashboard
#
# PUT /dashboards/{dashboardID}/cells
# operationId: PutDashboardsIDCells
export def "dashboards-cells PutDashboardsIDCells" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/cells")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a dashboard cell
#
# POST /dashboards/{dashboardID}/cells
# operationId: PostDashboardsIDCells
export def "dashboards-cells PostDashboardsIDCells" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --name: string
  --x: int # format: int32
  --y: int # format: int32
  --w: int # format: int32
  --h: int # format: int32
  --usingView: string # Makes a copy of the provided view.
]: any -> record<id: string, links: record<self: string, view: string>, x: int, y: int, w: int, h: int, viewID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/cells")
  let body = {name: $name, x: $x, y: $y, w: $w, h: $h, usingView: $usingView} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the non-positional information related to a cell
#
# PATCH /dashboards/{dashboardID}/cells/{cellID}
# operationId: PatchDashboardsIDCellsID
export def "dashboards-cells PatchDashboardsIDCellsID" [
  dashboardID: string
  cellID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --x: int # format: int32
  --y: int # format: int32
  --w: int # format: int32
  --h: int # format: int32
]: any -> record<id: string, links: record<self: string, view: string>, x: int, y: int, w: int, h: int, viewID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/cells/($cellID)")
  let body = {x: $x, y: $y, w: $w, h: $h} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a dashboard cell
#
# DELETE /dashboards/{dashboardID}/cells/{cellID}
# operationId: DeleteDashboardsIDCellsID
export def "dashboards-cells DeleteDashboardsIDCellsID" [
  dashboardID: string
  cellID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/cells/($cellID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the view for a cell
#
# GET /dashboards/{dashboardID}/cells/{cellID}/view
# operationId: GetDashboardsIDCellsIDView
export def "dashboards-cells-view GetDashboardsIDCellsIDView" [
  dashboardID: string
  cellID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<self: string>, id: string, name: string, properties: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/cells/($cellID)/view")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the view for a cell
#
# PATCH /dashboards/{dashboardID}/cells/{cellID}/view
# operationId: PatchDashboardsIDCellsIDView
# --links shape: {self?: string}
export def "dashboards-cells-view PatchDashboardsIDCellsIDView" [
  dashboardID: string
  cellID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  name: string
  properties: any
]: any -> record<links: record<self: string>, id: string, name: string, properties: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/cells/($cellID)/view")
  let body = {name: $name, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all labels for a dashboard
#
# GET /dashboards/{dashboardID}/labels
# operationId: GetDashboardsIDLabels
export def "dashboards-labels GetDashboardsIDLabels" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<labels: table<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/labels")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a label to a dashboard
#
# POST /dashboards/{dashboardID}/labels
# operationId: PostDashboardsIDLabels
export def "dashboards-labels PostDashboardsIDLabels" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  labelID: string # A label ID. Specifies the label to attach.
]: any -> record<label: record<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/labels")
  let body = {labelID: $labelID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a label from a dashboard
#
# DELETE /dashboards/{dashboardID}/labels/{labelID}
# operationId: DeleteDashboardsIDLabelsID
export def "dashboards-labels DeleteDashboardsIDLabelsID" [
  dashboardID: string
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all dashboard members
#
# GET /dashboards/{dashboardID}/members
# operationId: GetDashboardsIDMembers
export def "dashboards-members GetDashboardsIDMembers" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<self: string>, users: table<id: string, name: string, status: string, links: record, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/members")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a member to a dashboard
#
# POST /dashboards/{dashboardID}/members
# operationId: PostDashboardsIDMembers
export def "dashboards-members PostDashboardsIDMembers" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  id: string # The ID of the user to add to the resource.
  --name: string # The name of the user to add to the resource.
]: any -> record<id: string, name: string, status: string, links: record<self: string>, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/members")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a member from a dashboard
#
# DELETE /dashboards/{dashboardID}/members/{userID}
# operationId: DeleteDashboardsIDMembersID
export def "dashboards-members DeleteDashboardsIDMembersID" [
  userID: string
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/members/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all dashboard owners
#
# GET /dashboards/{dashboardID}/owners
# operationId: GetDashboardsIDOwners
export def "dashboards-owners GetDashboardsIDOwners" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<self: string>, users: table<id: string, name: string, status: string, links: record, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/owners")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an owner to a dashboard
#
# POST /dashboards/{dashboardID}/owners
# operationId: PostDashboardsIDOwners
export def "dashboards-owners PostDashboardsIDOwners" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  id: string # The ID of the user to add to the resource.
  --name: string # The name of the user to add to the resource.
]: any -> record<id: string, name: string, status: string, links: record<self: string>, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/owners")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an owner from a dashboard
#
# DELETE /dashboards/{dashboardID}/owners/{userID}
# operationId: DeleteDashboardsIDOwnersID
export def "dashboards-owners DeleteDashboardsIDOwnersID" [
  userID: string
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/owners/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a query Abstract Syntax Tree (AST)
#
# POST /query/ast
# operationId: PostQueryAst
export def "query-ast PostQueryAst" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --Content-Type: string@Content-Type-completer-1
  --body-query: string # The Flux query script to be analyzed.
]: any -> record<ast: record<type: string, path: string, package: string, files: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/query/ast")
  let body = {query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Flux query suggestions
#
# GET /query/suggestions
# operationId: GetQuerySuggestions
export def "query-suggestions GetQuerySuggestions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<funcs: table<name: string, params: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/query/suggestions")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a query suggestion for a branching suggestion
#
# GET /query/suggestions/{name}
# operationId: GetQuerySuggestionsName
export def "query-suggestions GetQuerySuggestionsName" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<name: string, params: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/query/suggestions/($name)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Analyze a Flux query
#
# POST /query/analyze
# operationId: PostQueryAnalyze
# --extern shape: {type?: string, name?: string, package?: record, imports?: list, body?: list}
# --dialect shape: {header?: bool, delimiter?: string, annotations?: list, commentPrefix?: string, dateTimeFormat?: "RFC3339"|"RFC3339Nano"}
export def "query-analyze PostQueryAnalyze" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --Content-Type: string@Content-Type-completer-1
  --extern: record # Represents a source from a single file — shape: {type?: string, name?: string, package?: record, imports?: list, body?: list}
  --body-query: string # The query script to execute.
  --type: string@type-completer # The type of query. Must be "flux".
  --params: record # Key-value pairs passed as parameters during query execution.  To use parameters in your query, pass a _`query`_ with `params` references (in dot notation)--for example:  ```json   query: "from(bucket: params.mybucket)\               |> range(start: params.rangeStart) |> limit(n:1)" ```  and pass _`params`_ with the key-value pairs--for example:  ```json   params: {     "mybucket": "environment",     "rangeStart": "-30d"   } ```  During query execution, InfluxDB passes _`params`_ to your script and substitutes the values.  #### Limitations  - If you use _`params`_, you can't use _`extern`_.
  --dialect: record # Options for tabular data output. Default output is [annotated CSV](https://docs.influxdata.com/influxdb/cloud/reference/syntax/annotated-csv/#csv-response-format) with headers.  For more information about tabular data **dialect**, see [W3 metadata vocabulary for tabular data](https://www.w3.org/TR/2015/REC-tabular-metadata-20151217/#dialect-descriptions). — shape: {header?: bool, delimiter?: string, annotations?: list, commentPrefix?: string, dateTimeFormat?: "RFC3339"|"RFC3339Nano"}
  --now: string # Specifies the time that should be reported as `now` in the query. Default is the server `now` time.  (format: date-time)
]: any -> record<errors: table<line: int, column: int, character: int, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/query/analyze")
  let body = {extern: $extern, query: $body_query, type: $type, params: $params, dialect: $dialect, now: $now} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Query data
#
# POST /query
# operationId: PostQuery
# --extern shape: {type?: string, name?: string, package?: record, imports?: list, body?: list}
# --dialect shape: {header?: bool, delimiter?: string, annotations?: list, commentPrefix?: string, dateTimeFormat?: "RFC3339"|"RFC3339Nano"}
export def "query PostQuery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --org: string # An organization name or ID.  #### InfluxDB Cloud  - Doesn't use the `org` parameter or `orgID` parameter. - Queries the bucket in the organization associated with the authorization (API token).  #### InfluxDB OSS  - Requires either the `org` parameter or `orgID` parameter. - Queries the bucket in the specified organization.
  --orgID: string # An organization ID.  #### InfluxDB Cloud  - Doesn't use the `org` parameter or `orgID` parameter. - Queries the bucket in the organization associated with the authorization (API token).  #### InfluxDB OSS  - Requires either the `org` parameter or `orgID` parameter. - Queries the bucket in the specified organization.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --Accept-Encoding: string@Accept-Encoding-completer # The content encoding (usually a compression algorithm) that the client can understand.
  --Content-Type: string@Content-Type-completer-2
  --extern: record # Represents a source from a single file — shape: {type?: string, name?: string, package?: record, imports?: list, body?: list}
  --body-query: string # The query script to execute.
  --type: string@type-completer # The type of query. Must be "flux".
  --params: record # Key-value pairs passed as parameters during query execution.  To use parameters in your query, pass a _`query`_ with `params` references (in dot notation)--for example:  ```json   query: "from(bucket: params.mybucket)\               |> range(start: params.rangeStart) |> limit(n:1)" ```  and pass _`params`_ with the key-value pairs--for example:  ```json   params: {     "mybucket": "environment",     "rangeStart": "-30d"   } ```  During query execution, InfluxDB passes _`params`_ to your script and substitutes the values.  #### Limitations  - If you use _`params`_, you can't use _`extern`_.
  --dialect: record # Options for tabular data output. Default output is [annotated CSV](https://docs.influxdata.com/influxdb/cloud/reference/syntax/annotated-csv/#csv-response-format) with headers.  For more information about tabular data **dialect**, see [W3 metadata vocabulary for tabular data](https://www.w3.org/TR/2015/REC-tabular-metadata-20151217/#dialect-descriptions). — shape: {header?: bool, delimiter?: string, annotations?: list, commentPrefix?: string, dateTimeFormat?: "RFC3339"|"RFC3339Nano"}
  --now: string # Specifies the time that should be reported as `now` in the query. Default is the server `now` time.  (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/query" $qp)
  let body = {extern: $extern, query: $body_query, type: $type, params: $params, dialect: $dialect, now: $now} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span, "Accept-Encoding": $Accept_Encoding, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List buckets
#
# GET /buckets
# operationId: GetBuckets
export def "buckets GetBuckets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # The offset for pagination. The number of records to skip.  For more information about pagination parameters, see [Pagination](https://docs.influxdata.com/influxdb/cloud/api/#tag/Pagination).
  --limit: int # Limits the number of records returned. Default is `20`.  (default: 20)
  --after: string # A resource ID to seek from. Returns records created after the specified record; results don't include the specified record.  Use `after` instead of the `offset` parameter. For more information about pagination parameters, see [Pagination](https://docs.influxdata.com/influxdb/cloud/api/#tag/Pagination).
  --org: string # An organization name.  #### InfluxDB Cloud  - Doesn't use the `org` parameter or `orgID` parameter. - Lists buckets for the organization associated with the authorization (API token).  #### InfluxDB OSS  - Lists buckets for the specified organization.
  --orgID: string # An organization ID.  #### InfluxDB Cloud  - Doesn't use the `org` parameter or `orgID` parameter. - Lists buckets for the organization associated with the authorization (API token).  #### InfluxDB OSS  - Requires either the `org` parameter or `orgID` parameter. - Lists buckets for the specified organization.
  --name: string # A bucket name. Only returns buckets with the specified name.
  --id: string # A bucket ID. Only returns the bucket with the specified ID.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<next: string, self: string, prev: string>, buckets: table<links: record, id: string, type: string, name: string, description: string, orgID: string, rp: string, schemaType: string, createdAt: string, updatedAt: string, retentionRules: list, labels: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "org" $org "scalar") (serialize-qp "orgID" $orgID "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/buckets" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a bucket
#
# POST /buckets
# operationId: PostBuckets
# --retentionRules item shape: {type?: "expire", everySeconds: int, shardGroupDurationSeconds?: int}
export def "buckets PostBuckets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  orgID: string # The organization ID. Specifies the organization that owns the bucket.
  name: string # The bucket name.
  --description: string # A description of the bucket.
  --rp: string # The retention policy for the bucket. For InfluxDB 1.x, specifies the duration of time that each data point in the retention policy persists.  If you need compatibility with InfluxDB 1.x, specify a value for the `rp` property; otherwise, see the `retentionRules` property.  [Retention policy](https://docs.influxdata.com/influxdb/v1.8/concepts/glossary/#retention-policy-rp) is an InfluxDB 1.x concept. The InfluxDB 2.x and Cloud equivalent is [retention period](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#retention-period). The InfluxDB `/api/v2` API uses `RetentionRules` to configure the retention period.  (default: 0)
  --retentionRules: list # Retention rules to expire or retain data. The InfluxDB `/api/v2` API uses `RetentionRules` to configure the [retention period](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#retention-period).  #### InfluxDB Cloud  - `retentionRules` is required.  #### InfluxDB OSS  - `retentionRules` isn't required. — item shape: {type?: "expire", everySeconds: int, shardGroupDurationSeconds?: int}
  --schemaType: string@schemaType-completer
]: any -> record<links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, id: string, type: string, name: string, description: string, orgID: string, rp: string, schemaType: string, createdAt: string, updatedAt: string, retentionRules: table<type: string, everySeconds: int, shardGroupDurationSeconds: int>, labels: table<id: string, orgID: string, name: string, properties: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/buckets")
  let body = {orgID: $orgID, name: $name, description: $description, rp: $rp, retentionRules: $retentionRules, schemaType: $schemaType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a bucket
#
# GET /buckets/{bucketID}
# operationId: GetBucketsID
export def "buckets GetBucketsID" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, id: string, type: string, name: string, description: string, orgID: string, rp: string, schemaType: string, createdAt: string, updatedAt: string, retentionRules: table<type: string, everySeconds: int, shardGroupDurationSeconds: int>, labels: table<id: string, orgID: string, name: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a bucket
#
# PATCH /buckets/{bucketID}
# operationId: PatchBucketsID
# --retentionRules item shape: {type?: "expire", everySeconds: int, shardGroupDurationSeconds?: int}
export def "buckets PatchBucketsID" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --name: string # The name of the bucket.
  --description: string # A description of the bucket.
  --retentionRules: list # Updates to rules to expire or retain data. No rules means no updates. — item shape: {type?: "expire", everySeconds: int, shardGroupDurationSeconds?: int}
]: any -> record<links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, id: string, type: string, name: string, description: string, orgID: string, rp: string, schemaType: string, createdAt: string, updatedAt: string, retentionRules: table<type: string, everySeconds: int, shardGroupDurationSeconds: int>, labels: table<id: string, orgID: string, name: string, properties: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)")
  let body = {name: $name, description: $description, retentionRules: $retentionRules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a bucket
#
# DELETE /buckets/{bucketID}
# operationId: DeleteBucketsID
export def "buckets DeleteBucketsID" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all labels for a bucket
#
# GET /buckets/{bucketID}/labels
# operationId: GetBucketsIDLabels
export def "buckets-labels GetBucketsIDLabels" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<labels: table<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)/labels")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a label to a bucket
#
# POST /buckets/{bucketID}/labels
# operationId: PostBucketsIDLabels
export def "buckets-labels PostBucketsIDLabels" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  labelID: string # A label ID. Specifies the label to attach.
]: any -> record<label: record<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)/labels")
  let body = {labelID: $labelID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a label from a bucket
#
# DELETE /buckets/{bucketID}/labels/{labelID}
# operationId: DeleteBucketsIDLabelsID
export def "buckets-labels DeleteBucketsIDLabelsID" [
  bucketID: string
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all users with member privileges for a bucket
#
# GET /buckets/{bucketID}/members
# operationId: GetBucketsIDMembers
export def "buckets-members GetBucketsIDMembers" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<self: string>, users: table<id: string, name: string, status: string, links: record, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)/members")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a member to a bucket
#
# POST /buckets/{bucketID}/members
# operationId: PostBucketsIDMembers
export def "buckets-members PostBucketsIDMembers" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  id: string # The ID of the user to add to the resource.
  --name: string # The name of the user to add to the resource.
]: any -> record<id: string, name: string, status: string, links: record<self: string>, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)/members")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a member from a bucket
#
# DELETE /buckets/{bucketID}/members/{userID}
# operationId: DeleteBucketsIDMembersID
export def "buckets-members DeleteBucketsIDMembersID" [
  userID: string
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)/members/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all owners of a bucket
#
# GET /buckets/{bucketID}/owners
# operationId: GetBucketsIDOwners
export def "buckets-owners GetBucketsIDOwners" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<self: string>, users: table<id: string, name: string, status: string, links: record, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)/owners")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an owner to a bucket
#
# POST /buckets/{bucketID}/owners
# operationId: PostBucketsIDOwners
export def "buckets-owners PostBucketsIDOwners" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  id: string # The ID of the user to add to the resource.
  --name: string # The name of the user to add to the resource.
]: any -> record<id: string, name: string, status: string, links: record<self: string>, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)/owners")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an owner from a bucket
#
# DELETE /buckets/{bucketID}/owners/{userID}
# operationId: DeleteBucketsIDOwnersID
export def "buckets-owners DeleteBucketsIDOwnersID" [
  userID: string
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)/owners/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organizations
#
# GET /orgs
# operationId: GetOrgs
export def "orgs GetOrgs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # The offset for pagination. The number of records to skip.  For more information about pagination parameters, see [Pagination](https://docs.influxdata.com/influxdb/cloud/api/#tag/Pagination).
  --limit: int # Limits the number of records returned. Default is `20`.  (default: 20)
  --descending: string@bool-completer # default: false
  --org: string # An organization name. Only returns the specified organization.
  --orgID: string # An organization ID. Only returns the specified organization.
  --userID: string # A user ID. Only returns organizations where the specified user is a member or owner.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<next: string, self: string, prev: string>, orgs: table<links: record, id: string, name: string, defaultStorageType: string, description: string, createdAt: string, updatedAt: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "descending" $descending "scalar") (serialize-qp "org" $org "scalar") (serialize-qp "orgID" $orgID "scalar") (serialize-qp "userID" $userID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orgs" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an organization
#
# POST /orgs
# operationId: PostOrgs
export def "orgs PostOrgs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  name: string # The name of the organization.
  --description: string # The description of the organization.
]: any -> record<links: record<self: string, members: string, owners: string, labels: string, secrets: string, buckets: string, tasks: string, dashboards: string>, id: string, name: string, defaultStorageType: string, description: string, createdAt: string, updatedAt: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orgs")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an organization
#
# GET /orgs/{orgID}
# operationId: GetOrgsID
export def "orgs GetOrgsID" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<self: string, members: string, owners: string, labels: string, secrets: string, buckets: string, tasks: string, dashboards: string>, id: string, name: string, defaultStorageType: string, description: string, createdAt: string, updatedAt: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an organization
#
# PATCH /orgs/{orgID}
# operationId: PatchOrgsID
export def "orgs PatchOrgsID" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --name: string # The name of the organization.
  --description: string # The description of the organization.
]: any -> record<links: record<self: string, members: string, owners: string, labels: string, secrets: string, buckets: string, tasks: string, dashboards: string>, id: string, name: string, defaultStorageType: string, description: string, createdAt: string, updatedAt: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an organization
#
# DELETE /orgs/{orgID}
# operationId: DeleteOrgsID
export def "orgs DeleteOrgsID" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all secret keys for an organization
#
# GET /orgs/{orgID}/secrets
# operationId: GetOrgsIDSecrets
export def "orgs-secrets GetOrgsIDSecrets" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<secrets: list<string>, links: record<self: string, org: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/secrets")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update secrets in an organization
#
# PATCH /orgs/{orgID}/secrets
# operationId: PatchOrgsIDSecrets
export def "orgs-secrets PatchOrgsIDSecrets" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --body: record
]: any -> record<code: string, message: string, op: string, err: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/secrets")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all members of an organization
#
# GET /orgs/{orgID}/members
# operationId: GetOrgsIDMembers
export def "orgs-members GetOrgsIDMembers" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<self: string>, users: table<id: string, name: string, status: string, links: record, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/members")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a member to an organization
#
# POST /orgs/{orgID}/members
# operationId: PostOrgsIDMembers
export def "orgs-members PostOrgsIDMembers" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  id: string # The ID of the user to add to the resource.
  --name: string # The name of the user to add to the resource.
]: any -> record<id: string, name: string, status: string, links: record<self: string>, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/members")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a member from an organization
#
# DELETE /orgs/{orgID}/members/{userID}
# operationId: DeleteOrgsIDMembersID
export def "orgs-members DeleteOrgsIDMembersID" [
  userID: string
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/members/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all owners of an organization
#
# GET /orgs/{orgID}/owners
# operationId: GetOrgsIDOwners
export def "orgs-owners GetOrgsIDOwners" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<self: string>, users: table<id: string, name: string, status: string, links: record, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/owners")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an owner to an organization
#
# POST /orgs/{orgID}/owners
# operationId: PostOrgsIDOwners
export def "orgs-owners PostOrgsIDOwners" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  id: string # The ID of the user to add to the resource.
  --name: string # The name of the user to add to the resource.
]: any -> record<id: string, name: string, status: string, links: record<self: string>, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/owners")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an owner from an organization
#
# DELETE /orgs/{orgID}/owners/{userID}
# operationId: DeleteOrgsIDOwnersID
export def "orgs-owners DeleteOrgsIDOwnersID" [
  userID: string
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/owners/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete secrets from an organization
#
# POST /orgs/{orgID}/secrets/delete
# DEPRECATED
# operationId: PostOrgsIDSecrets
@deprecated
export def "orgs-secrets-delete PostOrgsIDSecrets" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --secrets: list
]: any -> record<code: string, message: string, op: string, err: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/secrets/delete")
  let body = {secrets: $secrets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a secret from an organization
#
# DELETE /orgs/{orgID}/secrets/{secretID}
# operationId: DeleteOrgsIDSecretsID
export def "orgs-secrets DeleteOrgsIDSecretsID" [
  orgID: string
  secretID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/secrets/($secretID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all known resources
#
# GET /resources
# operationId: GetResources
export def "resources GetResources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/resources")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List installed stacks
#
# GET /stacks
# operationId: ListStacks
export def "stacks ListStacks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orgID: string # An organization ID. Only returns stacks owned by the specified [organization](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#organization).  #### InfluxDB Cloud  - Doesn't require this parameter;   InfluxDB only returns resources allowed by the API token.
  --name: string # A stack name. Finds stack `events` with this name and returns the stacks.  Repeatable. To filter for more than one stack name, repeat this parameter with each name--for example:  - `INFLUX_URL/api/v2/stacks?&orgID=INFLUX_ORG_ID&name=project-stack-0&name=project-stack-1`
  --stackID: string # A stack ID. Only returns the specified stack.  Repeatable. To filter for more than one stack ID, repeat this parameter with each ID--for example:  - `INFLUX_URL/api/v2/stacks?&orgID=INFLUX_ORG_ID&stackID=09bd87cd33be3000&stackID=09bef35081fe3000`
]: nothing -> record<stacks: table<id: string, orgID: string, createdAt: string, events: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $orgID "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "stackID" $stackID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stacks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a stack
#
# POST /stacks
# operationId: CreateStack
export def "stacks CreateStack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orgID: string
  --name: string
  --description: string
  --urls: list
]: any -> record<id: string, orgID: string, createdAt: string, events: table<eventType: string, name: string, description: string, sources: list, resources: list, urls: list, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stacks")
  let body = {orgID: $orgID, name: $name, description: $description, urls: $urls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a stack
#
# GET /stacks/{stack_id}
# operationId: ReadStack
export def "stacks ReadStack" [
  stack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, orgID: string, createdAt: string, events: table<eventType: string, name: string, description: string, sources: list, resources: list, urls: list, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stacks/($stack_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a stack
#
# PATCH /stacks/{stack_id}
# operationId: UpdateStack
# --additionalResources item shape: {resourceID: string, kind: string, templateMetaName?: string}
export def "stacks UpdateStack" [
  stack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # nullable
  --description: string # nullable
  --templateURLs: list # nullable
  --additionalResources: list # item shape: {resourceID: string, kind: string, templateMetaName?: string}
]: any -> record<id: string, orgID: string, createdAt: string, events: table<eventType: string, name: string, description: string, sources: list, resources: list, urls: list, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stacks/($stack_id)")
  let body = {name: $name, description: $description, templateURLs: $templateURLs, additionalResources: $additionalResources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a stack and associated resources
#
# DELETE /stacks/{stack_id}
# operationId: DeleteStack
export def "stacks DeleteStack" [
  stack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orgID: string # The identifier of the organization.
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stacks/($stack_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Uninstall a stack
#
# POST /stacks/{stack_id}/uninstall
# operationId: UninstallStack
export def "stacks-uninstall UninstallStack" [
  stack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, orgID: string, createdAt: string, events: table<eventType: string, name: string, description: string, sources: list, resources: list, urls: list, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stacks/($stack_id)/uninstall")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply or dry-run a template
#
# POST /templates/apply
# operationId: ApplyTemplate
# --template shape: {contentType?: string, sources?: list, contents?: list}
# --templates item shape: {contentType?: string, sources?: list, contents?: list}
# --remotes item shape: {url: string, contentType?: string}
export def "templates-apply ApplyTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dryRun: string@bool-completer # Only applies a dry run of the templates passed in the request.  - Validates the template and generates a resource diff and summary. - Doesn't install templates or make changes to the InfluxDB instance.
  --orgID: string # Organization ID. InfluxDB applies templates to this organization. The organization owns all resources created by the template.  To find your organization, see how to [view organizations](https://docs.influxdata.com/influxdb/cloud/organizations/view-orgs/).
  --stackID: string # ID of the stack to update.  To apply templates to an existing stack in the organization, use the `stackID` parameter. If you apply templates without providing a stack ID, InfluxDB initializes a new stack with all new resources.  To find a stack ID, use the InfluxDB [`/api/v2/stacks` API endpoint](#operation/ListStacks) to list stacks.  #### Related guides  - [Stacks](https://docs.influxdata.com/influxdb/cloud/influxdb-templates/stacks/) - [View stacks](https://docs.influxdata.com/influxdb/cloud/influxdb-templates/stacks/view/)
  --template: record # A template object to apply. A template object has a `contents` property with an array of InfluxDB resource configurations.  Pass `template` to apply only one template object. If you use `template`, you can't use the `templates` parameter. If you want to apply multiple template objects, use `templates` instead. — shape: {contentType?: string, sources?: list, contents?: list}
  --templates: list # A list of template objects to apply. A template object has a `contents` property with an array of InfluxDB resource configurations.  Use the `templates` parameter to apply multiple template objects. If you use `templates`, you can't use the `template` parameter. — item shape: {contentType?: string, sources?: list, contents?: list}
  --envRefs: record # An object with key-value pairs that map to **environment references** in templates.  Environment references in templates are `envRef` objects with an `envRef.key` property. To substitute a custom environment reference value when applying templates, pass `envRefs` with the `envRef.key` and the value.  When you apply a template, InfluxDB replaces `envRef` objects in the template with the values that you provide in the `envRefs` parameter. For more examples, see how to [define environment references](https://docs.influxdata.com/influxdb/cloud/influxdb-templates/use/#define-environment-references).  The following template fields may use environment references:    - `metadata.name`   - `spec.endpointName`   - `spec.associations.name`  For more information about including environment references in template fields, see how to [include user-definable resource names](https://docs.influxdata.com/influxdb/cloud/influxdb-templates/create/#include-user-definable-resource-names).
  --secrets: record # An object with key-value pairs that map to **secrets** in queries.  Queries may reference secrets stored in InfluxDB--for example, the following Flux script retrieves `POSTGRES_USERNAME` and `POSTGRES_PASSWORD` secrets and then uses them to connect to a PostgreSQL database:  ```js import "sql" import "influxdata/influxdb/secrets"  username = secrets.get(key: "POSTGRES_USERNAME") password = secrets.get(key: "POSTGRES_PASSWORD")  sql.from(   driverName: "postgres",   dataSourceName: "postgresql://${username}:${password}@localhost:5432",   query: "SELECT * FROM example_table", ) ```  To define secret values in your `/api/v2/templates/apply` request, pass the `secrets` parameter with key-value pairs--for example:  ```json {   ...   "secrets": {     "POSTGRES_USERNAME": "pguser",     "POSTGRES_PASSWORD": "foo"   }   ... } ```  InfluxDB stores the key-value pairs as secrets that you can access with `secrets.get()`. Once stored, you can't view secret values in InfluxDB.  #### Related guides  - [How to pass secrets when installing a template](https://docs.influxdata.com/influxdb/cloud/influxdb-templates/use/#pass-secrets-when-installing-a-template)
  --remotes: list # A list of URLs for template files.  To apply a template manifest file located at a URL, pass `remotes` with an array that contains the URL. — item shape: {url: string, contentType?: string}
  --actions: list # A list of `action` objects. Actions let you customize how InfluxDB applies templates in the request.  You can use the following actions to prevent creating or updating resources:  - A `skipKind` action skips template resources of a specified `kind`. - A `skipResource` action skips template resources with a specified `metadata.name`   and `kind`.
]: any -> record<sources: list<string>, stackID: string, summary: record<buckets: list<record>, checks: list<record>, dashboards: list<record>, labels: list<record>, labelMappings: list<record>, missingEnvRefs: list<string>, missingSecrets: list<string>, notificationEndpoints: list<record>, notificationRules: list<record>, tasks: list<record>, telegrafConfigs: list<record>, variables: list<record>>, diff: record<buckets: list<record>, checks: list<record>, dashboards: list<record>, labels: list<record>, labelMappings: list<record>, notificationEndpoints: list<record>, notificationRules: list<record>, tasks: list<record>, telegrafConfigs: list<record>, variables: list<record>>, errors: table<kind: string, reason: string, fields: list, indexes: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/apply")
  let body = {dryRun: $dryRun, orgID: $orgID, stackID: $stackID, template: $template, templates: $templates, envRefs: $envRefs, secrets: $secrets, remotes: $remotes, actions: $actions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export a new template
#
# POST /templates/export
# operationId: ExportTemplate
# --orgIDs item shape: {orgID?: string, resourceFilters?: record}
# --resources item shape: {id: string, kind: "Bucket"|"Check"|"CheckDeadman"|"CheckThreshold"|"Dashboard"|"Label"|"NotificationEndpoint"|"NotificationEndpointHTTP"|"NotificationEndpointPagerDuty"|"NotificationEndpointSlack"|"NotificationRule"|"Task"|"Telegraf"|"Variable", name?: string}
export def "templates-export ExportTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --stackID: string
  --orgIDs: list # item shape: {orgID?: string, resourceFilters?: record}
  --resources: list # item shape: {id: string, kind: "Bucket"|"Check"|"CheckDeadman"|"CheckThreshold"|"Dashboard"|"Label"|"NotificationEndpoint"|"NotificationEndpointHTTP"|"NotificationEndpointPagerDuty"|"NotificationEndpointSlack"|"NotificationRule"|"Task"|"Telegraf"|"Variable", name?: string}
]: any -> table<apiVersion: string, kind: string, metadata: record<name: string>, spec: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/export")
  let body = {stackID: $stackID, orgIDs: $orgIDs, resources: $resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List runs for a task
#
# GET /tasks/{taskID}/runs
# operationId: GetTasksIDRuns
export def "tasks-runs GetTasksIDRuns" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # A task run ID. Only returns runs created after this run.
  --limit: int # Limits the number of task runs returned. Default is `100`.  (default: 100)
  --afterTime: string # A timestamp ([RFC3339 date/time format](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#rfc3339-timestamp)). Only returns runs scheduled after this time.  (format: date-time)
  --beforeTime: string # A timestamp ([RFC3339 date/time format](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#rfc3339-timestamp)). Only returns runs scheduled before this time.  (format: date-time)
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<next: string, self: string, prev: string>, runs: table<id: string, taskID: string, status: string, scheduledFor: string, log: list, flux: string, startedAt: string, finishedAt: string, requestedAt: string, links: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "afterTime" $afterTime "scalar") (serialize-qp "beforeTime" $beforeTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($taskID)/runs" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start a task run, overriding the schedule
#
# POST /tasks/{taskID}/runs
# operationId: PostTasksIDRuns
export def "tasks-runs PostTasksIDRuns" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --scheduledFor: string # The time [RFC3339 date/time format](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#rfc3339-timestamp) used for the run's `now` option. Default is the server _now_ time.  (nullable, format: date-time)
]: any -> record<id: string, taskID: string, status: string, scheduledFor: string, log: table<time: string, message: string, runID: string>, flux: string, startedAt: string, finishedAt: string, requestedAt: string, links: record<self: string, task: string, retry: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/runs")
  let body = {scheduledFor: $scheduledFor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a run for a task.
#
# GET /tasks/{taskID}/runs/{runID}
# operationId: GetTasksIDRunsID
export def "tasks-runs GetTasksIDRunsID" [
  taskID: string
  runID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<id: string, taskID: string, status: string, scheduledFor: string, log: table<time: string, message: string, runID: string>, flux: string, startedAt: string, finishedAt: string, requestedAt: string, links: record<self: string, task: string, retry: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/runs/($runID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a running task
#
# DELETE /tasks/{taskID}/runs/{runID}
# operationId: DeleteTasksIDRunsID
export def "tasks-runs DeleteTasksIDRunsID" [
  taskID: string
  runID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/runs/($runID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retry a task run
#
# POST /tasks/{taskID}/runs/{runID}/retry
# operationId: PostTasksIDRunsIDRetry
export def "tasks-runs-retry PostTasksIDRunsIDRetry" [
  taskID: string
  runID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --body: record
]: any -> record<id: string, taskID: string, status: string, scheduledFor: string, log: table<time: string, message: string, runID: string>, flux: string, startedAt: string, finishedAt: string, requestedAt: string, links: record<self: string, task: string, retry: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/runs/($runID)/retry")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json; charset=utf-8" $body
}

# Retrieve all logs for a task
#
# GET /tasks/{taskID}/logs
# operationId: GetTasksIDLogs
export def "tasks-logs GetTasksIDLogs" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<events: table<time: string, message: string, runID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/logs")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all logs for a run
#
# GET /tasks/{taskID}/runs/{runID}/logs
# operationId: GetTasksIDRunsIDLogs
export def "tasks-runs-logs GetTasksIDRunsIDLogs" [
  taskID: string
  runID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<events: table<time: string, message: string, runID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/runs/($runID)/logs")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List labels for a task
#
# GET /tasks/{taskID}/labels
# operationId: GetTasksIDLabels
export def "tasks-labels GetTasksIDLabels" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<labels: table<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/labels")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a label to a task
#
# POST /tasks/{taskID}/labels
# operationId: PostTasksIDLabels
export def "tasks-labels PostTasksIDLabels" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  labelID: string # A label ID. Specifies the label to attach.
]: any -> record<label: record<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/labels")
  let body = {labelID: $labelID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a label from a task
#
# DELETE /tasks/{taskID}/labels/{labelID}
# operationId: DeleteTasksIDLabelsID
export def "tasks-labels DeleteTasksIDLabelsID" [
  taskID: string
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve feature flags
#
# GET /flags
# operationId: GetFlags
export def "flags GetFlags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/flags")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the currently authenticated user
#
# GET /me
# operationId: GetMe
export def "me GetMe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<id: string, name: string, status: string, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a password
#
# PUT /me/password
# operationId: PutMePassword
export def "me-password PutMePassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --influxdb-oss-session: string # The user session cookie for the [user](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#user) signed in with [Basic authentication credentials](#section/Authentication/BasicAuthentication).  #### Related guides  - [Manage users]({{% INFLUXDB_DOCS_URL%}}/users/)  (e.g. influxdb-oss-session=19aaaZZZGOvP2GGryXVT2qYftlFKu3bIopurM6AGFow1yF1abhtOlbHfsc-d8gozZFC_6WxmlQIAwLMW5xs523w==)
  password: string
]: any -> record<code: string, message: string, op: string, err: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/password")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let cookie_str = {influxdb-oss-session: $influxdb_oss_session} | transpose k v | where { $in.v != null } | each { $"($in.k)=($in.v)" } | str join "; "
  let auth = if ($cookie_str | is-not-empty) { $auth | update headers ($auth.headers | merge {Cookie: $cookie_str}) } else { $auth }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all task members
#
# GET /tasks/{taskID}/members
# DEPRECATED
# operationId: GetTasksIDMembers
@deprecated
export def "tasks-members GetTasksIDMembers" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<self: string>, users: table<id: string, name: string, status: string, links: record, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/members")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a member to a task
#
# POST /tasks/{taskID}/members
# DEPRECATED
# operationId: PostTasksIDMembers
@deprecated
export def "tasks-members PostTasksIDMembers" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  id: string # The ID of the user to add to the resource.
  --name: string # The name of the user to add to the resource.
]: any -> record<id: string, name: string, status: string, links: record<self: string>, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/members")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a member from a task
#
# DELETE /tasks/{taskID}/members/{userID}
# DEPRECATED
# operationId: DeleteTasksIDMembersID
@deprecated
export def "tasks-members DeleteTasksIDMembersID" [
  userID: string
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/members/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all owners of a task
#
# GET /tasks/{taskID}/owners
# DEPRECATED
# operationId: GetTasksIDOwners
@deprecated
export def "tasks-owners GetTasksIDOwners" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<self: string>, users: table<id: string, name: string, status: string, links: record, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/owners")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an owner for a task
#
# POST /tasks/{taskID}/owners
# DEPRECATED
# operationId: PostTasksIDOwners
@deprecated
export def "tasks-owners PostTasksIDOwners" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  id: string # The ID of the user to add to the resource.
  --name: string # The name of the user to add to the resource.
]: any -> record<id: string, name: string, status: string, links: record<self: string>, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/owners")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an owner from a task
#
# DELETE /tasks/{taskID}/owners/{userID}
# DEPRECATED
# operationId: DeleteTasksIDOwnersID
@deprecated
export def "tasks-owners DeleteTasksIDOwnersID" [
  userID: string
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/owners/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a password
#
# POST /users/{userID}/password
# operationId: PostUsersIDPassword
export def "users-password PostUsersIDPassword" [
  userID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userID)/password")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a password
#
# PUT /users/{userID}/password
# operationId: PutUsersIDPassword
export def "users-password PutUsersIDPassword" [
  userID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userID)/password")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all checks
#
# GET /checks
# operationId: GetChecks
export def "checks GetChecks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # The offset for pagination. The number of records to skip.  For more information about pagination parameters, see [Pagination](https://docs.influxdata.com/influxdb/cloud/api/#tag/Pagination).
  --limit: int # Limits the number of records returned. Default is `20`.  (default: 20)
  --orgID: string # Only show checks that belong to a specific organization ID.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<checks: list<record>, links: record<next: string, self: string, prev: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/checks" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add new check
#
# POST /checks
# operationId: CreateCheck
export def "checks CreateCheck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/checks")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a check
#
# GET /checks/{checkID}
# operationId: GetChecksID
export def "checks GetChecksID" [
  checkID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checks/($checkID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a check
#
# PUT /checks/{checkID}
# operationId: PutChecksID
export def "checks PutChecksID" [
  checkID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checks/($checkID)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a check
#
# PATCH /checks/{checkID}
# operationId: PatchChecksID
export def "checks PatchChecksID" [
  checkID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --name: string
  --description: string
  --status: string@status-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checks/($checkID)")
  let body = {name: $name, description: $description, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a check
#
# DELETE /checks/{checkID}
# operationId: DeleteChecksID
export def "checks DeleteChecksID" [
  checkID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checks/($checkID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all labels for a check
#
# GET /checks/{checkID}/labels
# operationId: GetChecksIDLabels
export def "checks-labels GetChecksIDLabels" [
  checkID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<labels: table<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checks/($checkID)/labels")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a label to a check
#
# POST /checks/{checkID}/labels
# operationId: PostChecksIDLabels
export def "checks-labels PostChecksIDLabels" [
  checkID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  labelID: string # A label ID. Specifies the label to attach.
]: any -> record<label: record<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checks/($checkID)/labels")
  let body = {labelID: $labelID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete label from a check
#
# DELETE /checks/{checkID}/labels/{labelID}
# operationId: DeleteChecksIDLabelsID
export def "checks-labels DeleteChecksIDLabelsID" [
  checkID: string
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checks/($checkID)/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all notification rules
#
# GET /notificationRules
# operationId: GetNotificationRules
export def "notification-rules GetNotificationRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # The offset for pagination. The number of records to skip.  For more information about pagination parameters, see [Pagination](https://docs.influxdata.com/influxdb/cloud/api/#tag/Pagination).
  --limit: int # Limits the number of records returned. Default is `20`.  (default: 20)
  --orgID: string # Only show notification rules that belong to a specific organization ID.
  --checkID: string # Only show notifications that belong to the specific check ID.
  --tag: string # Only return notification rules that "would match" statuses which contain the tag key value pairs provided. (e.g. env:prod)
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<notificationRules: list<record>, links: record<next: string, self: string, prev: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "orgID" $orgID "scalar") (serialize-qp "checkID" $checkID "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notificationRules" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a notification rule
#
# POST /notificationRules
# operationId: CreateNotificationRule
export def "notification-rules CreateNotificationRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notificationRules")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a check query
#
# GET /checks/{checkID}/query
# operationId: GetChecksIDQuery
export def "checks-query GetChecksIDQuery" [
  checkID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<flux: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checks/($checkID)/query")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a notification rule
#
# GET /notificationRules/{ruleID}
# operationId: GetNotificationRulesID
export def "notification-rules GetNotificationRulesID" [
  ruleID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationRules/($ruleID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a notification rule
#
# PUT /notificationRules/{ruleID}
# operationId: PutNotificationRulesID
export def "notification-rules PutNotificationRulesID" [
  ruleID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationRules/($ruleID)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a notification rule
#
# PATCH /notificationRules/{ruleID}
# operationId: PatchNotificationRulesID
export def "notification-rules PatchNotificationRulesID" [
  ruleID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --name: string
  --description: string
  --status: string@status-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationRules/($ruleID)")
  let body = {name: $name, description: $description, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a notification rule
#
# DELETE /notificationRules/{ruleID}
# operationId: DeleteNotificationRulesID
export def "notification-rules DeleteNotificationRulesID" [
  ruleID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationRules/($ruleID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all labels for a notification rule
#
# GET /notificationRules/{ruleID}/labels
# operationId: GetNotificationRulesIDLabels
export def "notification-rules-labels GetNotificationRulesIDLabels" [
  ruleID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<labels: table<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationRules/($ruleID)/labels")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a label to a notification rule
#
# POST /notificationRules/{ruleID}/labels
# operationId: PostNotificationRuleIDLabels
export def "notification-rules-labels PostNotificationRuleIDLabels" [
  ruleID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  labelID: string # A label ID. Specifies the label to attach.
]: any -> record<label: record<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationRules/($ruleID)/labels")
  let body = {labelID: $labelID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete label from a notification rule
#
# DELETE /notificationRules/{ruleID}/labels/{labelID}
# operationId: DeleteNotificationRulesIDLabelsID
export def "notification-rules-labels DeleteNotificationRulesIDLabelsID" [
  ruleID: string
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationRules/($ruleID)/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a notification rule query
#
# GET /notificationRules/{ruleID}/query
# operationId: GetNotificationRulesIDQuery
export def "notification-rules-query GetNotificationRulesIDQuery" [
  ruleID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<flux: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationRules/($ruleID)/query")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all notification endpoints
#
# GET /notificationEndpoints
# operationId: GetNotificationEndpoints
export def "notification-endpoints GetNotificationEndpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # The offset for pagination. The number of records to skip.  For more information about pagination parameters, see [Pagination](https://docs.influxdata.com/influxdb/cloud/api/#tag/Pagination).
  --limit: int # Limits the number of records returned. Default is `20`.  (default: 20)
  --orgID: string # Only show notification endpoints that belong to specific organization ID.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<notificationEndpoints: list<record>, links: record<next: string, self: string, prev: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notificationEndpoints" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a notification endpoint
#
# POST /notificationEndpoints
# operationId: CreateNotificationEndpoint
export def "notification-endpoints CreateNotificationEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notificationEndpoints")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a notification endpoint
#
# GET /notificationEndpoints/{endpointID}
# operationId: GetNotificationEndpointsID
export def "notification-endpoints GetNotificationEndpointsID" [
  endpointID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationEndpoints/($endpointID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a notification endpoint
#
# PUT /notificationEndpoints/{endpointID}
# operationId: PutNotificationEndpointsID
export def "notification-endpoints PutNotificationEndpointsID" [
  endpointID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationEndpoints/($endpointID)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a notification endpoint
#
# PATCH /notificationEndpoints/{endpointID}
# operationId: PatchNotificationEndpointsID
export def "notification-endpoints PatchNotificationEndpointsID" [
  endpointID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --name: string
  --description: string
  --status: string@status-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationEndpoints/($endpointID)")
  let body = {name: $name, description: $description, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a notification endpoint
#
# DELETE /notificationEndpoints/{endpointID}
# operationId: DeleteNotificationEndpointsID
export def "notification-endpoints DeleteNotificationEndpointsID" [
  endpointID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationEndpoints/($endpointID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all labels for a notification endpoint
#
# GET /notificationEndpoints/{endpointID}/labels
# operationId: GetNotificationEndpointsIDLabels
export def "notification-endpoints-labels GetNotificationEndpointsIDLabels" [
  endpointID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<labels: table<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationEndpoints/($endpointID)/labels")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a label to a notification endpoint
#
# POST /notificationEndpoints/{endpointID}/labels
# operationId: PostNotificationEndpointIDLabels
export def "notification-endpoints-labels PostNotificationEndpointIDLabels" [
  endpointID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  labelID: string # A label ID. Specifies the label to attach.
]: any -> record<label: record<id: string, orgID: string, name: string, properties: record>, links: record<next: string, self: string, prev: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationEndpoints/($endpointID)/labels")
  let body = {labelID: $labelID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a label from a notification endpoint
#
# DELETE /notificationEndpoints/{endpointID}/labels/{labelID}
# operationId: DeleteNotificationEndpointsIDLabelsID
export def "notification-endpoints-labels DeleteNotificationEndpointsIDLabelsID" [
  endpointID: string
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<code: string, message: string, op: string, err: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationEndpoints/($endpointID)/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List authorizations
#
# GET /authorizations
# operationId: GetAuthorizations
export def "authorizations GetAuthorizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userID: string # A user ID. Only returns authorizations scoped to the specified [user](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#user).
  --user: string # A user name. Only returns authorizations scoped to the specified [user](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#user).
  --orgID: string # An organization ID. Only returns authorizations that belong to the specified [organization](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#organization).
  --org: string # An organization name. Only returns authorizations that belong to the specified [organization](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#organization).
  --qp-token: string # An API [token](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#token) value. Specifies an authorization by its `token` property value and returns the authorization.  #### InfluxDB OSS  - Doesn't support this parameter. InfluxDB OSS ignores the `token=` parameter,   applies other parameters, and then returns the result.  #### Limitations  - The parameter is non-repeatable. If you specify more than one,   only the first one is used. If a resource with the specified   property value doesn't exist, then the response body contains an empty list.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<next: string, self: string, prev: string>, authorizations: table<status: string, description: string, createdAt: string, updatedAt: string, orgID: string, permissions: list, id: string, token: string, userID: string, user: string, org: string, links: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userID" $userID "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "orgID" $orgID "scalar") (serialize-qp "org" $org "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authorizations" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an authorization
#
# POST /authorizations
# operationId: PostAuthorizations
# --permissions item shape: {action: "read"|"write", resource: record}
export def "authorizations PostAuthorizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --status: string@status-completer # Status of the token. If `inactive`, InfluxDB rejects requests that use the token. (default: active)
  --description: string # A description of the token.
  orgID: string # An organization ID. Specifies the organization that owns the authorization.
  --userID: string # A user ID. Specifies the user that the authorization is scoped to.  When a user authenticates with username and password, InfluxDB generates a _user session_ with all the permissions specified by all the user's authorizations.
  permissions: list # A list of permissions for an authorization. In the list, provide at least one `permission` object.  In a `permission`, the `resource.type` property grants access to all resources of the specified type. To grant access to only a specific resource, specify the `resource.id` property. — item shape: {action: "read"|"write", resource: record}
]: any -> record<status: string, description: string, createdAt: string, updatedAt: string, orgID: string, permissions: table<action: string, resource: record>, id: string, token: string, userID: string, user: string, org: string, links: record<self: string, user: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authorizations")
  let body = {status: $status, description: $description, orgID: $orgID, userID: $userID, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an authorization
#
# GET /authorizations/{authID}
# Docs: https://docs.influxdata.com/influxdb/cloud/security/tokens/view-tokens/ — View tokens
# operationId: GetAuthorizationsID
export def "authorizations GetAuthorizationsID" [
  authID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<status: string, description: string, createdAt: string, updatedAt: string, orgID: string, permissions: table<action: string, resource: record>, id: string, token: string, userID: string, user: string, org: string, links: record<self: string, user: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorizations/($authID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an API token to be active or inactive
#
# PATCH /authorizations/{authID}
# operationId: PatchAuthorizationsID
export def "authorizations PatchAuthorizationsID" [
  authID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --status: string@status-completer # Status of the token. If `inactive`, InfluxDB rejects requests that use the token. (default: active)
  --description: string # A description of the token.
]: any -> record<status: string, description: string, createdAt: string, updatedAt: string, orgID: string, permissions: table<action: string, resource: record>, id: string, token: string, userID: string, user: string, org: string, links: record<self: string, user: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorizations/($authID)")
  let body = {status: $status, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an authorization
#
# DELETE /authorizations/{authID}
# operationId: DeleteAuthorizationsID
export def "authorizations DeleteAuthorizationsID" [
  authID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorizations/($authID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List users
#
# GET /users
# operationId: GetUsers
export def "users GetUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # A user name. Only lists the specified [user](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#user).
  --id: string # A user id. Only lists the specified [user](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#user).
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<self: string>, users: table<id: string, name: string, status: string, links: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a user
#
# POST /users
# operationId: PostUsers
export def "users PostUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  name: string
  --status: string@status-completer # If inactive the user is inactive. (default: active)
  --role: string@role-completer
  --org-id: string
]: any -> record<id: string, name: string, status: string, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let body = {name: $name, status: $status, role: $role, org_id: $org_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a user
#
# GET /users/{userID}
# operationId: GetUsersID
export def "users GetUsersID" [
  userID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<id: string, name: string, status: string, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user
#
# PATCH /users/{userID}
# operationId: PatchUsersID
export def "users PatchUsersID" [
  userID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  name: string
  --status: string@status-completer # If inactive the user is inactive. (default: active)
  --role: string@role-completer
  --org-id: string
]: any -> record<id: string, name: string, status: string, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userID)")
  let body = {name: $name, status: $status, role: $role, org_id: $org_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a user
#
# DELETE /users/{userID}
# operationId: DeleteUsersID
export def "users DeleteUsersID" [
  userID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve setup status
#
# GET /setup
# operationId: GetSetup
export def "setup GetSetup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<allowed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an initial user, organization, and bucket
#
# POST /setup
# operationId: PostSetup
# --limit shape: {orgID?: string, rate: record, bucket: record, task: record, dashboard: record, check: record, notificationRule: record, notificationEndpoint: record, stack?: record, timeout?: record, ioxQuery?: record, features?: record}
@deprecated --flag retentionPeriodHrs
export def "setup PostSetup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  username: string
  --password: string
  org: string
  bucket: string
  --retentionPeriodHrs: int # DEPRECATED
  --retentionPeriodSeconds: int
  --limit: record # These are org limits similar to those configured in/by quartz. — shape: {orgID?: string, rate: record, bucket: record, task: record, dashboard: record, check: record, notificationRule: record, notificationEndpoint: record, stack?: record, timeout?: record, ioxQuery?: record, features?: record}
]: any -> record<user: record<id: string, name: string, status: string, links: record<self: string>>, org: record<links: record<self: string, members: string, owners: string, labels: string, secrets: string, buckets: string, tasks: string, dashboards: string>, id: string, name: string, defaultStorageType: string, description: string, createdAt: string, updatedAt: string, status: string>, bucket: record<links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, id: string, type: string, name: string, description: string, orgID: string, rp: string, schemaType: string, createdAt: string, updatedAt: string, retentionRules: list<record>, labels: list<record>>, auth: record<status: string, description: string, createdAt: string, updatedAt: string, orgID: string, permissions: list<record>, id: string, token: string, userID: string, user: string, org: string, links: record<self: string, user: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup")
  let body = {username: $username, password: $password, org: $org, bucket: $bucket, retentionPeriodHrs: $retentionPeriodHrs, retentionPeriodSeconds: $retentionPeriodSeconds, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new user, organization, and bucket
#
# POST /setup/user
# operationId: PostSetupUser
# --limit shape: {orgID?: string, rate: record, bucket: record, task: record, dashboard: record, check: record, notificationRule: record, notificationEndpoint: record, stack?: record, timeout?: record, ioxQuery?: record, features?: record}
@deprecated --flag retentionPeriodHrs
export def "setup-user PostSetupUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  username: string
  --password: string
  org: string
  bucket: string
  --retentionPeriodHrs: int # DEPRECATED
  --retentionPeriodSeconds: int
  --limit: record # These are org limits similar to those configured in/by quartz. — shape: {orgID?: string, rate: record, bucket: record, task: record, dashboard: record, check: record, notificationRule: record, notificationEndpoint: record, stack?: record, timeout?: record, ioxQuery?: record, features?: record}
]: any -> record<user: record<id: string, name: string, status: string, links: record<self: string>>, org: record<links: record<self: string, members: string, owners: string, labels: string, secrets: string, buckets: string, tasks: string, dashboards: string>, id: string, name: string, defaultStorageType: string, description: string, createdAt: string, updatedAt: string, status: string>, bucket: record<links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, id: string, type: string, name: string, description: string, orgID: string, rp: string, schemaType: string, createdAt: string, updatedAt: string, retentionRules: list<record>, labels: list<record>>, auth: record<status: string, description: string, createdAt: string, updatedAt: string, orgID: string, permissions: list<record>, id: string, token: string, userID: string, user: string, org: string, links: record<self: string, user: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/user")
  let body = {username: $username, password: $password, org: $org, bucket: $bucket, retentionPeriodHrs: $retentionPeriodHrs, retentionPeriodSeconds: $retentionPeriodSeconds, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all variables
#
# GET /variables
# operationId: GetVariables
export def "variables GetVariables" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --org: string # The name of the organization.
  --orgID: string # The organization ID.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<variables: table<links: record, id: string, orgID: string, name: string, description: string, selected: list, sort_order: int, labels: list, arguments: record, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/variables" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a variable
#
# POST /variables
# operationId: PostVariables
# --links shape: {self?: string, org?: string, labels?: string}
# --labels item shape: {name?: string, properties?: record}
# --arguments shape: {type?: "query", values?: record}
export def "variables PostVariables" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  orgID: string
  name: string
  --description: string
  --selected: list
  --sort-order: int
  --labels: list # item shape: {name?: string, properties?: record}
  arguments: record # shape: {type?: "query", values?: record}
  --createdAt: string # format: date-time
  --updatedAt: string # format: date-time
]: any -> record<links: record<self: string, org: string, labels: string>, id: string, orgID: string, name: string, description: string, selected: list<string>, sort_order: int, labels: table<id: string, orgID: string, name: string, properties: record>, arguments: record, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/variables")
  let body = {orgID: $orgID, name: $name, description: $description, selected: $selected, sort_order: $sort_order, labels: $labels, arguments: $arguments, createdAt: $createdAt, updatedAt: $updatedAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a variable
#
# GET /variables/{variableID}
# operationId: GetVariablesID
export def "variables GetVariablesID" [
  variableID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<self: string, org: string, labels: string>, id: string, orgID: string, name: string, description: string, selected: list<string>, sort_order: int, labels: table<id: string, orgID: string, name: string, properties: record>, arguments: record, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/variables/($variableID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a variable
#
# DELETE /variables/{variableID}
# operationId: DeleteVariablesID
export def "variables DeleteVariablesID" [
  variableID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/variables/($variableID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a variable
#
# PATCH /variables/{variableID}
# operationId: PatchVariablesID
# --links shape: {self?: string, org?: string, labels?: string}
# --labels item shape: {name?: string, properties?: record}
# --arguments shape: {type?: "query", values?: record}
export def "variables PatchVariablesID" [
  variableID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  orgID: string
  name: string
  --description: string
  --selected: list
  --sort-order: int
  --labels: list # item shape: {name?: string, properties?: record}
  arguments: record # shape: {type?: "query", values?: record}
  --createdAt: string # format: date-time
  --updatedAt: string # format: date-time
]: any -> record<links: record<self: string, org: string, labels: string>, id: string, orgID: string, name: string, description: string, selected: list<string>, sort_order: int, labels: table<id: string, orgID: string, name: string, properties: record>, arguments: record, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/variables/($variableID)")
  let body = {orgID: $orgID, name: $name, description: $description, selected: $selected, sort_order: $sort_order, labels: $labels, arguments: $arguments, createdAt: $createdAt, updatedAt: $updatedAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace a variable
#
# PUT /variables/{variableID}
# operationId: PutVariablesID
# --links shape: {self?: string, org?: string, labels?: string}
# --labels item shape: {name?: string, properties?: record}
# --arguments shape: {type?: "query", values?: record}
export def "variables PutVariablesID" [
  variableID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  orgID: string
  name: string
  --description: string
  --selected: list
  --sort-order: int
  --labels: list # item shape: {name?: string, properties?: record}
  arguments: record # shape: {type?: "query", values?: record}
  --createdAt: string # format: date-time
  --updatedAt: string # format: date-time
]: any -> record<links: record<self: string, org: string, labels: string>, id: string, orgID: string, name: string, description: string, selected: list<string>, sort_order: int, labels: table<id: string, orgID: string, name: string, properties: record>, arguments: record, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/variables/($variableID)")
  let body = {orgID: $orgID, name: $name, description: $description, selected: $selected, sort_order: $sort_order, labels: $labels, arguments: $arguments, createdAt: $createdAt, updatedAt: $updatedAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List measurement schemas of a bucket
#
# GET /buckets/{bucketID}/schema/measurements
# operationId: getMeasurementSchemas
export def "buckets-schema-measurements list" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --org: string # An organization name. Specifies the organization that owns the schema.
  --orgID: string # An organization ID. Specifies the organization that owns the schema.
  --name: string # A measurement name. Only returns measurement schemas with the specified name.
]: nothing -> record<measurementSchemas: table<id: string, orgID: string, bucketID: string, name: string, columns: list, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "orgID" $orgID "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/buckets/($bucketID)/schema/measurements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a measurement schema for a bucket
#
# POST /buckets/{bucketID}/schema/measurements
# operationId: createMeasurementSchema
# --columns item shape: {name: string, type: "timestamp"|"tag"|"field", dataType?: "integer"|"float"|"boolean"|"string"|"unsigned"}
export def "buckets-schema-measurements createMeasurementSchema" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --org: string # An organization name. Specifies the organization that owns the schema.
  --orgID: string # An organization ID. Specifies the organization that owns the schema.
  name: string # The [measurement](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#measurement) name.
  columns: list # Ordered collection of column definitions. — item shape: {name: string, type: "timestamp"|"tag"|"field", dataType?: "integer"|"float"|"boolean"|"string"|"unsigned"}
]: any -> record<id: string, orgID: string, bucketID: string, name: string, columns: table<name: string, type: string, dataType: string>, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/buckets/($bucketID)/schema/measurements" $qp)
  let body = {name: $name, columns: $columns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a measurement schema
#
# GET /buckets/{bucketID}/schema/measurements/{measurementID}
# operationId: getMeasurementSchema
export def "buckets-schema-measurements get" [
  bucketID: string
  measurementID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --org: string # Organization name. Specifies the organization that owns the schema.
  --orgID: string # Organization ID. Specifies the organization that owns the schema.
]: nothing -> record<id: string, orgID: string, bucketID: string, name: string, columns: table<name: string, type: string, dataType: string>, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/buckets/($bucketID)/schema/measurements/($measurementID)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a measurement schema
#
# PATCH /buckets/{bucketID}/schema/measurements/{measurementID}
# operationId: updateMeasurementSchema
# --columns item shape: {name: string, type: "timestamp"|"tag"|"field", dataType?: "integer"|"float"|"boolean"|"string"|"unsigned"}
export def "buckets-schema-measurements updateMeasurementSchema" [
  bucketID: string
  measurementID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --org: string # An organization name. Specifies the organization that owns the schema.
  --orgID: string # An organization ID. Specifies the organization that owns the schema.
  columns: list # An ordered collection of column definitions — item shape: {name: string, type: "timestamp"|"tag"|"field", dataType?: "integer"|"float"|"boolean"|"string"|"unsigned"}
]: any -> record<id: string, orgID: string, bucketID: string, name: string, columns: table<name: string, type: string, dataType: string>, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/buckets/($bucketID)/schema/measurements/($measurementID)" $qp)
  let body = {columns: $columns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve limits for an organization
#
# GET /orgs/{orgID}/limits
# operationId: GetOrgLimitsID
export def "orgs-limits GetOrgLimitsID" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<links: record<next: string, self: string, prev: string>, limits: record<orgID: string, rate: record<queryTime: int, readKBs: int, concurrentReadRequests: int, writeKBs: int, concurrentWriteRequests: int, cardinality: int, concurrentDeleteRequests: int, deleteRequestsPerSecond: int>, bucket: record<maxBuckets: int, maxRetentionDuration: int>, task: record<maxTasks: int>, dashboard: record<maxDashboards: int>, check: record<maxChecks: int>, notificationRule: record<maxNotifications: int, blockedNotificationRules: string>, notificationEndpoint: record<blockedNotificationEndpoints: string>, stack: record<enabled: bool>, timeout: record<queryUnconditionalTimeoutSeconds: int, queryidleWriteTimeoutSeconds: int>, ioxQuery: record<partitions: int, parquetFiles: int>, features: record<allowDelete: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/limits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve usage for an organization
#
# GET /orgs/{orgID}/usage
# operationId: GetOrgUsageID
export def "orgs-usage GetOrgUsageID" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Earliest time to include in results. For more information about timestamps, see [Manipulate timestamps with Flux](https://docs.influxdata.com/influxdb/cloud/query-data/flux/manipulate-timestamps/).  (format: unix timestamp)
  --stop: int # Latest time to include in results. For more information about timestamps, see [Manipulate timestamps with Flux](https://docs.influxdata.com/influxdb/cloud/query-data/flux/manipulate-timestamps/).  (format: unix timestamp)
  --qp-raw: string@bool-completer # return raw usage data (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "stop" $stop "scalar") (serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($orgID)/usage" $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a dashboard
#
# POST /dashboards
# operationId: PostDashboards
export def "dashboards PostDashboards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  orgID: string # The ID of the organization that owns the dashboard.
  name: string # The user-facing name of the dashboard.
  --description: string # The user-facing description of the dashboard.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dashboards")
  let body = {orgID: $orgID, name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List dashboards
#
# GET /dashboards
# operationId: GetDashboards
export def "dashboards GetDashboards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # The offset for pagination. The number of records to skip.  For more information about pagination parameters, see [Pagination](https://docs.influxdata.com/influxdb/cloud/api/#tag/Pagination).
  --descending: string@bool-completer # default: false
  --limit: int # The maximum number of [dashboards](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#dashboard) to return. Default is `20`. The minimum is `-1` and the maximum is `100`.  (default: 20)
  --owner: string # A user ID. Only returns [dashboards](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#dashboard) where the specified user has the `owner` role.
  --sortBy: string@sortBy-completer # The column to sort by.
  --id: list # A list of dashboard IDs. Returns only the specified [dashboards](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#dashboard). If you specify `id` and `owner`, only `id` is used.
  --orgID: string # An organization ID. Only returns [dashboards](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#dashboard) that belong to the specified [organization](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#organization).
  --org: string # An organization name. Only returns [dashboards](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#dashboard) that belong to the specified [organization](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#organization).
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<next: string, self: string, prev: string>, dashboards: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "descending" $descending "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "id" $id "multi") (serialize-qp "orgID" $orgID "scalar") (serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dashboards" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all tasks
#
# GET /tasks
# operationId: GetTasks
export def "tasks GetTasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # A [task](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#task) name. Only returns tasks with the specified name. Different tasks may have the same name.
  --after: string # A [task](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#task) ID. Only returns tasks created after the specified task.
  --user: string # A [user](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#user) ID. Only returns tasks owned by the specified user.
  --org: string # An [organization](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#organization) name. Only returns tasks owned by the specified organization.
  --orgID: string # An [organization](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#organization) ID. Only returns tasks owned by the specified organization.
  --status: string@status-completer # A [task](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#task) status. Only returns tasks that have the specified status (`active` or `inactive`).
  --limit: int # The maximum number of [tasks](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#task) to return. Default is `100`. The minimum is `1` and the maximum is `500`.  To reduce the payload size, combine _`type=basic`_ and _`limit`_ (see _Request samples_). For more information about the `basic` response, see the _`type`_ parameter.  (default: 100)
  --offset: int # The number of records to skip. (default: 0)
  --sortBy: string@sortBy-completer-1 # The sort field. Only `name` is supported. Specifies the field used to sort records in the list.
  --type: string@type-completer-1 # A [task](https://docs.influxdata.com/influxdb/cloud/reference/glossary/#task) type (`basic` or `system`). Default is `system`. Specifies the level of detail for tasks in the response. The default (`system`) response contains all the metadata properties for tasks. To reduce the response size, pass `basic` to omit some task properties (`flux`, `createdAt`, `updatedAt`).  (default: )
  --scriptID: string # A [script](#tag/Invokable-Scripts) ID. Only returns tasks that use the specified invokable script.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<links: record<next: string, self: string, prev: string>, tasks: table<id: string, orgID: string, org: string, name: string, ownerID: string, description: string, status: string, labels: list, authorizationID: string, flux: string, every: string, cron: string, offset: string, latestCompleted: string, lastRunStatus: string, lastRunError: string, createdAt: string, updatedAt: string, links: record, scriptID: string, scriptParameters: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "org" $org "scalar") (serialize-qp "orgID" $orgID "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "scriptID" $scriptID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tasks" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a task
#
# POST /tasks
# operationId: PostTasks
export def "tasks PostTasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --orgID: string # The ID of the organization that owns the task.
  --org: string # The name of the organization that owns the task.
  --status: string@status-completer # `inactive` cancels scheduled runs and prevents manual runs of the task.
  --flux: string # The Flux script that the task runs.  #### Limitations  - If you use the `flux` property, you can't use the `scriptID` and `scriptParameters` properties.
  --description: string # The description of the task.
  --scriptID: string # The ID of the script that the task runs.  #### Limitations  - If you use the `scriptID` property, you can't use the `flux` property.
  --scriptParameters: record # The parameter key-value pairs passed to the script (referenced by `scriptID`) during the task run.  #### Limitations  - `scriptParameters` requires `scriptID`. - If you use the `scriptID` and `scriptParameters` properties, you can't use the `flux` property.
  --name: string # The name of the task
  --every: string # The interval ([duration literal](https://docs.influxdata.com/flux/v0.x/spec/lexical-elements/#duration-literals))) at which the task runs. `every` also determines when the task first runs, depending on the specified time.
  --cron: string # A [Cron expression](https://en.wikipedia.org/wiki/Cron#Overview) that defines the schedule on which the task runs. InfluxDB bases cron runs on the system time.
  --offset: string # A [duration](https://docs.influxdata.com/flux/v0.x/spec/lexical-elements/#duration-literals) to delay execution of the task after the scheduled time has elapsed. `0` removes the offset. (format: duration)
]: any -> record<id: string, orgID: string, org: string, name: string, ownerID: string, description: string, status: string, labels: table<id: string, orgID: string, name: string, properties: record>, authorizationID: string, flux: string, every: string, cron: string, offset: string, latestCompleted: string, lastRunStatus: string, lastRunError: string, createdAt: string, updatedAt: string, links: record<self: string, owners: string, members: string, runs: string, logs: string, labels: string>, scriptID: string, scriptParameters: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tasks")
  let body = {orgID: $orgID, org: $org, status: $status, flux: $flux, description: $description, scriptID: $scriptID, scriptParameters: $scriptParameters, name: $name, every: $every, cron: $cron, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a task
#
# GET /tasks/{taskID}
# operationId: GetTasksID
export def "tasks GetTasksID" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> record<id: string, orgID: string, org: string, name: string, ownerID: string, description: string, status: string, labels: table<id: string, orgID: string, name: string, properties: record>, authorizationID: string, flux: string, every: string, cron: string, offset: string, latestCompleted: string, lastRunStatus: string, lastRunError: string, createdAt: string, updatedAt: string, links: record<self: string, owners: string, members: string, runs: string, logs: string, labels: string>, scriptID: string, scriptParameters: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a task
#
# PATCH /tasks/{taskID}
# operationId: PatchTasksID
export def "tasks PatchTasksID" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
  --status: string@status-completer # `inactive` cancels scheduled runs and prevents manual runs of the task.
  --flux: string # Update the Flux script that the task runs.
  --name: string # Update the 'name' option in the flux script.
  --every: string # Update the 'every' option in the flux script.
  --cron: string # Update the 'cron' option in the flux script.
  --offset: string # Update the 'offset' option in the flux script.
  --description: string # Update the description of the task.
  --scriptID: string # Update the 'scriptID' of the task.
  --scriptParameters: record # Update the 'scriptParameters' of the task.
]: any -> record<id: string, orgID: string, org: string, name: string, ownerID: string, description: string, status: string, labels: table<id: string, orgID: string, name: string, properties: record>, authorizationID: string, flux: string, every: string, cron: string, offset: string, latestCompleted: string, lastRunStatus: string, lastRunError: string, createdAt: string, updatedAt: string, links: record<self: string, owners: string, members: string, runs: string, logs: string, labels: string>, scriptID: string, scriptParameters: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)")
  let body = {status: $status, flux: $flux, name: $name, every: $every, cron: $cron, offset: $offset, description: $description, scriptID: $scriptID, scriptParameters: $scriptParameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a task
#
# DELETE /tasks/{taskID}
# operationId: DeleteTasksID
export def "tasks DeleteTasksID" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {trace_id: 1, span_id: 1, baggage: {key: value}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
