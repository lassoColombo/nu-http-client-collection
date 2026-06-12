# Auto-generated client for Rudder API v16
# Source: https://api.apis.guru/v2/specs/rudder.example.local/16/openapi.json
# Auth: --token flag or $env.RUDDER_API_TOKEN

const BASE_URL = "https://rudder.example.local/rudder/api/latest"
const DEFAULT_AUTH = "x-api-token"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o RUDDER_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-token" => { {headers: {X-API-Token: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://rudder.example.local/rudder/api/latest"] }
def auth-scheme-completer [] { ["x-api-token"] }

# Completers for enum parameters
def status-completer [] { ["deployed" "pending deployment"] }
def policyMode-completer [] { ["audit" "enforce"] }
def composition-completer [] { ["and" "or"] }
def status-completer-1 [] { ["accepted" "refused"] }
def mode-completer [] { ["erase" "move"] }
def policyMode-completer-1 [] { ["audit" "default" "enforce"] }
def state-completer [] { ["empty-policies" "enabled" "ignored" "initializing" "preparing-eol"] }
def isPreHahed-completer [] { ["false" "true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "change-requests listChangeRequests" } } | get name | first)
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

# List all change requests
#
# GET /api/changeRequests
# operationId: listChangeRequests
export def "change-requests listChangeRequests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<rules: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/changeRequests")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a ZIP archive of the requested items and their dependencies
#
# GET /archives/export
# operationId: export
export def "archives-export export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # IDs (optionally with revision, '+' need to be escaped as '%2B') of rules to include
  --directives: list # IDs (optionally with revision, '+' need to be escaped as '%2B') of directives to include
  --techniques: list # IDs, ie technique name/technique version (optionally with revision, '+' need to be escaped as '%2B') of techniques to include
  --groups: list # IDs (optionally with revision, '+' need to be escaped as '%2B') of groups to include
  --include: list # Scope of dependencies to include in archive, where rule as directives and groups dependencies, directives have techniques dependencies, and techniques and groups don't have dependencies. 'none' means no dependencies will be include, 'all' means that the whole tree will,  'directives' and 'groups' means to include them specifically, 'techniques' means to include both directives and techniques.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rules" $rules "csv") (serialize-qp "directives" $directives "csv") (serialize-qp "techniques" $techniques "csv") (serialize-qp "groups" $groups "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/archives/export" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Import a ZIP archive of policies into Rudder
#
# POST /archives/import
# operationId: import
export def "archives-import import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --archive: string # The ZIP archive file containing policies in a conventional layout and serialization format (format: binary)
]: any -> record<action: string, data: record<archiveImported: bool>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/archives/import")
  let body = {archive: $archive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get branding configuration
#
# GET /branding
# operationId: getBrandingConf
export def "branding get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<branding: record<barColor: record, displayBar: bool, displayBarLogin: bool, displayLabel: bool, displayMotd: bool, labelColor: record, labelText: string, motd: string, smallLogo: record, wideLogo: record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/branding")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update web interface customization
#
# POST /branding
# operationId: updateBRandingConf
# --barColor shape: {alpha: float, blue: float, green: float, red: float}
# --labelColor shape: {alpha: float, blue: float, green: float, red: float}
# --smallLogo shape: {enable: bool}
# --wideLogo shape: {enable: bool}
export def "branding updateBRandingConf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  barColor: record # shape: {alpha: float, blue: float, green: float, red: float}
  --displayBar: oneof<nothing, bool> # Whether header bar is displayed or not
  --displayBarLogin: oneof<nothing, bool> # Whether header bar is displayed in login page or not
  --displayLabel: oneof<nothing, bool> # Whether header bar's label is displayed or not
  --displayMotd: oneof<nothing, bool> # Whether the message of the day is displayed in login page or not
  labelColor: record # shape: {alpha: float, blue: float, green: float, red: float}
  labelText: string # The header bar's label title (e.g. Production)
  motd: string # Message of the day in login page (e.g. Welcome, please sign in:)
  smallLogo: record # shape: {enable: bool}
  wideLogo: record # shape: {enable: bool}
]: any -> record<action: string, data: record<branding: record<barColor: record, displayBar: bool, displayBarLogin: bool, displayLabel: bool, displayMotd: bool, labelColor: record, labelText: string, motd: string, smallLogo: record, wideLogo: record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/branding")
  let body = {barColor: $barColor, displayBar: $displayBar, displayBarLogin: $displayBarLogin, displayLabel: $displayLabel, displayMotd: $displayMotd, labelColor: $labelColor, labelText: $labelText, motd: $motd, smallLogo: $smallLogo, wideLogo: $wideLogo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reload branding file
#
# POST /branding/reload
# operationId: reloadBrandingConf
export def "branding-reload reloadBrandingConf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<branding: record<barColor: record, displayBar: bool, displayBarLogin: bool, displayLabel: bool, displayMotd: bool, labelColor: record, labelText: string, motd: string, smallLogo: record, wideLogo: record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/branding/reload")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Decline a request details
#
# DELETE /changeRequests/{changeRequestId}
# operationId: declineChangeRequest
export def "change-requests declineChangeRequest" [
  changeRequestId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<rules: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/changeRequests/($changeRequestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a change request details
#
# GET /changeRequests/{changeRequestId}
# operationId: changeRequestDetails
export def "change-requests changeRequestDetails" [
  changeRequestId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<rules: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/changeRequests/($changeRequestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a request details
#
# POST /changeRequests/{changeRequestId}
# operationId: updateChangeRequest
export def "change-requests updateChangeRequest" [
  changeRequestId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Change request description
  --name: string # Change request name
]: any -> record<action: string, data: record<rules: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/changeRequests/($changeRequestId)")
  let body = {description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Accept a request details
#
# POST /changeRequests/{changeRequestId}/accept
# operationId: acceptChangeRequest
export def "change-requests-accept acceptChangeRequest" [
  changeRequestId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # New status of the change request (e.g. deployed)
]: any -> record<action: string, data: record<rules: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/changeRequests/($changeRequestId)/accept")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Global compliance
#
# GET /compliance
# operationId: getGlobalCompliance
export def "compliance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --precision: int # Number of digits after comma in compliance percent figures (default: 2, e.g. 0)
]: nothing -> record<action: string, data: record<globalCompliance: record<compliance: float, complianceDetails: record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "precision" $precision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/compliance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Compliance details for all nodes
#
# GET /compliance/nodes
# operationId: getNodesCompliance
export def "compliance-nodes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: int # Number of depth level of compliance objects to display (1:rules, 2:directives, 3:components, 4:nodes, 5:values, 6:reports) (default: 10, e.g. 4)
  --precision: int # Number of digits after comma in compliance percent figures (default: 2, e.g. 0)
]: nothing -> record<action: string, data: record<nodes: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "level" $level "scalar") (serialize-qp "precision" $precision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/compliance/nodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Compliance details by node
#
# GET /compliance/nodes/{nodeId}
# operationId: getNodeCompliance
export def "compliance-nodes get" [
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: int # Number of depth level of compliance objects to display (1:rules, 2:directives, 3:components, 4:nodes, 5:values, 6:reports) (default: 10, e.g. 4)
  --precision: int # Number of digits after comma in compliance percent figures (default: 2, e.g. 0)
]: nothing -> record<action: string, data: record<nodes: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "level" $level "scalar") (serialize-qp "precision" $precision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/compliance/nodes/($nodeId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Compliance details for all rules
#
# GET /compliance/rules
# operationId: getRulesCompliance
export def "compliance-rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: int # Number of depth level of compliance objects to display (1:rules, 2:directives, 3:components, 4:nodes, 5:values, 6:reports) (default: 10, e.g. 4)
  --precision: int # Number of digits after comma in compliance percent figures (default: 2, e.g. 0)
]: nothing -> record<action: string, data: record<rules: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "level" $level "scalar") (serialize-qp "precision" $precision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/compliance/rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Compliance details by rule
#
# GET /compliance/rules/{ruleId}
# operationId: getRuleCompliance
export def "compliance-rules get" [
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: int # Number of depth level of compliance objects to display (1:rules, 2:directives, 3:components, 4:nodes, 5:values, 6:reports) (default: 10, e.g. 4)
  --precision: int # Number of digits after comma in compliance percent figures (default: 2, e.g. 0)
]: nothing -> record<action: string, data: record<rules: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "level" $level "scalar") (serialize-qp "precision" $precision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/compliance/rules/($ruleId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all CVE details
#
# GET /cve
# operationId: getAllCve
export def "cve get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<CVEs: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trigger a CVE check
#
# POST /cve/check
# operationId: checkCVE
export def "cve-check checkCVE" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<cveChecks: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cve/check")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CVE check config
#
# GET /cve/check/config
# operationId: getCVECheckConfiguration
export def "cve-check-config get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<apiKey: string, url: string>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cve/check/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update cve check config
#
# POST /cve/check/config
# operationId: updateCVECheckConfiguration
export def "cve-check-config updateCVECheckConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # Token used by to contact the API to check CVE
  --body-url: string # Url used to check CVE (e.g. https://api.rudder.io/cve/v1/)
]: any -> record<action: string, data: record<apiKey: string, url: string>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cve/check/config")
  let body = {apiKey: $apiKey, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get last CVE check result
#
# GET /cve/check/last
# operationId: getLastCVECheck
export def "cve-check-last get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<CVEChecks: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cve/check/last")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of CVE details
#
# POST /cve/list
# operationId: getCVEList
export def "cve-list post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cveIds: list
]: any -> record<action: string, data: record<CVEs: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cve/list")
  let body = {cveIds: $cveIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update CVE database from remote source
#
# POST /cve/update/
# operationId: updateCVE
export def "cve-update updateCVE" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string # Url used to update CVE, will default to one set in config (e.g. https://nvd.nist.gov/feeds/json/cve/1.1)
  --years: list
]: any -> record<action: string, data: record<CVEs: int>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cve/update/")
  let body = {url: $body_url, years: $years} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update CVE database from file system
#
# POST /cve/update/fs
# operationId: readCVEfromFS
export def "cve-update-fs readCVEfromFS" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<CVEs: int>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cve/update/fs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all data sources
#
# GET /datasources
# operationId: getAllDataSources
export def "datasources list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<datasources: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/datasources")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a data source
#
# PUT /datasources
# operationId: createDataSource
# --runParameters shape: {onGeneration?: bool, onNewNode?: bool, schedule?: record}
# --type shape: {name?: "HTTP", parameters?: record}
export def "datasources createDataSource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the goal of the data source to create. (e.g. Synchronize example data from the CMDB)
  --enabled: oneof<nothing, bool> # Enable or disable data source. (e.g. true)
  --id: string # Unique identifier of the data source to create. (e.g. test-data-source)
  --name: string # The human readable name of the data source to create. (e.g. Test data source)
  --runParameters: record # Parameters to configure when the data source is fetched to update node properties. — shape: {onGeneration?: bool, onNewNode?: bool, schedule?: record}
  --type: record # Define and configure data source type. — shape: {name?: "HTTP", parameters?: record}
  --updateTimeout: int # Duration in seconds before aborting data source update. The main goal is to prevent never ending requests. If a periodicity if configured, you should set that timeout at a lower value. (e.g. 30)
]: any -> record<action: string, data: record<datasources: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/datasources")
  let body = {description: $description, enabled: $enabled, id: $id, name: $name, runParameters: $runParameters, type: $type, updateTimeout: $updateTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update properties from data sources
#
# POST /datasources/reload
# operationId: ReloadAllDatasourcesAllNodes
export def "datasources-reload ReloadAllDatasourcesAllNodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: string, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/datasources/reload")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update properties from data sources
#
# POST /datasources/reload/{datasourceId}
# operationId: ReloadOneDatasourceAllNodes
export def "datasources-reload ReloadOneDatasourceAllNodes" [
  datasourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: string, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/datasources/reload/($datasourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a data source
#
# DELETE /datasources/{datasourceId}
# operationId: deleteDataSource
export def "datasources delete" [
  datasourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<datasources: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/datasources/($datasourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get data source configuration
#
# GET /datasources/{datasourceId}
# operationId: getDataSource
export def "datasources get" [
  datasourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<datasources: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/datasources/($datasourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a data source configuration
#
# POST /datasources/{datasourceId}
# operationId: updateDataSource
# --runParameters shape: {onGeneration?: bool, onNewNode?: bool, schedule?: record}
# --type shape: {name?: "HTTP", parameters?: record}
export def "datasources updateDataSource" [
  datasourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the goal of the data source to create. (e.g. Synchronize example data from the CMDB)
  --enabled: oneof<nothing, bool> # Enable or disable data source. (e.g. true)
  --id: string # Unique identifier of the data source to create. (e.g. test-data-source)
  --name: string # The human readable name of the data source to create. (e.g. Test data source)
  --runParameters: record # Parameters to configure when the data source is fetched to update node properties. — shape: {onGeneration?: bool, onNewNode?: bool, schedule?: record}
  --type: record # Define and configure data source type. — shape: {name?: "HTTP", parameters?: record}
  --updateTimeout: int # Duration in seconds before aborting data source update. The main goal is to prevent never ending requests. If a periodicity if configured, you should set that timeout at a lower value. (e.g. 30)
]: any -> record<action: string, data: record<datasources: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/datasources/($datasourceId)")
  let body = {description: $description, enabled: $enabled, id: $id, name: $name, runParameters: $runParameters, type: $type, updateTimeout: $updateTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all directives
#
# GET /directives
# operationId: listDirectives
export def "directives listDirectives" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<directives: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/directives")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a directive
#
# PUT /directives
# operationId: createDirective
# --tags item shape: {name?: string}
export def "directives createDirective" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string # Human readable name of the directive (e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --enabled: oneof<nothing, bool> # Is the directive enabled (e.g. true)
  --id: string # Directive id (format: uuid, e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --longDescription: string # Description of the technique (rendered as markdown) (format: markdown, e.g. # Documentation * [Ticket link](https://tickets.example.com/issues/3456))
  --parameters: record # Directive parameters (depends on the source technique) (e.g. {name: sections, sections: [{section: {name: File to manage, sections: [{section: {name: File, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_PATH, value: /root/test}}]}}, {section: {name: File cleaning options, vars: [{var: {name: FILE_AND_FOLDER_DELETION_DAYS, value: 0}}, {var: {name: FILE_AND_FOLDER_DELETION_OPTION, value: none}}, {var: {name: FILE_AND_FOLDER_DELETION_PATTERN, value: .*}}]}}, {section: {name: Permissions, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_CHECK_PERMISSIONS, value: false}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_GROUP, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_OWNER, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_PERM, value: 000}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_RECURSIVE, value: 1}}]}}, {section: {name: Post-modification hook, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_COMMAND, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_RUN, value: false}}]}}], vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_ACTION, value: copy}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_SOURCE, value: /vagrant/node.sh}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_SYMLINK_ENFORCE, value: false}}]}}]})
  --priority: int # Directive priority. `0` has highest priority. (e.g. 5)
  --shortDescription: string # One line directive description (e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --body-source: string # The id of the directive the clone will be based onto. If this parameter if provided,  the new directive will be a clone of this source. Other value will override values from the source. (format: uuid, e.g. b9f6d98a-28bc-4d80-90f7-d2f14269e215)
  --system: oneof<nothing, bool> # If true it is an internal Rudder directive (e.g. false)
  --tags: list # item shape: {name?: string}
  --techniqueName: string # Directive id (e.g. userManagement)
  --techniqueVersion: string # Directive id (e.g. 8.0)
]: any -> record<action: string, data: record<directives: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/directives")
  let body = {displayName: $displayName, enabled: $enabled, id: $id, longDescription: $longDescription, parameters: $parameters, priority: $priority, shortDescription: $shortDescription, source: $body_source, system: $system, tags: $tags, techniqueName: $techniqueName, techniqueVersion: $techniqueVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a directive
#
# DELETE /directives/{directiveId}
# operationId: deleteDirective
export def "directives delete" [
  directiveId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<directives: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/directives/($directiveId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get directive details
#
# GET /directives/{directiveId}
# operationId: directiveDetails
export def "directives directiveDetails" [
  directiveId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<directives: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/directives/($directiveId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a directive details
#
# POST /directives/{directiveId}
# operationId: updateDirective
# --tags item shape: {name?: string}
export def "directives updateDirective" [
  directiveId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string # Human readable name of the directive (e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --enabled: oneof<nothing, bool> # Is the directive enabled (e.g. true)
  --id: string # Directive id (format: uuid, e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --longDescription: string # Description of the technique (rendered as markdown) (format: markdown, e.g. # Documentation * [Ticket link](https://tickets.example.com/issues/3456))
  --parameters: record # Directive parameters (depends on the source technique) (e.g. {name: sections, sections: [{section: {name: File to manage, sections: [{section: {name: File, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_PATH, value: /root/test}}]}}, {section: {name: File cleaning options, vars: [{var: {name: FILE_AND_FOLDER_DELETION_DAYS, value: 0}}, {var: {name: FILE_AND_FOLDER_DELETION_OPTION, value: none}}, {var: {name: FILE_AND_FOLDER_DELETION_PATTERN, value: .*}}]}}, {section: {name: Permissions, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_CHECK_PERMISSIONS, value: false}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_GROUP, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_OWNER, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_PERM, value: 000}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_RECURSIVE, value: 1}}]}}, {section: {name: Post-modification hook, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_COMMAND, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_RUN, value: false}}]}}], vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_ACTION, value: copy}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_SOURCE, value: /vagrant/node.sh}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_SYMLINK_ENFORCE, value: false}}]}}]})
  --policyMode: string@policyMode-completer # Policy mode of the directive (e.g. audit)
  --priority: int # Directive priority. `0` has highest priority. (e.g. 5)
  --shortDescription: string # One line directive description (e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --system: oneof<nothing, bool> # If true it is an internal Rudder directive (e.g. false)
  --tags: list # item shape: {name?: string}
  --techniqueName: string # Directive id (e.g. userManagement)
  --techniqueVersion: string # Directive id (e.g. 8.0)
]: any -> record<action: string, data: record<directives: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/directives/($directiveId)")
  let body = {displayName: $displayName, enabled: $enabled, id: $id, longDescription: $longDescription, parameters: $parameters, policyMode: $policyMode, priority: $priority, shortDescription: $shortDescription, system: $system, tags: $tags, techniqueName: $techniqueName, techniqueVersion: $techniqueVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Check that update on a directive is valid
#
# POST /directives/{directiveId}/check
# operationId: checkDirective
# --tags item shape: {name?: string}
export def "directives-check checkDirective" [
  directiveId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string # Human readable name of the directive (e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --enabled: oneof<nothing, bool> # Is the directive enabled (e.g. true)
  --id: string # Directive id (format: uuid, e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --longDescription: string # Description of the technique (rendered as markdown) (format: markdown, e.g. # Documentation * [Ticket link](https://tickets.example.com/issues/3456))
  --parameters: record # Directive parameters (depends on the source technique) (e.g. {name: sections, sections: [{section: {name: File to manage, sections: [{section: {name: File, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_PATH, value: /root/test}}]}}, {section: {name: File cleaning options, vars: [{var: {name: FILE_AND_FOLDER_DELETION_DAYS, value: 0}}, {var: {name: FILE_AND_FOLDER_DELETION_OPTION, value: none}}, {var: {name: FILE_AND_FOLDER_DELETION_PATTERN, value: .*}}]}}, {section: {name: Permissions, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_CHECK_PERMISSIONS, value: false}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_GROUP, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_OWNER, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_PERM, value: 000}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_RECURSIVE, value: 1}}]}}, {section: {name: Post-modification hook, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_COMMAND, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_RUN, value: false}}]}}], vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_ACTION, value: copy}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_SOURCE, value: /vagrant/node.sh}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_SYMLINK_ENFORCE, value: false}}]}}]})
  --policyMode: string@policyMode-completer # Policy mode of the directive (e.g. audit)
  --priority: int # Directive priority. `0` has highest priority. (e.g. 5)
  --shortDescription: string # One line directive description (e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --system: oneof<nothing, bool> # If true it is an internal Rudder directive (e.g. false)
  --tags: list # item shape: {name?: string}
  --techniqueName: string # Directive id (e.g. userManagement)
  --techniqueVersion: string # Directive id (e.g. 8.0)
]: any -> record<action: string, data: record<directives: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/directives/($directiveId)/check")
  let body = {displayName: $displayName, enabled: $enabled, id: $id, longDescription: $longDescription, parameters: $parameters, policyMode: $policyMode, priority: $priority, shortDescription: $shortDescription, system: $system, tags: $tags, techniqueName: $techniqueName, techniqueVersion: $techniqueVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all groups
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<groups: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a group
#
# PUT /groups
# operationId: createGroup
# --properties item shape: {name: string, value: any}
# --query shape: {composition?: "and"|"or", select?: string, where?: list}
export def "groups createGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  category: string # Id of the new group's category (format: uuid, e.g. e17ecf6a-a9f2-44de-a97c-116d24d30ff4)
  --description: string # Group description (e.g. Documentation for the group)
  displayName: string # Name of the group (e.g. Ubuntu 18.04 nodes)
  --dynamic: oneof<nothing, bool> # Should the group be dynamically refreshed (if not, it is a static group) (default: true)
  --enabled: oneof<nothing, bool> # Enable or disable the group (default: true)
  --id: string # Group id, only provide it when needed. (format: uuid, default: {autogenerated}, e.g. 32d013f7-b6d8-46c8-99d3-016307fa66c0)
  --properties: list # Group properties — item shape: {name: string, value: any}
  --body-query: record # The criteria defining the group. If not provided, the group will be empty. — shape: {composition?: "and"|"or", select?: string, where?: list}
  --body-source: string # The id of the group the clone will be based onto. If this parameter if provided,  the new group will be a clone of this source. Other value will override values from the source. (format: uuid, e.g. b9f6d98a-28bc-4d80-90f7-d2f14269e215)
]: any -> record<action: string, data: record<groups: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups")
  let body = {category: $category, description: $description, displayName: $displayName, dynamic: $dynamic, enabled: $enabled, id: $id, properties: $properties, query: $body_query, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a group category
#
# PUT /groups/categories
# operationId: CreateGroupCategory
export def "groups-categories CreateGroupCategory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Group category description (e.g. Nodes by hardware provider)
  --id: string # Group category id, only provide it when needed. (format: uuid, default: {autogenerated}, e.g. 32d013f7-b6d8-46c8-99d3-016307fa66c0)
  name: string # Name of the group category (e.g. Hardware groups)
  parent: string # The parent category of the groups (format: uuid, e.g. b9f6d98a-28bc-4d80-90f7-d2f14269e215)
]: any -> record<action: string, data: record<groupCategories: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups/categories")
  let body = {description: $description, id: $id, name: $name, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete group category
#
# DELETE /groups/categories/{groupCategoryId}
# operationId: DeleteGroupCategory
export def "groups-categories DeleteGroupCategory" [
  groupCategoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<groupCategories: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/categories/($groupCategoryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get group category details
#
# GET /groups/categories/{groupCategoryId}
# operationId: GetGroupCategoryDetails
export def "groups-categories GetGroupCategoryDetails" [
  groupCategoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<groupCategories: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/categories/($groupCategoryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update group category details
#
# POST /groups/categories/{groupCategoryId}
# operationId: UpdateGroupCategory
export def "groups-categories UpdateGroupCategory" [
  groupCategoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Group category description (e.g. Nodes by hardware provider)
  name: string # Name of the group category (e.g. Hardware groups)
  parent: string # The parent category of the groups (format: uuid, e.g. b9f6d98a-28bc-4d80-90f7-d2f14269e215)
]: any -> record<action: string, data: record<groupCategories: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/categories/($groupCategoryId)")
  let body = {description: $description, name: $name, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get groups tree
#
# GET /groups/tree
# operationId: GetGroupTree
export def "groups-tree GetGroupTree" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<groupCategories: record>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups/tree")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a group
#
# DELETE /groups/{groupId}
# operationId: deleteGroup
export def "groups delete" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<groups: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($groupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get group details
#
# GET /groups/{groupId}
# operationId: groupDetails
export def "groups groupDetails" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<groups: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($groupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update group details
#
# POST /groups/{groupId}
# operationId: updateGroup
# --query shape: {composition?: "and"|"or", select?: string, where?: list}
export def "groups updateGroup" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string # Id of the new group's category (format: uuid, e.g. e17ecf6a-a9f2-44de-a97c-116d24d30ff4)
  --description: string # Group description (e.g. Documentation for the group)
  --displayName: string # Name of the group (e.g. Ubuntu 18.04 nodes)
  --dynamic: oneof<nothing, bool> # Should the group be dynamically refreshed (if not, it is a static group) (default: true)
  --enabled: oneof<nothing, bool> # Enable or disable the group (default: true)
  --body-query: record # The criteria defining the group. If not provided, the group will be empty. — shape: {composition?: "and"|"or", select?: string, where?: list}
]: any -> record<action: string, data: record<groups: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($groupId)")
  let body = {category: $category, description: $description, displayName: $displayName, dynamic: $dynamic, enabled: $enabled, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reload a group
#
# POST /groups/{groupId}/reload
# operationId: reloadGroup
export def "groups-reload reloadGroup" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<groups: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($groupId)/reload")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all endoints
#
# GET /info
# operationId: apiGeneralInformations
export def "info apiGeneralInformations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<availableVersions: list<record>, documentation: string, endpoints: list<list>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about one API endpoint
#
# GET /info/details/{endpointName}
# operationId: apiInformations
export def "info-details apiInformations" [
  endpointName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<documentation: string, endpointName: string, endpoints: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/info/details/($endpointName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information on endpoint in a section
#
# GET /info/{sectionId}
# operationId: apiSubInformations
export def "info apiSubInformations" [
  sectionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<availableVersions: list<record>, documentation: string, endpoints: list<list>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/info/($sectionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about inventory processing queue
#
# GET /inventories/info
# operationId: queueInformation
export def "inventories-info queueInformation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<queueMaxSize: int, queueSaturated: bool>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/inventories/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload an inventory for processing
#
# POST /inventories/upload
# operationId: uploadInventory
export def "inventories-upload uploadInventory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # The inventory file. The original file name is used to check extension, that should be .xml[.gz] or .ocs[.gz] (format: binary)
  --signature: string # The signature file. The original file name is used to check extension, that should be ${originalInventoryFileName}.sign[.gz] (format: binary)
]: any -> record<action: string, data: string, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/inventories/upload")
  let body = {file: $file, signature: $signature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Restart inventory watcher
#
# POST /inventories/watcher/restart
# operationId: fileWatcherRestart
export def "inventories-watcher-restart fileWatcherRestart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: string, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/inventories/watcher/restart")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start inventory watcher
#
# POST /inventories/watcher/start
# operationId: fileWatcherStart
export def "inventories-watcher-start fileWatcherStart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: string, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/inventories/watcher/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop inventory watcher
#
# POST /inventories/watcher/stop
# operationId: fileWatcherStop
export def "inventories-watcher-stop fileWatcherStop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: string, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/inventories/watcher/stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List methods
#
# GET /methods
# operationId: methods
export def "methods methods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<methods: record<agents: list, category: string, condition: record, deprecated: record, desc: string, documentation: string, id: string, name: string, parameters: list, version: string>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/methods")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reload methods
#
# POST /methods/reload
# operationId: reloadMethods
export def "methods-reload reloadMethods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<methods: record<agents: list, category: string, condition: record, deprecated: record, desc: string, documentation: string, id: string, name: string, parameters: list, version: string>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/methods/reload")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List managed nodes
#
# GET /nodes
# operationId: listAcceptedNodes
export def "nodes listAcceptedNodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # Level of information to include from the node inventory. Some base levels are defined (**minimal**, **default**, **full**). You can add fields you want to a base level by adding them to the list, possible values are keys from json answer. If you don't provide a base level, they will be added to `default` level, so if you only want os details, use `minimal,os` as the value for this parameter. * **minimal** includes: `id`, `hostname` and `status` * **default** includes **minimal** plus `architectureDescription`, `description`, `ipAddresses`, `lastRunDate`, `lastInventoryDate`, `machine`, `os`, `managementTechnology`, `policyServerId`, `properties` (be careful! Only node own properties, if you also need inherited properties, look at the dedicated `/nodes/{id}/inheritedProperties` endpoint), `policyMode `, `ram` and `timezone` * **full** includes: **default** plus `accounts`, `bios`, `controllers`, `environmentVariables`, `fileSystems`, `managementTechnologyDetails`, `memories`, `networkInterfaces`, `ports`, `processes`, `processors`, `slots`, `software`, `sound`, `storage`, `videos` and `virtualMachines` (format: comma-separated list, default: default, e.g. minimal)
  --qp-query: string # The criterion you want to find for your nodes. Replaces the `where`, `composition` and `select` parameters in a single parameter.
  --qp-where: string # The criterion you want to find for your nodes
  --composition: string@composition-completer # Boolean operator to use between each  `where` criteria. (default: and, e.g. and)
  --select: string # What kind of data we want to include. Here we can get policy servers/relay by setting `nodeAndPolicyServer`. Only used if `where` is defined. (default: node)
]: nothing -> record<action: string, data: record<nodes: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "where" $qp_where "scalar") (serialize-qp "composition" $composition "scalar") (serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create one or several new nodes
#
# PUT /nodes
# operationId: createNodes
export def "nodes createNodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<action: string, data: record<created: list<string>, failed: list<string>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/nodes")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Trigger an agent run on all nodes
#
# POST /nodes/applyPolicy
# operationId: applyPolicyAllNodes
export def "nodes-apply-policy applyPolicyAllNodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: table<hostname: string, id: string, result: string>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/nodes/applyPolicy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List pending nodes
#
# GET /nodes/pending
# operationId: listPendingNodes
export def "nodes-pending listPendingNodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # Level of information to include from the node inventory. Some base levels are defined (**minimal**, **default**, **full**). You can add fields you want to a base level by adding them to the list, possible values are keys from json answer. If you don't provide a base level, they will be added to `default` level, so if you only want os details, use `minimal,os` as the value for this parameter. * **minimal** includes: `id`, `hostname` and `status` * **default** includes **minimal** plus `architectureDescription`, `description`, `ipAddresses`, `lastRunDate`, `lastInventoryDate`, `machine`, `os`, `managementTechnology`, `policyServerId`, `properties` (be careful! Only node own properties, if you also need inherited properties, look at the dedicated `/nodes/{id}/inheritedProperties` endpoint), `policyMode `, `ram` and `timezone` * **full** includes: **default** plus `accounts`, `bios`, `controllers`, `environmentVariables`, `fileSystems`, `managementTechnologyDetails`, `memories`, `networkInterfaces`, `ports`, `processes`, `processors`, `slots`, `software`, `sound`, `storage`, `videos` and `virtualMachines` (format: comma-separated list, default: default, e.g. minimal)
  --qp-query: string # The criterion you want to find for your nodes. Replaces the `where`, `composition` and `select` parameters in a single parameter.
  --qp-where: string # The criterion you want to find for your nodes
  --composition: string@composition-completer # Boolean operator to use between each  `where` criteria. (default: and, e.g. and)
  --select: string # What kind of data we want to include. Here we can get policy servers/relay by setting `nodeAndPolicyServer`. Only used if `where` is defined. (default: node)
]: nothing -> record<action: string, data: record<nodes: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "where" $qp_where "scalar") (serialize-qp "composition" $composition "scalar") (serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nodes/pending" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update pending Node status
#
# POST /nodes/pending/{nodeId}
# operationId: changePendingNodeStatus
export def "nodes-pending changePendingNodeStatus" [
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # New status of the pending node (e.g. accepted)
]: any -> record<action: string, data: record<nodes: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/nodes/pending/($nodeId)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get nodes acceptation status
#
# GET /nodes/status
# operationId: getNodesStatus
export def "nodes-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # Comma separated list of node Ids (format: comma-separated list, default: default, e.g. 8403353b-42c4-46f5-a08d-bc77a1a0bad9,root)
]: nothing -> record<action: string, data: record<nodes: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nodes/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a node
#
# DELETE /nodes/{nodeId}
# operationId: deleteNode
export def "nodes delete" [
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mode: string@mode-completer # Deletion mode to use, either move to trash ('move', default) or erase ('erase') (default: move, e.g. move)
]: nothing -> record<action: string, data: record<nodes: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mode" $mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nodes/($nodeId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about a node
#
# GET /nodes/{nodeId}
# operationId: nodeDetails
export def "nodes nodeDetails" [
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # Level of information to include from the node inventory. Some base levels are defined (**minimal**, **default**, **full**). You can add fields you want to a base level by adding them to the list, possible values are keys from json answer. If you don't provide a base level, they will be added to `default` level, so if you only want os details, use `minimal,os` as the value for this parameter. * **minimal** includes: `id`, `hostname` and `status` * **default** includes **minimal** plus `architectureDescription`, `description`, `ipAddresses`, `lastRunDate`, `lastInventoryDate`, `machine`, `os`, `managementTechnology`, `policyServerId`, `properties` (be careful! Only node own properties, if you also need inherited properties, look at the dedicated `/nodes/{id}/inheritedProperties` endpoint), `policyMode `, `ram` and `timezone` * **full** includes: **default** plus `accounts`, `bios`, `controllers`, `environmentVariables`, `fileSystems`, `managementTechnologyDetails`, `memories`, `networkInterfaces`, `ports`, `processes`, `processors`, `slots`, `software`, `sound`, `storage`, `videos` and `virtualMachines` (format: comma-separated list, default: default, e.g. minimal)
]: nothing -> record<action: string, data: record<nodes: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nodes/($nodeId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update node settings and properties
#
# POST /nodes/{nodeId}
# operationId: updateNode
# --agentKey shape: {status?: "certified"|"undefined", value: string}
# --properties item shape: {name: string, value: any}
export def "nodes updateNode" [
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --agentKey: record # Information about agent key or certificate — shape: {status?: "certified"|"undefined", value: string}
  --policyMode: string@policyMode-completer-1 # In which mode the node will apply its configuration policy. Use `default` to use the global mode. (e.g. audit)
  --properties: list # item shape: {name: string, value: any}
  --state: string@state-completer # The node life cycle state. See [dedicated doc](https://docs.rudder.io/reference/current/usage/advanced_node_management.html#node-lifecycle) for more information. (e.g. enabled)
]: any -> record<action: string, data: record<nodes: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/nodes/($nodeId)")
  let body = {agentKey: $agentKey, policyMode: $policyMode, properties: $properties, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Trigger an agent run
#
# POST /nodes/{nodeId}/applyPolicy
# operationId: applyNode
export def "nodes-apply-policy applyNode" [
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/nodes/($nodeId)/applyPolicy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update properties for one node from all data sources
#
# POST /nodes/{nodeId}/fetchData
# operationId: ReloadAllDatasourcesOneNode
export def "nodes-fetch-data ReloadAllDatasourcesOneNode" [
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: string, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/nodes/($nodeId)/fetchData")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update properties for one node from a data source
#
# POST /nodes/{nodeId}/fetchData/{datasourceId}
# operationId: ReloadOneDatasourceOneNode
export def "nodes-fetch-data ReloadOneDatasourceOneNode" [
  nodeId: string
  datasourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: string, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/nodes/($nodeId)/fetchData/($datasourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get inherited node properties for a node
#
# GET /nodes/{nodeId}/inheritedProperties
# operationId: nodeInheritedProperties
export def "nodes-inherited-properties nodeInheritedProperties" [
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: table<id: string, properties: list>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/nodes/($nodeId)/inheritedProperties")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all global parameters
#
# GET /parameters
# operationId: listParameters
export def "parameters listParameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<parameters: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/parameters")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new parameter
#
# PUT /parameters
# operationId: createParameter
export def "parameters createParameter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the parameter (e.g. Default inform message put in footer of managed files by Rudder)
  id: string # Name of the parameter (e.g. rudder_file_edit_footer)
  --overridable: oneof<nothing, bool> # Is the global parameter overridable by node (e.g. false)
  --value: any # Value of the parameter (format: string or JSON, e.g. ### End of file managed by Rudder ###)
]: any -> record<action: string, data: record<parameters: list<record>>, id: string, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/parameters")
  let body = {description: $description, id: $id, overridable: $overridable, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a parameter
#
# DELETE /parameters/{parameterId}
# operationId: deleteParameter
export def "parameters delete" [
  parameterId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<parameters: list<record>>, id: string, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/parameters/($parameterId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the value of a parameter
#
# GET /parameters/{parameterId}
# operationId: parameterDetails
export def "parameters parameterDetails" [
  parameterId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<parameters: list<record>>, id: string, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/parameters/($parameterId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a parameter's value
#
# POST /parameters/{parameterId}
# operationId: updateParameter
export def "parameters updateParameter" [
  parameterId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<parameters: list<record>>, id: string, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/parameters/($parameterId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all rules
#
# GET /rules
# operationId: listRules
export def "rules listRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<rules: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a rule
#
# PUT /rules
# operationId: createRule
# --tags item shape: {name?: string}
# --targets item shape: {exclude: record, include: record}
export def "rules createRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string # The parent category id. If provided, the new rule will be in this parent category (format: uuid, e.g. 38e0c6ea-917f-47b8-82e0-e6a1d3dd62ca)
  --directives: list # Directives linked to the rule
  --displayName: string # Rule name (e.g. Security policy)
  --enabled: oneof<nothing, bool> # Is the rule enabled (e.g. true)
  --id: string # Rule id (format: uuid, e.g. 0c1713ae-cb9d-4f7b-abda-ca38c5d643ea)
  --longDescription: string # Rule documentation (e.g. This rules should be applied to all Linux nodes required basic hardening)
  --shortDescription: string # One line rule description (e.g. Baseline applying CIS guidelines)
  --body-source: string # The id of the rule the clone will be based onto. If this parameter if provided, the new rule will be a clone of this source. Other value will override values from the source. (format: uuid, e.g. b9f6d98a-28bc-4d80-90f7-d2f14269e215)
  --system: oneof<nothing, bool> # If true it is an internal Rudder rule (e.g. false)
  --tags: list # item shape: {name?: string}
  --targets: list # Node and special groups targeted by that rule — item shape: {exclude: record, include: record}
]: any -> record<action: string, data: record<rules: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rules")
  let body = {category: $category, directives: $directives, displayName: $displayName, enabled: $enabled, id: $id, longDescription: $longDescription, shortDescription: $shortDescription, source: $body_source, system: $system, tags: $tags, targets: $targets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a rule category
#
# PUT /rules/categories
# operationId: CreateRuleCategory
export def "rules-categories CreateRuleCategory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Rules category description (e.g. Baseline applying CIS guidelines)
  --id: string # Rule category id, only provide it when needed. (format: uuid, default: {autogenerated}, e.g. 32d013f7-b6d8-46c8-99d3-016307fa66c0)
  name: string # Name of the rule category (e.g. Security policies)
  parent: string # The parent category of the rules (format: uuid, e.g. b9f6d98a-28bc-4d80-90f7-d2f14269e215)
]: any -> record<action: string, data: record<ruleCategories: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rules/categories")
  let body = {description: $description, id: $id, name: $name, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete group category
#
# DELETE /rules/categories/{ruleCategoryId}
# operationId: DeleteRuleCategory
export def "rules-categories DeleteRuleCategory" [
  ruleCategoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<groupCategories: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rules/categories/($ruleCategoryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get rule category details
#
# GET /rules/categories/{ruleCategoryId}
# operationId: GetRuleCategoryDetails
export def "rules-categories GetRuleCategoryDetails" [
  ruleCategoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<rulesCategories: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rules/categories/($ruleCategoryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update rule category details
#
# POST /rules/categories/{ruleCategoryId}
# operationId: UpdateRuleCategory
export def "rules-categories UpdateRuleCategory" [
  ruleCategoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Rules category description (e.g. Baseline applying CIS guidelines)
  name: string # Name of the rule category (e.g. Security policies)
  parent: string # The parent category of the rules (format: uuid, e.g. b9f6d98a-28bc-4d80-90f7-d2f14269e215)
]: any -> record<action: string, data: record<ruleCategories: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rules/categories/($ruleCategoryId)")
  let body = {description: $description, name: $name, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get rules tree
#
# GET /rules/tree
# operationId: GetRuleTree
export def "rules-tree GetRuleTree" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<ruleCategories: record>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rules/tree")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a rule
#
# DELETE /rules/{ruleId}
# operationId: deleteRule
export def "rules delete" [
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<rules: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rules/($ruleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a rule details
#
# GET /rules/{ruleId}
# operationId: ruleDetails
export def "rules ruleDetails" [
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<rules: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rules/($ruleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a rule details
#
# POST /rules/{ruleId}
# operationId: updateRule
# --tags item shape: {name?: string}
# --targets item shape: {exclude: record, include: record}
export def "rules updateRule" [
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string # The parent category id. (format: uuid, e.g. 38e0c6ea-917f-47b8-82e0-e6a1d3dd62ca)
  --directives: list # Directives linked to the rule
  --displayName: string # Rule name (e.g. Security policy)
  --enabled: oneof<nothing, bool> # Is the rule enabled (e.g. true)
  --id: string # Rule id (format: uuid, e.g. 0c1713ae-cb9d-4f7b-abda-ca38c5d643ea)
  --longDescription: string # Rule documentation (e.g. This rules should be applied to all Linux nodes required basic hardening)
  --shortDescription: string # One line rule description (e.g. Baseline applying CIS guidelines)
  --system: oneof<nothing, bool> # If true it is an internal Rudder rule (e.g. false)
  --tags: list # item shape: {name?: string}
  --targets: list # Node and special groups targeted by that rule — item shape: {exclude: record, include: record}
]: any -> record<action: string, data: record<rules: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rules/($ruleId)")
  let body = {category: $category, directives: $directives, displayName: $displayName, enabled: $enabled, id: $id, longDescription: $longDescription, shortDescription: $shortDescription, system: $system, tags: $tags, targets: $targets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Demote a relay to simple node
#
# POST /scaleoutrelay/demote/{nodeId}
# operationId: demoteToNode
export def "scaleoutrelay-demote demoteToNode" [
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: string, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scaleoutrelay/demote/($nodeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Promote a node to relay
#
# POST /scaleoutrelay/promote/{nodeId}
# operationId: promoteToRelay
export def "scaleoutrelay-promote promoteToRelay" [
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: string, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scaleoutrelay/promote/($nodeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all secrets
#
# GET /secret/
# operationId: getAllSecrets
export def "secret list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<secrets: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/secret/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a secret
#
# POST /secret/
# operationId: updateSecret
export def "secret updateSecret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the secret to identify it more easily (e.g. Password of my super secret user account)
  --name: string # The name of the secret used as a reference on the value (e.g. secret-password)
  --value: string # The value of the secret it will not be exposed in the interface (e.g. nj-k;EO32!kFWewn2Nk,u)
]: any -> record<action: string, data: record<secrets: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/secret/")
  let body = {description: $description, name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a secret
#
# PUT /secret/
# operationId: addSecret
export def "secret addSecret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the secret to identify it more easily (e.g. Password of my super secret user account)
  --name: string # The name of the secret used as a reference on the value (e.g. secret-password)
  --value: string # The value of the secret it will not be exposed in the interface (e.g. nj-k;EO32!kFWewn2Nk,u)
]: any -> record<action: string, data: record<secrets: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/secret/")
  let body = {description: $description, name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a secret
#
# DELETE /secret/{name}
# operationId: deleteSecret
export def "secret delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<secrets: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/secret/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get one secret
#
# GET /secret/{name}
# operationId: getSecret
export def "secret get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<secrets: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/secret/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all settings
#
# GET /settings
# operationId: getAllSettings
export def "settings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<settings: record<allowed_networks: list, change_message_prompt: string, display_recent_changes_graphs: bool, enable_change_message: bool, enable_change_request: bool, enable_javascript_directives: string, enable_self_deployment: bool, enable_self_validation: bool, first_run_hour: int, first_run_minute: int, global_policy_mode: string, global_policy_mode_overridable: bool, heartbeat_frequency: int, mandatory_change_message: bool, modified_file_ttl: int, node_accept_duplicated_hostname: bool, node_onaccept_default_policyMode: string, node_onaccept_default_state: string, output_file_ttl: int, relay_server_synchronization_method: string, relay_server_synchronize_policies: bool, relay_server_synchronize_shared_files: bool, reporting_mode: string, require_time_synchronization: bool, rudder_compute_changes: bool, rudder_compute_dyngroups_max_parallelism: string, rudder_generation_compute_dyngroups: bool, rudder_generation_continue_on_error: bool, rudder_generation_delay: string, rudder_generation_js_timeout: int, rudder_generation_max_parallelism: string, rudder_generation_policy: string, rudder_report_protocol_default: string, rudder_save_db_compliance_details: bool, rudder_save_db_compliance_levels: bool, rudder_verify_certificates: bool, run_frequency: int, send_metrics: string, splay_time: int, unexpected_unbound_var_values: bool>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get allowed networks for a policy server
#
# GET /settings/allowed_networks/{nodeId}
# operationId: getAllowedNetworks
export def "settings-allowed-networks get" [
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<settings: record<allowed_networks: list>>, id: string, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/settings/allowed_networks/($nodeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set allowed networks for a policy server
#
# POST /settings/allowed_networks/{nodeId}
# operationId: setAllowedNetworks
export def "settings-allowed-networks setAllowedNetworks" [
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: record # New value of the allowed networks (e.g. enforce)
]: any -> record<action: string, data: record<allowed_networks: list<any>>, id: string, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/settings/allowed_networks/($nodeId)")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Modify allowed networks for a policy server
#
# POST /settings/allowed_networks/{nodeId}/diff
# operationId: modifyAllowedNetworks
# --allowed_networks shape: {add?: list, delete?: list}
export def "settings-allowed-networks-diff modifyAllowedNetworks" [
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-networks: record # shape: {add?: list, delete?: list}
]: any -> record<action: string, data: record<allowed_networks: list<any>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/settings/allowed_networks/($nodeId)/diff")
  let body = {allowed_networks: $allowed_networks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the value of a setting
#
# GET /settings/{settingId}
# operationId: getSetting
export def "settings get" [
  settingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<settingId: string>, id: string, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/settings/($settingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set the value of a setting
#
# POST /settings/{settingId}
# operationId: modifySetting
export def "settings modifySetting" [
  settingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # New value of the setting (e.g. enforce)
]: any -> record<action: string, data: record<settingId: string>, id: string, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/settings/($settingId)")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Check if Rudder is alive
#
# GET /status
# operationId: none
export def "status none" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/status")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List archives
#
# GET /system/archives/{archiveKind}
# operationId: listArchives
export def "system-archives listArchives" [
  archiveKind: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<full: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/system/archives/($archiveKind)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an archive
#
# POST /system/archives/{archiveKind}
# operationId: createArchive
export def "system-archives createArchive" [
  archiveKind: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<full: record<commiter: string, gitCommit: string, id: string>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/system/archives/($archiveKind)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restore an archive
#
# POST /system/archives/{archiveKind}/restore/{archiveRestoreKind}
# operationId: restoreArchive
export def "system-archives-restore restoreArchive" [
  archiveKind: string
  archiveRestoreKind: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<directive: string, full: string, groups: string, parameters: string, rules: string>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/system/archives/($archiveKind)/restore/($archiveRestoreKind)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an archive as a ZIP
#
# GET /system/archives/{archiveKind}/zip/{commitId}
# operationId: getZipArchive
export def "system-archives-zip get" [
  archiveKind: string
  commitId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/system/archives/($archiveKind)/zip/($commitId)")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get healthcheck
#
# GET /system/healthcheck
# operationId: getHealthcheckResult
export def "system-healthcheck get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: table<msg: string, name: string, status: string>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/healthcheck")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get server information
#
# GET /system/info
# operationId: getSystemInfo
export def "system-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<rudder: record<build_time: string, full_version: string, major_version: string>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trigger batch for cleaning unreferenced software
#
# POST /system/maintenance/purgeSoftware
# operationId: purgeSoftware
export def "system-maintenance-purge-software purgeSoftware" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: list<string>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/maintenance/purgeSoftware")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trigger a new policy generation
#
# POST /system/regenerate/policies
# operationId: regeneratePolicies
export def "system-regenerate-policies regeneratePolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<policies: string>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/regenerate/policies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reload both techniques and dynamic groups
#
# POST /system/reload
# operationId: reloadAll
export def "system-reload reloadAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<groups: string, techniques: string>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/reload")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reload dynamic groups
#
# POST /system/reload/groups
# operationId: reloadGroups
export def "system-reload-groups reloadGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<groups: string>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/reload/groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reload techniques
#
# POST /system/reload/techniques
# operationId: reloadTechniques
export def "system-reload-techniques reloadTechniques" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<techniques: string>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/reload/techniques")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get server status
#
# GET /system/status
# operationId: getStatus
export def "system-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<global: string>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trigger update of policies
#
# POST /system/update/policies
# operationId: updatePolicies
export def "system-update-policies updatePolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<policies: string>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/update/policies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all techniques
#
# GET /techniques
# operationId: listTechniques
export def "techniques listTechniques" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<techniques: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/techniques")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create technique
#
# PUT /techniques
# operationId: CreateTechnique
export def "techniques CreateTechnique" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<action: string, data: record<techniques: record<technique: record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/techniques")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List categories
#
# GET /techniques/categories
# operationId: techniqueCategories
export def "techniques-categories techniqueCategories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<techniqueCategories: record<id: string, name: string, path: string, subcategories: list>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/techniques/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reload techniques
#
# POST /techniques/reload
# operationId: techniques
export def "techniques-reload techniques" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<techniques: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/techniques/reload")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List versions
#
# GET /techniques/versions
# operationId: listTechniquesVersions
export def "techniques-versions listTechniquesVersions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<techniques: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/techniques/versions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Technique metadata by ID
#
# GET /techniques/{techniqueId}
# operationId: getTechniqueAllVersion
export def "techniques list" [
  techniqueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<techniques: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/techniques/($techniqueId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all directives based on a technique
#
# GET /techniques/{techniqueId}/directives
# operationId: listTechniquesDirectives
export def "techniques-directives listTechniquesDirectives" [
  techniqueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<directives: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/techniques/($techniqueId)/directives")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete technique
#
# DELETE /techniques/{techniqueId}/{techniqueVersion}
# operationId: deleteTechnique
export def "techniques delete" [
  techniqueId: string
  techniqueVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<techniques: record<id: string, version: string>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/techniques/($techniqueId)/($techniqueVersion)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Technique metadata by version and ID
#
# GET /techniques/{techniqueId}/{techniqueVersion}
# operationId: getTechniqueAllVersionId
export def "techniques get" [
  techniqueId: string
  techniqueVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<techniques: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/techniques/($techniqueId)/($techniqueVersion)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update technique
#
# POST /techniques/{techniqueId}/{techniqueVersion}
# operationId: updateTechnique
export def "techniques updateTechnique" [
  techniqueId: string
  techniqueVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<action: string, data: record<techniques: record<technique: record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/techniques/($techniqueId)/($techniqueVersion)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all directives based on a version of a technique
#
# GET /techniques/{techniqueId}/{techniqueVersion}/directives
# operationId: listTechniqueVersionDirectives
export def "techniques-directives listTechniqueVersionDirectives" [
  techniqueId: string
  techniqueVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<directives: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/techniques/($techniqueId)/($techniqueVersion)/directives")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Technique's resources
#
# GET /techniques/{techniqueId}/{techniqueVersion}/resources
# operationId: getTechniquesResources
export def "techniques-resources get" [
  techniqueId: string
  techniqueVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<resources: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/techniques/($techniqueId)/($techniqueVersion)/resources")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Technique's revisions
#
# GET /techniques/{techniqueId}/{techniqueVersion}/revisions
# operationId: techniqueRevisions
export def "techniques-revisions techniqueRevisions" [
  techniqueId: string
  techniqueVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<techniques: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/techniques/($techniqueId)/($techniqueVersion)/revisions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add user
#
# POST /usermanagement
# operationId: addUser
export def "usermanagement addUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isPreHahed: oneof<nothing, bool> # If you want to provide hashed password set this property to `true` otherwise we will hash the plain password and store the hash
  --password: string # this password will be hashed for you if the `isPreHashed` is set on false (e.g. passwdWillBeStoredHashed)
  --role: list # Defined user's permissions
  --username: string # e.g. John Doe
]: any -> record<action: string, data: record<addedUser: record<password: string, role: list, username: string>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usermanagement")
  let body = {isPreHahed: $isPreHahed, password: $password, role: $role, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all roles
#
# GET /usermanagement/roles
# operationId: getRole
export def "usermanagement-roles get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: table<id: string, rights: list>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usermanagement/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user's infos
#
# POST /usermanagement/update/{username}
# operationId: updateUser
export def "usermanagement-update updateUser" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isPreHahed: oneof<nothing, bool> # If you want to provide hashed password set this property to `true` otherwise we will hash the plain password and store the hash
  --password: string # this password will be hashed for you if the `isPreHashed` is set on false (e.g. passwdWillBeStoredHashed)
  --role: list # Defined user's permissions
  --body-username: string # e.g. John Doe
]: any -> record<action: string, data: record<updatedUser: record<password: string, role: list, username: string>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/usermanagement/update/($username)")
  let body = {isPreHahed: $isPreHahed, password: $password, role: $role, username: $body_username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all users
#
# GET /usermanagement/users
# operationId: getUserInfo
export def "usermanagement-users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<digest: string, users: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usermanagement/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reload user
#
# GET /usermanagement/users/reload
# operationId: reloadUserConf
export def "usermanagement-users-reload reloadUserConf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<reload: record<status: string>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usermanagement/users/reload")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an user
#
# DELETE /usermanagement/{username}
# operationId: deleteUser
export def "usermanagement delete" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: record<deletedUser: record<username: string>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/usermanagement/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List user
#
# GET /users
# operationId: listUsers
export def "users listUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: table<isValidated: bool, userExists: bool, username: string>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update validated user list
#
# POST /validatedUsers
# operationId: saveWorkflowUser
export def "validated-users saveWorkflowUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  validatedUsers: list # list of user to put in validated list
]: any -> record<action: string, data: record<isValidated: bool, userExists: bool, username: string>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/validatedUsers")
  let body = {validatedUsers: $validatedUsers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an user from validated user list
#
# DELETE /validatedUsers/{username}
# operationId: removeValidatedUser
export def "validated-users removeValidatedUser" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, data: string, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/validatedUsers/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
