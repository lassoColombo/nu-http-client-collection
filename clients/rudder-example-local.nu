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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
def build-multipart-body [parts: record, file_fields: list<string>]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | transpose k v | where {|p| $p.v != null} | each {|p|
    let name = $p.k
    let val = $p.v
    if $name in $file_fields {
      let filename = ($val | path basename)
      let bytes = (open --raw $val | into binary | collect)
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  })
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://rudder.example.local/rudder/api/latest"] }
def auth-scheme-completer [] { ["x-api-token"] }

# Completers for enum parameters
def status-completer [] { ["deployed" "pending deployment"] }
def policy-mode-completer [] { ["audit" "enforce"] }
def composition-completer [] { ["and" "or"] }
def status-completer-1 [] { ["accepted" "refused"] }
def mode-completer [] { ["erase" "move"] }
def policy-mode-completer-1 [] { ["audit" "default" "enforce"] }
def state-completer [] { ["empty-policies" "enabled" "ignored" "initializing" "preparing-eol"] }
def is-pre-hahed-completer [] { ["false" "true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "change-requests list" } } | get name | first)
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
export def "change-requests list" [
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
  --include: list<string> # Scope of dependencies to include in archive, where rule as directives and groups dependencies, directives have techniques dependencies, and techniques and groups don't have dependencies. 'none' means no dependencies will be include, 'all' means that the whole tree will, 'directives' and 'groups' means to include them specifically, 'techniques' means to include both directives and techniques.
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
  let req_body = {"archive": $archive} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body ["archive"])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Get branding configuration
#
# GET /branding
# operationId: getBrandingConf
export def "branding get-conf" [
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
export def "branding update-b-randing-conf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  bar_color: record # shape: {alpha: float, blue: float, green: float, red: float}
  --display-bar: oneof<nothing, bool> # Whether header bar is displayed or not
  --display-bar-login: oneof<nothing, bool> # Whether header bar is displayed in login page or not
  --display-label: oneof<nothing, bool> # Whether header bar's label is displayed or not
  --display-motd: oneof<nothing, bool> # Whether the message of the day is displayed in login page or not
  label_color: record # shape: {alpha: float, blue: float, green: float, red: float}
  label_text: string # The header bar's label title (e.g. Production)
  motd: string # Message of the day in login page (e.g. Welcome, please sign in:)
  small_logo: record # shape: {enable: bool}
  wide_logo: record # shape: {enable: bool}
]: any -> record<action: string, data: record<branding: record<barColor: record, displayBar: bool, displayBarLogin: bool, displayLabel: bool, displayMotd: bool, labelColor: record, labelText: string, motd: string, smallLogo: record, wideLogo: record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/branding")
  let req_body = {"barColor": $bar_color, "displayBar": $display_bar, "displayBarLogin": $display_bar_login, "displayLabel": $display_label, "displayMotd": $display_motd, "labelColor": $label_color, "labelText": $label_text, "motd": $motd, "smallLogo": $small_logo, "wideLogo": $wide_logo} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Reload branding file
#
# POST /branding/reload
# operationId: reloadBrandingConf
export def "branding-reload reload-conf" [
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
export def "change-requests request-decline" [
  change_request_id: int
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
  let full_url = (build-url $base ({change_request_id: (encode-path-segment $change_request_id)} | format pattern "/changeRequests/{change_request_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a change request details
#
# GET /changeRequests/{changeRequestId}
# operationId: changeRequestDetails
export def "change-requests request-details" [
  change_request_id: int
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
  let full_url = (build-url $base ({change_request_id: (encode-path-segment $change_request_id)} | format pattern "/changeRequests/{change_request_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a request details
#
# POST /changeRequests/{changeRequestId}
# operationId: updateChangeRequest
export def "change-requests update" [
  change_request_id: int
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
  let full_url = (build-url $base ({change_request_id: (encode-path-segment $change_request_id)} | format pattern "/changeRequests/{change_request_id}"))
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Accept a request details
#
# POST /changeRequests/{changeRequestId}/accept
# operationId: acceptChangeRequest
export def "change-requests-accept request" [
  change_request_id: int
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
  let full_url = (build-url $base ({change_request_id: (encode-path-segment $change_request_id)} | format pattern "/changeRequests/{change_request_id}/accept"))
  let req_body = {"status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Global compliance
#
# GET /compliance
# operationId: getGlobalCompliance
export def "compliance get-global" [
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
  node_id: string
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
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/compliance/nodes/{node_id}") $qp)
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
  rule_id: string
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
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/compliance/rules/{rule_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all CVE details
#
# GET /cve
# operationId: getAllCve
export def "cve get-list" [
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
export def "cve-check check" [
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
export def "cve-check-config get-configuration" [
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
export def "cve-check-config update-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # Token used by to contact the API to check CVE
  --url: string # Url used to check CVE (e.g. https://api.rudder.io/cve/v1/)
]: any -> record<action: string, data: record<apiKey: string, url: string>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cve/check/config")
  let req_body = {"apiKey": $api_key, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
export def "cve-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cve-ids: list<string>
]: any -> record<action: string, data: record<CVEs: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cve/list")
  let req_body = {"cveIds": $cve_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update CVE database from remote source
#
# POST /cve/update/
# operationId: updateCVE
export def "cve-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # Url used to update CVE, will default to one set in config (e.g. https://nvd.nist.gov/feeds/json/cve/1.1)
  --years: list<string>
]: any -> record<action: string, data: record<CVEs: int>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cve/update/")
  let req_body = {"url": $url, "years": $years} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update CVE database from file system
#
# POST /cve/update/fs
# operationId: readCVEfromFS
export def "cve-update-fs get-cv-efrom" [
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
export def "datasources get-list-data-sources" [
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
export def "datasources create-data-source" [
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
  --run-parameters: record # Parameters to configure when the data source is fetched to update node properties. — shape: {onGeneration?: bool, onNewNode?: bool, schedule?: record}
  --type: record # Define and configure data source type. — shape: {name?: "HTTP", parameters?: record}
  --update-timeout: int # Duration in seconds before aborting data source update. The main goal is to prevent never ending requests. If a periodicity if configured, you should set that timeout at a lower value. (e.g. 30)
]: any -> record<action: string, data: record<datasources: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/datasources")
  let req_body = {"description": $description, "enabled": $enabled, "id": $id, "name": $name, "runParameters": $run_parameters, "type": $type, "updateTimeout": $update_timeout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update properties from data sources
#
# POST /datasources/reload
# operationId: ReloadAllDatasourcesAllNodes
export def "datasources-reload list-list-nodes" [
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
export def "datasources-reload list-one-nodes" [
  datasource_id: string
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
  let full_url = (build-url $base ({datasource_id: (encode-path-segment $datasource_id)} | format pattern "/datasources/reload/{datasource_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a data source
#
# DELETE /datasources/{datasourceId}
# operationId: deleteDataSource
export def "datasources delete-data-source" [
  datasource_id: string
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
  let full_url = (build-url $base ({datasource_id: (encode-path-segment $datasource_id)} | format pattern "/datasources/{datasource_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get data source configuration
#
# GET /datasources/{datasourceId}
# operationId: getDataSource
export def "datasources get-data-source" [
  datasource_id: string
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
  let full_url = (build-url $base ({datasource_id: (encode-path-segment $datasource_id)} | format pattern "/datasources/{datasource_id}"))
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
export def "datasources update-data-source" [
  datasource_id: string
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
  --run-parameters: record # Parameters to configure when the data source is fetched to update node properties. — shape: {onGeneration?: bool, onNewNode?: bool, schedule?: record}
  --type: record # Define and configure data source type. — shape: {name?: "HTTP", parameters?: record}
  --update-timeout: int # Duration in seconds before aborting data source update. The main goal is to prevent never ending requests. If a periodicity if configured, you should set that timeout at a lower value. (e.g. 30)
]: any -> record<action: string, data: record<datasources: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({datasource_id: (encode-path-segment $datasource_id)} | format pattern "/datasources/{datasource_id}"))
  let req_body = {"description": $description, "enabled": $enabled, "id": $id, "name": $name, "runParameters": $run_parameters, "type": $type, "updateTimeout": $update_timeout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all directives
#
# GET /directives
# operationId: listDirectives
export def "directives list" [
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
export def "directives create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # Human readable name of the directive (e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --enabled: oneof<nothing, bool> # Is the directive enabled (e.g. true)
  --id: string # Directive id (format: uuid, e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --long-description: string # Description of the technique (rendered as markdown) (format: markdown, e.g. # Documentation * [Ticket link](https://tickets.example.com/issues/3456))
  --parameters: record # Directive parameters (depends on the source technique) (e.g. {name: sections, sections: [{section: {name: File to manage, sections: [{section: {name: File, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_PATH, value: /root/test}}]}}, {section: {name: File cleaning options, vars: [{var: {name: FILE_AND_FOLDER_DELETION_DAYS, value: 0}}, {var: {name: FILE_AND_FOLDER_DELETION_OPTION, value: none}}, {var: {name: FILE_AND_FOLDER_DELETION_PATTERN, value: .*}}]}}, {section: {name: Permissions, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_CHECK_PERMISSIONS, value: false}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_GROUP, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_OWNER, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_PERM, value: 000}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_RECURSIVE, value: 1}}]}}, {section: {name: Post-modification hook, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_COMMAND, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_RUN, value: false}}]}}], vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_ACTION, value: copy}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_SOURCE, value: /vagrant/node.sh}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_SYMLINK_ENFORCE, value: false}}]}}]})
  --priority: int # Directive priority. `0` has highest priority. (e.g. 5)
  --short-description: string # One line directive description (e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --body-source: string # The id of the directive the clone will be based onto. If this parameter if provided, the new directive will be a clone of this source. Other value will override values from the source. (format: uuid, e.g. b9f6d98a-28bc-4d80-90f7-d2f14269e215)
  --system: oneof<nothing, bool> # If true it is an internal Rudder directive (e.g. false)
  --tags: list # item shape: {name?: string}
  --technique-name: string # Directive id (e.g. userManagement)
  --technique-version: string # Directive id (e.g. 8.0)
]: any -> record<action: string, data: record<directives: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/directives")
  let req_body = {"displayName": $display_name, "enabled": $enabled, "id": $id, "longDescription": $long_description, "parameters": $parameters, "priority": $priority, "shortDescription": $short_description, "source": $body_source, "system": $system, "tags": $tags, "techniqueName": $technique_name, "techniqueVersion": $technique_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a directive
#
# DELETE /directives/{directiveId}
# operationId: deleteDirective
export def "directives delete" [
  directive_id: string
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
  let full_url = (build-url $base ({directive_id: (encode-path-segment $directive_id)} | format pattern "/directives/{directive_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get directive details
#
# GET /directives/{directiveId}
# operationId: directiveDetails
export def "directives get-details" [
  directive_id: string
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
  let full_url = (build-url $base ({directive_id: (encode-path-segment $directive_id)} | format pattern "/directives/{directive_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a directive details
#
# POST /directives/{directiveId}
# operationId: updateDirective
# --tags item shape: {name?: string}
export def "directives update" [
  directive_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # Human readable name of the directive (e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --enabled: oneof<nothing, bool> # Is the directive enabled (e.g. true)
  --id: string # Directive id (format: uuid, e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --long-description: string # Description of the technique (rendered as markdown) (format: markdown, e.g. # Documentation * [Ticket link](https://tickets.example.com/issues/3456))
  --parameters: record # Directive parameters (depends on the source technique) (e.g. {name: sections, sections: [{section: {name: File to manage, sections: [{section: {name: File, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_PATH, value: /root/test}}]}}, {section: {name: File cleaning options, vars: [{var: {name: FILE_AND_FOLDER_DELETION_DAYS, value: 0}}, {var: {name: FILE_AND_FOLDER_DELETION_OPTION, value: none}}, {var: {name: FILE_AND_FOLDER_DELETION_PATTERN, value: .*}}]}}, {section: {name: Permissions, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_CHECK_PERMISSIONS, value: false}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_GROUP, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_OWNER, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_PERM, value: 000}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_RECURSIVE, value: 1}}]}}, {section: {name: Post-modification hook, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_COMMAND, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_RUN, value: false}}]}}], vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_ACTION, value: copy}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_SOURCE, value: /vagrant/node.sh}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_SYMLINK_ENFORCE, value: false}}]}}]})
  --policy-mode: string@policy-mode-completer # Policy mode of the directive (e.g. audit)
  --priority: int # Directive priority. `0` has highest priority. (e.g. 5)
  --short-description: string # One line directive description (e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --system: oneof<nothing, bool> # If true it is an internal Rudder directive (e.g. false)
  --tags: list # item shape: {name?: string}
  --technique-name: string # Directive id (e.g. userManagement)
  --technique-version: string # Directive id (e.g. 8.0)
]: any -> record<action: string, data: record<directives: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({directive_id: (encode-path-segment $directive_id)} | format pattern "/directives/{directive_id}"))
  let req_body = {"displayName": $display_name, "enabled": $enabled, "id": $id, "longDescription": $long_description, "parameters": $parameters, "policyMode": $policy_mode, "priority": $priority, "shortDescription": $short_description, "system": $system, "tags": $tags, "techniqueName": $technique_name, "techniqueVersion": $technique_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Check that update on a directive is valid
#
# POST /directives/{directiveId}/check
# operationId: checkDirective
# --tags item shape: {name?: string}
export def "directives-check check" [
  directive_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # Human readable name of the directive (e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --enabled: oneof<nothing, bool> # Is the directive enabled (e.g. true)
  --id: string # Directive id (format: uuid, e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --long-description: string # Description of the technique (rendered as markdown) (format: markdown, e.g. # Documentation * [Ticket link](https://tickets.example.com/issues/3456))
  --parameters: record # Directive parameters (depends on the source technique) (e.g. {name: sections, sections: [{section: {name: File to manage, sections: [{section: {name: File, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_PATH, value: /root/test}}]}}, {section: {name: File cleaning options, vars: [{var: {name: FILE_AND_FOLDER_DELETION_DAYS, value: 0}}, {var: {name: FILE_AND_FOLDER_DELETION_OPTION, value: none}}, {var: {name: FILE_AND_FOLDER_DELETION_PATTERN, value: .*}}]}}, {section: {name: Permissions, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_CHECK_PERMISSIONS, value: false}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_GROUP, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_OWNER, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_PERM, value: 000}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_RECURSIVE, value: 1}}]}}, {section: {name: Post-modification hook, vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_COMMAND, value: }}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_POST_HOOK_RUN, value: false}}]}}], vars: [{var: {name: FILE_AND_FOLDER_MANAGEMENT_ACTION, value: copy}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_SOURCE, value: /vagrant/node.sh}}, {var: {name: FILE_AND_FOLDER_MANAGEMENT_SYMLINK_ENFORCE, value: false}}]}}]})
  --policy-mode: string@policy-mode-completer # Policy mode of the directive (e.g. audit)
  --priority: int # Directive priority. `0` has highest priority. (e.g. 5)
  --short-description: string # One line directive description (e.g. 91252ea2-feb2-412d-8599-c6945fee02c4)
  --system: oneof<nothing, bool> # If true it is an internal Rudder directive (e.g. false)
  --tags: list # item shape: {name?: string}
  --technique-name: string # Directive id (e.g. userManagement)
  --technique-version: string # Directive id (e.g. 8.0)
]: any -> record<action: string, data: record<directives: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({directive_id: (encode-path-segment $directive_id)} | format pattern "/directives/{directive_id}/check"))
  let req_body = {"displayName": $display_name, "enabled": $enabled, "id": $id, "longDescription": $long_description, "parameters": $parameters, "policyMode": $policy_mode, "priority": $priority, "shortDescription": $short_description, "system": $system, "tags": $tags, "techniqueName": $technique_name, "techniqueVersion": $technique_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all groups
#
# GET /groups
# operationId: listGroups
export def "groups list" [
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
export def "groups create" [
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
  display_name: string # Name of the group (e.g. Ubuntu 18.04 nodes)
  --dynamic: oneof<nothing, bool> # Should the group be dynamically refreshed (if not, it is a static group) (default: true)
  --enabled: oneof<nothing, bool> # Enable or disable the group (default: true)
  --id: string # Group id, only provide it when needed. (format: uuid, default: {autogenerated}, e.g. 32d013f7-b6d8-46c8-99d3-016307fa66c0)
  --properties: list # Group properties — item shape: {name: string, value: any}
  --query: record # The criteria defining the group. If not provided, the group will be empty. — shape: {composition?: "and"|"or", select?: string, where?: list}
  --body-source: string # The id of the group the clone will be based onto. If this parameter if provided, the new group will be a clone of this source. Other value will override values from the source. (format: uuid, e.g. b9f6d98a-28bc-4d80-90f7-d2f14269e215)
]: any -> record<action: string, data: record<groups: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups")
  let req_body = {"category": $category, "description": $description, "displayName": $display_name, "dynamic": $dynamic, "enabled": $enabled, "id": $id, "properties": $properties, "query": $query, "source": $body_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create a group category
#
# PUT /groups/categories
# operationId: CreateGroupCategory
export def "groups-categories create-category" [
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
  let req_body = {"description": $description, "id": $id, "name": $name, "parent": $parent} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete group category
#
# DELETE /groups/categories/{groupCategoryId}
# operationId: DeleteGroupCategory
export def "groups-categories delete-category" [
  group_category_id: string
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
  let full_url = (build-url $base ({group_category_id: (encode-path-segment $group_category_id)} | format pattern "/groups/categories/{group_category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get group category details
#
# GET /groups/categories/{groupCategoryId}
# operationId: GetGroupCategoryDetails
export def "groups-categories get-category-details" [
  group_category_id: string
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
  let full_url = (build-url $base ({group_category_id: (encode-path-segment $group_category_id)} | format pattern "/groups/categories/{group_category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update group category details
#
# POST /groups/categories/{groupCategoryId}
# operationId: UpdateGroupCategory
export def "groups-categories update-category" [
  group_category_id: string
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
  let full_url = (build-url $base ({group_category_id: (encode-path-segment $group_category_id)} | format pattern "/groups/categories/{group_category_id}"))
  let req_body = {"description": $description, "name": $name, "parent": $parent} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get groups tree
#
# GET /groups/tree
# operationId: GetGroupTree
export def "groups-tree get" [
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
  group_id: string
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
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get group details
#
# GET /groups/{groupId}
# operationId: groupDetails
export def "groups get-details" [
  group_id: string
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
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update group details
#
# POST /groups/{groupId}
# operationId: updateGroup
# --query shape: {composition?: "and"|"or", select?: string, where?: list}
export def "groups update" [
  group_id: string
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
  --display-name: string # Name of the group (e.g. Ubuntu 18.04 nodes)
  --dynamic: oneof<nothing, bool> # Should the group be dynamically refreshed (if not, it is a static group) (default: true)
  --enabled: oneof<nothing, bool> # Enable or disable the group (default: true)
  --query: record # The criteria defining the group. If not provided, the group will be empty. — shape: {composition?: "and"|"or", select?: string, where?: list}
]: any -> record<action: string, data: record<groups: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}"))
  let req_body = {"category": $category, "description": $description, "displayName": $display_name, "dynamic": $dynamic, "enabled": $enabled, "query": $query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Reload a group
#
# POST /groups/{groupId}/reload
# operationId: reloadGroup
export def "groups-reload reload" [
  group_id: string
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
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}/reload"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all endoints
#
# GET /info
# operationId: apiGeneralInformations
export def "info get-general-informations" [
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
export def "info-details get-informations" [
  endpoint_name: string
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
  let full_url = (build-url $base ({endpoint_name: (encode-path-segment $endpoint_name)} | format pattern "/info/details/{endpoint_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information on endpoint in a section
#
# GET /info/{sectionId}
# operationId: apiSubInformations
export def "info get-sub-informations" [
  section_id: string
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
  let full_url = (build-url $base ({section_id: (encode-path-segment $section_id)} | format pattern "/info/{section_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about inventory processing queue
#
# GET /inventories/info
# operationId: queueInformation
export def "inventories-info get-queue-information" [
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
export def "inventories-upload upload-inventory" [
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
  let req_body = {"file": $file, "signature": $signature} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body ["file" "signature"])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Restart inventory watcher
#
# POST /inventories/watcher/restart
# operationId: fileWatcherRestart
export def "inventories-watcher-restart restart-file" [
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
export def "inventories-watcher-start start-file" [
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
export def "inventories-watcher-stop stop-file" [
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
export def "methods get" [
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
export def "methods-reload reload" [
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
export def "nodes list-accepted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # Level of information to include from the node inventory. Some base levels are defined (**minimal**, **default**, **full**). You can add fields you want to a base level by adding them to the list, possible values are keys from json answer. If you don't provide a base level, they will be added to `default` level, so if you only want os details, use `minimal,os` as the value for this parameter. * **minimal** includes: `id`, `hostname` and `status` * **default** includes **minimal** plus `architectureDescription`, `description`, `ipAddresses`, `lastRunDate`, `lastInventoryDate`, `machine`, `os`, `managementTechnology`, `policyServerId`, `properties` (be careful! Only node own properties, if you also need inherited properties, look at the dedicated `/nodes/{id}/inheritedProperties` endpoint), `policyMode `, `ram` and `timezone` * **full** includes: **default** plus `accounts`, `bios`, `controllers`, `environmentVariables`, `fileSystems`, `managementTechnologyDetails`, `memories`, `networkInterfaces`, `ports`, `processes`, `processors`, `slots`, `software`, `sound`, `storage`, `videos` and `virtualMachines` (format: comma-separated list, default: default, e.g. minimal)
  --query: string # The criterion you want to find for your nodes. Replaces the `where`, `composition` and `select` parameters in a single parameter.
  --qp-where: string # The criterion you want to find for your nodes
  --composition: string@composition-completer # Boolean operator to use between each `where` criteria. (default: and, e.g. and)
  --select: string # What kind of data we want to include. Here we can get policy servers/relay by setting `nodeAndPolicyServer`. Only used if `where` is defined. (default: node)
]: nothing -> record<action: string, data: record<nodes: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "where" $qp_where "scalar") (serialize-qp "composition" $composition "scalar") (serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create one or several new nodes
#
# PUT /nodes
# operationId: createNodes
export def "nodes create" [
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
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Trigger an agent run on all nodes
#
# POST /nodes/applyPolicy
# operationId: applyPolicyAllNodes
export def "nodes-apply-policy list" [
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
export def "nodes-pending list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # Level of information to include from the node inventory. Some base levels are defined (**minimal**, **default**, **full**). You can add fields you want to a base level by adding them to the list, possible values are keys from json answer. If you don't provide a base level, they will be added to `default` level, so if you only want os details, use `minimal,os` as the value for this parameter. * **minimal** includes: `id`, `hostname` and `status` * **default** includes **minimal** plus `architectureDescription`, `description`, `ipAddresses`, `lastRunDate`, `lastInventoryDate`, `machine`, `os`, `managementTechnology`, `policyServerId`, `properties` (be careful! Only node own properties, if you also need inherited properties, look at the dedicated `/nodes/{id}/inheritedProperties` endpoint), `policyMode `, `ram` and `timezone` * **full** includes: **default** plus `accounts`, `bios`, `controllers`, `environmentVariables`, `fileSystems`, `managementTechnologyDetails`, `memories`, `networkInterfaces`, `ports`, `processes`, `processors`, `slots`, `software`, `sound`, `storage`, `videos` and `virtualMachines` (format: comma-separated list, default: default, e.g. minimal)
  --query: string # The criterion you want to find for your nodes. Replaces the `where`, `composition` and `select` parameters in a single parameter.
  --qp-where: string # The criterion you want to find for your nodes
  --composition: string@composition-completer # Boolean operator to use between each `where` criteria. (default: and, e.g. and)
  --select: string # What kind of data we want to include. Here we can get policy servers/relay by setting `nodeAndPolicyServer`. Only used if `where` is defined. (default: node)
]: nothing -> record<action: string, data: record<nodes: list<record>>, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "where" $qp_where "scalar") (serialize-qp "composition" $composition "scalar") (serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nodes/pending" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update pending Node status
#
# POST /nodes/pending/{nodeId}
# operationId: changePendingNodeStatus
export def "nodes-pending create-change-status" [
  node_id: string
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
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/pending/{node_id}"))
  let req_body = {"status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  node_id: string
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
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about a node
#
# GET /nodes/{nodeId}
# operationId: nodeDetails
export def "nodes get-details" [
  node_id: string
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
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}") $qp)
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
export def "nodes update" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --agent-key: record # Information about agent key or certificate — shape: {status?: "certified"|"undefined", value: string}
  --policy-mode: string@policy-mode-completer-1 # In which mode the node will apply its configuration policy. Use `default` to use the global mode. (e.g. audit)
  --properties: list # item shape: {name: string, value: any}
  --state: string@state-completer # The node life cycle state. See [dedicated doc](https://docs.rudder.io/reference/current/usage/advanced_node_management.html#node-lifecycle) for more information. (e.g. enabled)
]: any -> record<action: string, data: record<nodes: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}"))
  let req_body = {"agentKey": $agent_key, "policyMode": $policy_mode, "properties": $properties, "state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Trigger an agent run
#
# POST /nodes/{nodeId}/applyPolicy
# operationId: applyNode
export def "nodes-apply-policy create" [
  node_id: string
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
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/applyPolicy"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update properties for one node from all data sources
#
# POST /nodes/{nodeId}/fetchData
# operationId: ReloadAllDatasourcesOneNode
export def "nodes-fetch-data reload-list-datasources-one" [
  node_id: string
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
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/fetchData"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update properties for one node from a data source
#
# POST /nodes/{nodeId}/fetchData/{datasourceId}
# operationId: ReloadOneDatasourceOneNode
export def "nodes-fetch-data reload-one-datasource-one" [
  node_id: string
  datasource_id: string
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
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id), datasource_id: (encode-path-segment $datasource_id)} | format pattern "/nodes/{node_id}/fetchData/{datasource_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get inherited node properties for a node
#
# GET /nodes/{nodeId}/inheritedProperties
# operationId: nodeInheritedProperties
export def "nodes-inherited-properties get" [
  node_id: string
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
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/inheritedProperties"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all global parameters
#
# GET /parameters
# operationId: listParameters
export def "parameters list" [
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
export def "parameters create" [
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
  let req_body = {"description": $description, "id": $id, "overridable": $overridable, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a parameter
#
# DELETE /parameters/{parameterId}
# operationId: deleteParameter
export def "parameters delete" [
  parameter_id: string
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
  let full_url = (build-url $base ({parameter_id: (encode-path-segment $parameter_id)} | format pattern "/parameters/{parameter_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the value of a parameter
#
# GET /parameters/{parameterId}
# operationId: parameterDetails
export def "parameters get-details" [
  parameter_id: string
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
  let full_url = (build-url $base ({parameter_id: (encode-path-segment $parameter_id)} | format pattern "/parameters/{parameter_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a parameter's value
#
# POST /parameters/{parameterId}
# operationId: updateParameter
export def "parameters update" [
  parameter_id: string
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
  let full_url = (build-url $base ({parameter_id: (encode-path-segment $parameter_id)} | format pattern "/parameters/{parameter_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all rules
#
# GET /rules
# operationId: listRules
export def "rules list" [
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
export def "rules create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string # The parent category id. If provided, the new rule will be in this parent category (format: uuid, e.g. 38e0c6ea-917f-47b8-82e0-e6a1d3dd62ca)
  --directives: list<string> # Directives linked to the rule
  --display-name: string # Rule name (e.g. Security policy)
  --enabled: oneof<nothing, bool> # Is the rule enabled (e.g. true)
  --id: string # Rule id (format: uuid, e.g. 0c1713ae-cb9d-4f7b-abda-ca38c5d643ea)
  --long-description: string # Rule documentation (e.g. This rules should be applied to all Linux nodes required basic hardening)
  --short-description: string # One line rule description (e.g. Baseline applying CIS guidelines)
  --body-source: string # The id of the rule the clone will be based onto. If this parameter if provided, the new rule will be a clone of this source. Other value will override values from the source. (format: uuid, e.g. b9f6d98a-28bc-4d80-90f7-d2f14269e215)
  --system: oneof<nothing, bool> # If true it is an internal Rudder rule (e.g. false)
  --tags: list # item shape: {name?: string}
  --targets: list # Node and special groups targeted by that rule — item shape: {exclude: record, include: record}
]: any -> record<action: string, data: record<rules: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rules")
  let req_body = {"category": $category, "directives": $directives, "displayName": $display_name, "enabled": $enabled, "id": $id, "longDescription": $long_description, "shortDescription": $short_description, "source": $body_source, "system": $system, "tags": $tags, "targets": $targets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create a rule category
#
# PUT /rules/categories
# operationId: CreateRuleCategory
export def "rules-categories create-category" [
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
  let req_body = {"description": $description, "id": $id, "name": $name, "parent": $parent} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete group category
#
# DELETE /rules/categories/{ruleCategoryId}
# operationId: DeleteRuleCategory
export def "rules-categories delete-category" [
  rule_category_id: string
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
  let full_url = (build-url $base ({rule_category_id: (encode-path-segment $rule_category_id)} | format pattern "/rules/categories/{rule_category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get rule category details
#
# GET /rules/categories/{ruleCategoryId}
# operationId: GetRuleCategoryDetails
export def "rules-categories get-category-details" [
  rule_category_id: string
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
  let full_url = (build-url $base ({rule_category_id: (encode-path-segment $rule_category_id)} | format pattern "/rules/categories/{rule_category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update rule category details
#
# POST /rules/categories/{ruleCategoryId}
# operationId: UpdateRuleCategory
export def "rules-categories update-category" [
  rule_category_id: string
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
  let full_url = (build-url $base ({rule_category_id: (encode-path-segment $rule_category_id)} | format pattern "/rules/categories/{rule_category_id}"))
  let req_body = {"description": $description, "name": $name, "parent": $parent} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get rules tree
#
# GET /rules/tree
# operationId: GetRuleTree
export def "rules-tree get" [
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
  rule_id: string
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
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/rules/{rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a rule details
#
# GET /rules/{ruleId}
# operationId: ruleDetails
export def "rules get-details" [
  rule_id: string
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
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/rules/{rule_id}"))
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
export def "rules update" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string # The parent category id. (format: uuid, e.g. 38e0c6ea-917f-47b8-82e0-e6a1d3dd62ca)
  --directives: list<string> # Directives linked to the rule
  --display-name: string # Rule name (e.g. Security policy)
  --enabled: oneof<nothing, bool> # Is the rule enabled (e.g. true)
  --id: string # Rule id (format: uuid, e.g. 0c1713ae-cb9d-4f7b-abda-ca38c5d643ea)
  --long-description: string # Rule documentation (e.g. This rules should be applied to all Linux nodes required basic hardening)
  --short-description: string # One line rule description (e.g. Baseline applying CIS guidelines)
  --system: oneof<nothing, bool> # If true it is an internal Rudder rule (e.g. false)
  --tags: list # item shape: {name?: string}
  --targets: list # Node and special groups targeted by that rule — item shape: {exclude: record, include: record}
]: any -> record<action: string, data: record<rules: list<record>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/rules/{rule_id}"))
  let req_body = {"category": $category, "directives": $directives, "displayName": $display_name, "enabled": $enabled, "id": $id, "longDescription": $long_description, "shortDescription": $short_description, "system": $system, "tags": $tags, "targets": $targets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Demote a relay to simple node
#
# POST /scaleoutrelay/demote/{nodeId}
# operationId: demoteToNode
export def "scaleoutrelay-demote create-to-node" [
  node_id: string
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
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/scaleoutrelay/demote/{node_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Promote a node to relay
#
# POST /scaleoutrelay/promote/{nodeId}
# operationId: promoteToRelay
export def "scaleoutrelay-promote create-to-relay" [
  node_id: string
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
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/scaleoutrelay/promote/{node_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all secrets
#
# GET /secret/
# operationId: getAllSecrets
export def "secret get-list" [
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
export def "secret update" [
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
  let req_body = {"description": $description, "name": $name, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create a secret
#
# PUT /secret/
# operationId: addSecret
export def "secret create" [
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
  let req_body = {"description": $description, "name": $name, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/secret/{name}"))
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
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/secret/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all settings
#
# GET /settings
# operationId: getAllSettings
export def "settings get-list" [
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
  node_id: string
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
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/settings/allowed_networks/{node_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set allowed networks for a policy server
#
# POST /settings/allowed_networks/{nodeId}
# operationId: setAllowedNetworks
export def "settings-allowed-networks update" [
  node_id: string
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
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/settings/allowed_networks/{node_id}"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Modify allowed networks for a policy server
#
# POST /settings/allowed_networks/{nodeId}/diff
# operationId: modifyAllowedNetworks
# --allowed_networks shape: {add?: list, delete?: list}
export def "settings-allowed-networks-diff create-modify" [
  node_id: string
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
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/settings/allowed_networks/{node_id}/diff"))
  let req_body = {"allowed_networks": $allowed_networks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the value of a setting
#
# GET /settings/{settingId}
# operationId: getSetting
export def "settings get" [
  setting_id: string
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
  let full_url = (build-url $base ({setting_id: (encode-path-segment $setting_id)} | format pattern "/settings/{setting_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set the value of a setting
#
# POST /settings/{settingId}
# operationId: modifySetting
export def "settings create-modify" [
  setting_id: string
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
  let full_url = (build-url $base ({setting_id: (encode-path-segment $setting_id)} | format pattern "/settings/{setting_id}"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Check if Rudder is alive
#
# GET /status
# operationId: none
export def "status get-none" [
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
export def "system-archives list" [
  archive_kind: string
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
  let full_url = (build-url $base ({archive_kind: (encode-path-segment $archive_kind)} | format pattern "/system/archives/{archive_kind}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an archive
#
# POST /system/archives/{archiveKind}
# operationId: createArchive
export def "system-archives create" [
  archive_kind: string
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
  let full_url = (build-url $base ({archive_kind: (encode-path-segment $archive_kind)} | format pattern "/system/archives/{archive_kind}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restore an archive
#
# POST /system/archives/{archiveKind}/restore/{archiveRestoreKind}
# operationId: restoreArchive
export def "system-archives-restore archive" [
  archive_kind: string
  archive_restore_kind: string
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
  let full_url = (build-url $base ({archive_kind: (encode-path-segment $archive_kind), archive_restore_kind: (encode-path-segment $archive_restore_kind)} | format pattern "/system/archives/{archive_kind}/restore/{archive_restore_kind}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an archive as a ZIP
#
# GET /system/archives/{archiveKind}/zip/{commitId}
# operationId: getZipArchive
export def "system-archives-zip get" [
  archive_kind: string
  commit_id: string
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
  let full_url = (build-url $base ({archive_kind: (encode-path-segment $archive_kind), commit_id: (encode-path-segment $commit_id)} | format pattern "/system/archives/{archive_kind}/zip/{commit_id}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get healthcheck
#
# GET /system/healthcheck
# operationId: getHealthcheckResult
export def "system-healthcheck get-result" [
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
export def "system-maintenance-purge-software create" [
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
export def "system-regenerate-policies create" [
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
export def "system-reload list" [
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
export def "system-reload-groups reload" [
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
export def "system-reload-techniques reload" [
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
export def "system-update-policies update" [
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
export def "techniques list" [
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
export def "techniques create" [
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
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List categories
#
# GET /techniques/categories
# operationId: techniqueCategories
export def "techniques-categories get" [
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
export def "techniques-reload create" [
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
export def "techniques-versions list" [
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
export def "techniques list-1" [
  technique_id: string
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
  let full_url = (build-url $base ({technique_id: (encode-path-segment $technique_id)} | format pattern "/techniques/{technique_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all directives based on a technique
#
# GET /techniques/{techniqueId}/directives
# operationId: listTechniquesDirectives
export def "techniques-directives list" [
  technique_id: string
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
  let full_url = (build-url $base ({technique_id: (encode-path-segment $technique_id)} | format pattern "/techniques/{technique_id}/directives"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete technique
#
# DELETE /techniques/{techniqueId}/{techniqueVersion}
# operationId: deleteTechnique
export def "techniques delete" [
  technique_id: string
  technique_version: string
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
  let full_url = (build-url $base ({technique_id: (encode-path-segment $technique_id), technique_version: (encode-path-segment $technique_version)} | format pattern "/techniques/{technique_id}/{technique_version}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Technique metadata by version and ID
#
# GET /techniques/{techniqueId}/{techniqueVersion}
# operationId: getTechniqueAllVersionId
export def "techniques get-list-version" [
  technique_id: string
  technique_version: string
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
  let full_url = (build-url $base ({technique_id: (encode-path-segment $technique_id), technique_version: (encode-path-segment $technique_version)} | format pattern "/techniques/{technique_id}/{technique_version}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update technique
#
# POST /techniques/{techniqueId}/{techniqueVersion}
# operationId: updateTechnique
export def "techniques update" [
  technique_id: string
  technique_version: string
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
  let full_url = (build-url $base ({technique_id: (encode-path-segment $technique_id), technique_version: (encode-path-segment $technique_version)} | format pattern "/techniques/{technique_id}/{technique_version}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all directives based on a version of a technique
#
# GET /techniques/{techniqueId}/{techniqueVersion}/directives
# operationId: listTechniqueVersionDirectives
export def "techniques-directives list-version" [
  technique_id: string
  technique_version: string
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
  let full_url = (build-url $base ({technique_id: (encode-path-segment $technique_id), technique_version: (encode-path-segment $technique_version)} | format pattern "/techniques/{technique_id}/{technique_version}/directives"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Technique's resources
#
# GET /techniques/{techniqueId}/{techniqueVersion}/resources
# operationId: getTechniquesResources
export def "techniques-resources get" [
  technique_id: string
  technique_version: string
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
  let full_url = (build-url $base ({technique_id: (encode-path-segment $technique_id), technique_version: (encode-path-segment $technique_version)} | format pattern "/techniques/{technique_id}/{technique_version}/resources"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Technique's revisions
#
# GET /techniques/{techniqueId}/{techniqueVersion}/revisions
# operationId: techniqueRevisions
export def "techniques-revisions get" [
  technique_id: string
  technique_version: string
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
  let full_url = (build-url $base ({technique_id: (encode-path-segment $technique_id), technique_version: (encode-path-segment $technique_version)} | format pattern "/techniques/{technique_id}/{technique_version}/revisions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add user
#
# POST /usermanagement
# operationId: addUser
export def "usermanagement create-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-pre-hahed: oneof<nothing, bool> # If you want to provide hashed password set this property to `true` otherwise we will hash the plain password and store the hash
  --password: string # this password will be hashed for you if the `isPreHashed` is set on false (e.g. passwdWillBeStoredHashed)
  --role: list<string> # Defined user's permissions
  --username: string # e.g. John Doe
]: any -> record<action: string, data: record<addedUser: record<password: string, role: list, username: string>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usermanagement")
  let req_body = {"isPreHahed": $is_pre_hahed, "password": $password, "role": $role, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
export def "usermanagement-update update-user" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-pre-hahed: oneof<nothing, bool> # If you want to provide hashed password set this property to `true` otherwise we will hash the plain password and store the hash
  --password: string # this password will be hashed for you if the `isPreHashed` is set on false (e.g. passwdWillBeStoredHashed)
  --role: list<string> # Defined user's permissions
  --body-username: string # e.g. John Doe
]: any -> record<action: string, data: record<updatedUser: record<password: string, role: list, username: string>>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/usermanagement/update/{username}"))
  let req_body = {"isPreHahed": $is_pre_hahed, "password": $password, "role": $role, "username": $body_username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all users
#
# GET /usermanagement/users
# operationId: getUserInfo
export def "usermanagement-users get-get" [
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
export def "usermanagement-users-reload reload-conf" [
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
export def "usermanagement delete-user" [
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
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/usermanagement/{username}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List user
#
# GET /users
# operationId: listUsers
export def "users list" [
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
export def "validated-users create-save-workflow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  validated_users: list<string> # list of user to put in validated list
]: any -> record<action: string, data: record<isValidated: bool, userExists: bool, username: string>, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/validatedUsers")
  let req_body = {"validatedUsers": $validated_users} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove an user from validated user list
#
# DELETE /validatedUsers/{username}
# operationId: removeValidatedUser
export def "validated-users delete" [
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
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/validatedUsers/{username}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
